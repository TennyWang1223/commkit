#pragma once
// all_reduce, lamport proto, push, two-shot, wave split (aiter
// lamportAllReduceTwoShotWaveSplit).
#include "gfx9/proto/lamport.cuh"

namespace commkit::gfx9 {

/*
 * Two-shot: the message is ngpus chunks of `part` packs, chunk j is reduced on
 * rank j. Position t = kLamportWaveSize * blockIdx.x + lane, t < part, stands
 * for pack j * part + t of every chunk j, on every rank.
 *   reduce-scatter: wave w loads pack t of chunk peer = (rank + w) % ngpus,
 *     pushes it into slot[rank] of peer's rs inbox and polls slot[peer] of its
 *     own, where peer put its copy of this rank's chunk. Wave 0 loads this
 *     rank's chunk. All of it goes to LDS by source rank, one __syncthreads.
 *   all-gather: every wave sums the LDS entries in rank order itself (same
 *     bits in every wave, no second sync). Wave 0 writes this rank's chunk of
 *     the output; wave w pushes the sum into slot[rank] of peer's ag inbox,
 *     polls slot[peer] of its own and writes peer's chunk.
 * peers.ptrs[i] is rank i's rs inbox, its ag inbox follows. Both inboxes use
 * the block's one round counter. Ranks stay at most one round apart: nobody
 * finishes round c without every peer's round c ag data. A rank may still be
 * waiting for round c-1 ag data while a peer is in round c, but by then it has
 * sent everything of round c-1, so the peer's re-arm at the end of round c is
 * still safe.
 */
template <typename T, int ngpus>
__global__ void __launch_bounds__(ngpus * kLamportWaveSize, 1) arTwoShotLamportWarpSplit(
    const T* __restrict__ input,
    T* __restrict__ result,
    LamportPeers peers,
    uint32_t* __restrict__ round_counter, // [lamportTwoShotMaxBlocks(ngpus)], rank-local
    int rank,
    int part) // packs per chunk, the message is ngpus * part packs
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
    constexpr int pack_size = 16 / sizeof(T);
    // positions per inbox slot; packs from one buffer to the next, and from
    // the rs inbox to the ag inbox
    constexpr int64_t max_part     = lamportTwoShotMaxPart(ngpus);
    constexpr int64_t buffer_packs = ngpus * max_part;
    constexpr int64_t inbox_packs  = kLamportBuffers * buffer_packs;
    using P        = typename opus::vector_t<T, pack_size>;
    using A        = typename opus::vector_t<opus::fp32_t, pack_size>;
    using ui32x4_t = __attribute__((__vector_size__(4 * sizeof(uint32_t)))) uint32_t;
    union pack
    {
        P data;
        ui32x4_t i;
    };

    __shared__ uint32_t s_round;
    __shared__ P s_data[ngpus][kLamportWaveSize]; // by source rank
    if(threadIdx.x == 0)
        s_round = round_counter[blockIdx.x];
    __syncthreads();
    const uint32_t round = s_round;
    const uint32_t rearm = (round + 2) % kLamportBuffers;

    const int wave_id    = __builtin_amdgcn_readfirstlane(threadIdx.x / kLamportWaveSize);
    const int lane_id    = threadIdx.x % kLamportWaveSize;
    const int peer       = (rank + wave_id) % ngpus;
    const int pos        = blockIdx.x * kLamportWaveSize + lane_id;
    const bool is_active = pos < part;

    ui32x4_t* self_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[rank]);
    ui32x4_t* peer_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[peer]);
    // this round's slot written in peer's inbox, and the one polled in mine
    const int64_t send_off = round * buffer_packs + rank * max_part + pos;
    const int64_t recv_off = round * buffer_packs + peer * max_part + pos;

    // reduce-scatter
    if(is_active)
    {
        pack pack_val;
        pack_val.data = *(reinterpret_cast<const P*>(input) + (int64_t)peer * part + pos);
#pragma unroll
        for(int j = 0; j < 4; ++j)
            pack_val.i[j] = lamportCanonicalize(pack_val.i[j]);

        if(wave_id != 0)
        {
            __builtin_nontemporal_store(pack_val.i, peer_inbox + send_off);
            pack_val.i = lamportPollSlot(self_inbox + recv_off);
        }
        s_data[peer][lane_id] = pack_val.data;
    }
    __syncthreads();

    // all-gather
    if(is_active)
    {
        A acc;
#pragma unroll
        for(int i = 0; i < ngpus; ++i)
        {
            const P rank_data = s_data[i][lane_id];
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                acc[j] = i == 0 ? upcastS(rank_data[j]) : acc[j] + upcastS(rank_data[j]);
        }
        pack sum_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            sum_val.data[j] = downcastS<T>(acc[j]);
        // peers would take a 0xffff sum for "not arrived"; this rank's output
        // uses the same canonical bits
#pragma unroll
        for(int j = 0; j < 4; ++j)
            sum_val.i[j] = lamportCanonicalize(sum_val.i[j]);

        if(wave_id == 0)
        {
            *(reinterpret_cast<P*>(result) + (int64_t)rank * part + pos) = sum_val.data;
        }
        else
        {
            __builtin_nontemporal_store(sum_val.i, peer_inbox + inbox_packs + send_off);
            sum_val.i = lamportPollSlot(self_inbox + inbox_packs + recv_off);
            *(reinterpret_cast<P*>(result) + (int64_t)peer * part + pos) = sum_val.data;
        }
    }

    if(wave_id != 0)
    {
        // re-arm slot[peer] of last round's buffer in both inboxes, on every lane
        const ui32x4_t sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
        const int64_t rearm_off = rearm * buffer_packs + peer * max_part + pos;
        __builtin_nontemporal_store(sentinel, self_inbox + rearm_off);
        __builtin_nontemporal_store(sentinel, self_inbox + inbox_packs + rearm_off);
    }

    if(threadIdx.x == 0)
        round_counter[blockIdx.x] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx9
