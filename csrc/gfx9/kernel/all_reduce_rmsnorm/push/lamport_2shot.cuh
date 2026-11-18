#pragma once
// all_reduce + residual + RMSNorm, lamport proto, push, two-shot (aiter
// lamportArRmsTwoShot).
#include "gfx9/epilogue/rmsnorm.cuh"
#include "gfx9/proto/lamport.cuh"

namespace commkit::gfx9 {

/*
 * Two shot. Row r splits into ngpus chunks of cp = row_packs / ngpus packs,
 * chunk g reduced on rank g (as the two-shot all-reduce does with the whole
 * message). SPLIT blocks per row on every rank, block (r, s) = blockIdx.x
 * r * SPLIT + s with row_packs / SPLIT threads; it handles sub-range s, sub =
 * cp / SPLIT packs from s * sub, of every chunk. Each peer g gets `stride`
 * threads, whole waves when (ngpus - 1) of them fit the block (one peer a
 * wave, so its pointer is scalar), else sub; thread q is paired with peer g =
 * (rank + 1 + q / stride) % ngpus and pack pos = s * sub + q % stride of a
 * chunk, if q % stride < sub:
 *   reduce     push pack pos of chunk g into slot[rank] of row r in rank g's
 *              reduce inbox; poll pack pos of slot[g] in this rank's and put
 *              it in LDS by source rank (q < sub also loads this rank's own).
 *   broadcast  after one __syncthreads sum pack pos of this rank's chunk in
 *              rank order from LDS (every thread the same bits, no second
 *              sync), round to T, push it to rank g's broadcast inbox at its
 *              place in the row; q < sub also stores it in this rank's own.
 *   epilogue   the broadcast inbox now gets the whole row, so every block
 *              polls all of it (SPLIT packs a thread, loaded together; this
 *              rank's chunk included), adds this rank's residual and folds the row's sum
 *              of squares from 32-pack partials in LDS, the 1-stage order;
 *              it stores out and residual_out of packs [s, s + 1) *
 *              row_packs / SPLIT only. Every block of a row folds the same
 *              bits.
 * Row r of either inbox is used by row r only and row r's counter is
 * advanced by block (r, 0) on every rank, whatever the row count, so calls of
 * different sizes interleave. Both inboxes use the one counter: two hops as
 * the two-shot all-reduce, so ranks stay at most one round apart on a row.
 * Block (r, 0) moves the counter only after the whole row has arrived, which
 * needs every block (r, s) of this launch to have pushed, i.e. read it.
 * hidden and SPLIT may change between calls: the receiver notes the row
 * length each buffer got and the re-arm clears that much (the blocks of a row
 * share it out), so a longer earlier row leaves no stale tail.
 * Unlike the all-reduce kernels a block also waits for the other blocks of
 * its row on this rank (their part of this rank's chunk): this relies on
 * blocks being dispatched in id order, so the blocks of the lowest unfinished
 * row are resident on every rank.
 *
 * Inboxes (this kernel's scratch), [kLamportBuffers][row] slots of
 * kLamportArRms2SlotPacks: reduce, slot[src] at src * (SlotPacks / ngpus);
 * broadcast, the row as is.
 */
template <typename T, int ngpus, int SPLIT>
__global__ void __launch_bounds__(kLamportArRms2SlotPacks / SPLIT, 1) arRmsTwoShotLamport(
    const T* __restrict__ input,
    const T* __restrict__ residual_inp,
    T* __restrict__ residual_out,
    T* __restrict__ output,
    const T* __restrict__ weight,
    LamportPeers peers,                 // reduce inbox, broadcast inbox follows
    uint32_t* __restrict__ row_round,   // [kLamportArRms2MaxRows], rank-local
    uint32_t* __restrict__ row_written, // [kLamportArRms2MaxRows][kLamportBuffers], rank-local
    int rank,
    int hidden,
    float eps,
    bool gemma_norm)
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
    constexpr int pack_size       = 16 / sizeof(T);
    constexpr int src_packs       = kLamportArRms2SlotPacks / ngpus; // reduce slot per source
    constexpr int64_t inbox_packs = kLamportBuffers * kLamportArRms2BufPacks;
    using P        = typename opus::vector_t<T, pack_size>;
    using A        = typename opus::vector_t<opus::fp32_t, pack_size>;
    using ui32x4_t = __attribute__((__vector_size__(4 * sizeof(uint32_t)))) uint32_t;
    union pack
    {
        P data;
        ui32x4_t i;
    };

    __shared__ P s_data[ngpus][src_packs / SPLIT]; // sub-range of this rank's chunk, by source
    __shared__ float s_part[kLamportArRms2SlotPacks / kLamportRmsLanes];
    const int row         = blockIdx.x / SPLIT;
    const int split_id    = blockIdx.x % SPLIT;
    const int row_packs   = hidden / pack_size;
    const int block_packs = row_packs / SPLIT; // == blockDim.x
    const int chunk       = row_packs / ngpus;
    const int sub         = chunk / SPLIT;
    const int tid         = threadIdx.x;
    const P* row_in       = reinterpret_cast<const P*>(input) + (int64_t)row * row_packs;
    // block-uniform, so these are scalar loads
    const uint32_t round   = row_round[row];
    const uint32_t rearm   = (round + 2) % kLamportBuffers;
    const uint32_t written = row_written[row * kLamportBuffers + rearm];

    ui32x4_t* self_inbox  = reinterpret_cast<ui32x4_t*>(peers.ptrs[rank]);
    const int64_t row_off = round * kLamportArRms2BufPacks + (int64_t)row * kLamportArRms2SlotPacks;

    const int wave_lanes = (sub + kLamportWaveSize - 1) / kLamportWaveSize * kLamportWaveSize;
    const int stride     = (ngpus - 1) * wave_lanes <= block_packs ? wave_lanes : sub;
    const bool is_relay  = tid < (ngpus - 1) * stride && tid % stride < sub;
    const int relay_peer = (rank + 1 + tid / stride) % ngpus;
    const int relay_pos  = tid % stride;              // in s_data
    const int chunk_pos  = split_id * sub + relay_pos; // in a chunk

    // reduce
    if(is_relay)
    {
        pack send;
        send.data = row_in[relay_peer * chunk + chunk_pos];
#pragma unroll
        for(int j = 0; j < 4; ++j)
            send.i[j] = lamportCanonicalize(send.i[j]);
        auto dst = lamportPeerPtr<ngpus, ui32x4_t>(peers, relay_peer);
        __builtin_nontemporal_store(send.i, dst + row_off + rank * src_packs + chunk_pos);
    }
    if(tid < sub)
    {
        pack own;
        own.data = row_in[rank * chunk + split_id * sub + tid];
#pragma unroll
        for(int j = 0; j < 4; ++j)
            own.i[j] = lamportCanonicalize(own.i[j]);
        s_data[rank][tid] = own.data;
    }
    // local operands of the epilogue, loaded before the waits
    const int64_t out_id = (int64_t)row * row_packs + split_id * block_packs + tid;
    P res[SPLIT];
#pragma unroll
    for(int k = 0; k < SPLIT; ++k)
        res[k] = *(reinterpret_cast<const P*>(residual_inp) + (int64_t)row * row_packs +
                   k * block_packs + tid);
    const P w = *(reinterpret_cast<const P*>(weight) + split_id * block_packs + tid);
    if(is_relay)
    {
        pack got;
        got.i = lamportPollSlot(self_inbox + row_off + relay_peer * src_packs + chunk_pos);
        s_data[relay_peer][relay_pos] = got.data;
    }
    __syncthreads();

    // broadcast
    if(is_relay)
    {
        A sum;
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
        {
            const P rank_data = s_data[g][relay_pos];
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                sum[j] = g == 0 ? upcastS(rank_data[j]) : sum[j] + upcastS(rank_data[j]);
        }
        pack sum_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            sum_val.data[j] = downcastS<T>(sum[j]);
#pragma unroll
        for(int j = 0; j < 4; ++j)
            sum_val.i[j] = lamportCanonicalize(sum_val.i[j]);
        const int64_t bcast_id = inbox_packs + row_off + rank * chunk + chunk_pos;
        auto dst = lamportPeerPtr<ngpus, ui32x4_t>(peers, relay_peer);
        __builtin_nontemporal_store(sum_val.i, dst + bcast_id);
        if(tid < sub)
            __builtin_nontemporal_store(sum_val.i, self_inbox + bcast_id);
    }

    // epilogue: the whole row from the broadcast inbox
    A acc;
    P res_out;
    const ui32x4_t* bcast_row = self_inbox + inbox_packs + row_off + tid;
    pack sums[SPLIT];
    uint32_t wait_mask;
    do
    {
        // without the memory clobber the loads are hoisted out of the loop
        asm volatile("" ::: "memory");
#pragma unroll
        for(int k = 0; k < SPLIT; ++k)
            sums[k].i = __builtin_nontemporal_load(bcast_row + k * block_packs);
        // issue every load before any mask math
        __builtin_amdgcn_sched_barrier(0);
        wait_mask = 0;
#pragma unroll
        for(int k = 0; k < SPLIT; ++k)
#pragma unroll
            for(int j = 0; j < 4; ++j)
                wait_mask |= lamportSentinelMask(sums[k].i[j]);
    } while(wait_mask != 0);
#pragma unroll
    for(int k = 0; k < SPLIT; ++k)
    {
        A acc_k;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            acc_k[j] = upcastS(sums[k].data[j]);
        P res_out_k;
        // acc_k is already rounded to T, the rounding in here keeps it
        const float square_sum = lamportRmsResidual<T>(acc_k, res[k], res_out_k);
        const float part       = warpReduce<AddFunctor, float, kLamportRmsLanes>(square_sum);
        if(tid % kLamportRmsLanes == 0)
            s_part[(k * block_packs + tid) / kLamportRmsLanes] = part;
        if(k == split_id)
        {
            acc     = acc_k;
            res_out = res_out_k;
        }
    }
    *(reinterpret_cast<P*>(residual_out) + out_id) = res_out;
    __syncthreads();
    // every wave folds the row's partials itself, the same bits in each
    const int row_partials = row_packs / kLamportRmsLanes;
    const int width        = lamportRmsWidth(row_partials);
    const int part_lane    = tid % kLamportWaveSize & (width - 1);
    float v                = part_lane < row_partials ? s_part[part_lane] : 0.f;
    v                      = lamportRmsFold(v, width);
    const float rms        = rsqrtf(v / hidden + eps);
    *(reinterpret_cast<P*>(output) + out_id) = lamportRmsNorm<T>(acc, w, rms, gemma_norm);

    // re-arm what last round's buffer got, shared out over the row's blocks:
    // written packs of the broadcast row, written / ngpus of every reduce
    // slot (the own slot is never written, clearing it is harmless)
    const ui32x4_t sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
    const int64_t rearm_off =
        rearm * kLamportArRms2BufPacks + (int64_t)row * kLamportArRms2SlotPacks;
    const int written_chunk = (int)written / ngpus;
    for(int p = split_id * block_packs + tid; p < (int)written; p += row_packs)
    {
        __builtin_nontemporal_store(sentinel, self_inbox + inbox_packs + rearm_off + p);
        const int src = p / written_chunk;
        __builtin_nontemporal_store(
            sentinel, self_inbox + rearm_off + src * src_packs + (p - src * written_chunk));
    }

    if(split_id == 0 && tid == 0)
    {
        row_written[row * kLamportBuffers + round] = row_packs;
        row_round[row]                             = (round + 1) % kLamportBuffers;
    }
}

} // namespace commkit::gfx9
