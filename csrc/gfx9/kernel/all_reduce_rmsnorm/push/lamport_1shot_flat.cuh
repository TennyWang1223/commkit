#pragma once
// all_reduce + residual + RMSNorm, lamport proto, push, one-shot, flat
// (aiter lamportArRmsFlat).
#include "gfx9/epilogue/rmsnorm.cuh"
#include "gfx9/proto/lamport.cuh"

namespace commkit::gfx9 {

/*
 * Flat: thread t owns pack t. ROW: the block is the row (blockDim = hidden / 8
 * <= BLOCK); else blocks of BLOCK packs, the row split over hidden / 8 / BLOCK
 * of them.
 */
template <typename T, int ngpus, int BLOCK, bool ROW>
__global__ void __launch_bounds__(BLOCK, 1) arRmsOneShotLamportFlat(
    const T* __restrict__ input,
    const T* __restrict__ residual_inp,
    T* __restrict__ residual_out,
    T* __restrict__ output,
    const T* __restrict__ weight,
    LamportPeers peers,
    uint32_t* __restrict__ inbox_round,   // [kLamportMaxBlocks], of this kernel's inbox
    uint32_t* __restrict__ partials,      // [kLamportBuffers][kLamportRmsMaxPartials], split only
    uint32_t* __restrict__ partial_round, // [kLamportMaxBlocks], split only
    int rank,
    int hidden,
    float eps,
    bool gemma_norm)
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
    static_assert(BLOCK % kLamportWaveSize == 0, "a round counter covers a whole wave");
    constexpr int pack_size        = 16 / sizeof(T);
    constexpr int64_t buffer_packs = (int64_t)ngpus * kLamportMaxPacks;
    using P        = typename opus::vector_t<T, pack_size>;
    using A        = typename opus::vector_t<opus::fp32_t, pack_size>;
    using ui32x4_t = __attribute__((__vector_size__(4 * sizeof(uint32_t)))) uint32_t;
    union pack
    {
        P data;
        ui32x4_t i;
    };

    __shared__ float s_rms;
    const int row_packs   = hidden / pack_size;
    const int block_packs = ROW ? row_packs : BLOCK;
    // the grid covers whole rows, so every thread owns a pack
    const int pack_id = blockIdx.x * block_packs + threadIdx.x;
    const int row     = pack_id / row_packs;
    const int col     = pack_id - row * row_packs;
    // a wave is one group of positions, so the counters are scalar loads
    const int group      = __builtin_amdgcn_readfirstlane(pack_id / kLamportWaveSize);
    const uint32_t round = inbox_round[group];
    const uint32_t rearm = (round + 2) % kLamportBuffers;

    ui32x4_t* self_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[rank]);

    pack local_pack;
    local_pack.data = *(reinterpret_cast<const P*>(input) + pack_id);
#pragma unroll
    for(int j = 0; j < 4; ++j)
        local_pack.i[j] = lamportCanonicalize(local_pack.i[j]);
#pragma unroll
    for(int i = 1; i < ngpus; ++i)
    {
        ui32x4_t* peer_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[(rank + i) % ngpus]);
        __builtin_nontemporal_store(
            local_pack.i, peer_inbox + round * buffer_packs + rank * kLamportMaxPacks + pack_id);
    }

    // local operands of the epilogue, loaded before the wait
    const P res = *(reinterpret_cast<const P*>(residual_inp) + pack_id);
    const P w   = *(reinterpret_cast<const P*>(weight) + col);

    // slot[rank] is never written and stays the sentinel; it is loaded anyway
    // and masked out, a branch would make every load wait for the previous one
    const ui32x4_t* inbox = self_inbox + round * buffer_packs + pack_id;
    pack scratch[ngpus];
    uint32_t wait_mask;
    do
    {
        asm volatile("" ::: "memory");
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            scratch[g].i = __builtin_nontemporal_load(inbox + g * kLamportMaxPacks);
        // issue every load before any mask math
        __builtin_amdgcn_sched_barrier(0);
        wait_mask = 0;
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
        {
            uint32_t slot_mask = 0;
#pragma unroll
            for(int j = 0; j < 4; ++j)
                slot_mask |= lamportSentinelMask(scratch[g].i[j]);
            wait_mask |= g == rank ? 0u : slot_mask;
        }
    } while(wait_mask != 0);

    A acc;
#pragma unroll
    for(int g = 0; g < ngpus; ++g)
    {
        const P rank_data = g == rank ? local_pack.data : scratch[g].data;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            acc[j] = g == 0 ? upcastS(rank_data[j]) : acc[j] + upcastS(rank_data[j]);
    }
    float square_sum =
        lamportRmsAddResidual<T>(acc, res, reinterpret_cast<P*>(residual_out) + pack_id);

    if constexpr(ROW)
    {
        square_sum = rmsnormBlockReduce<AddFunctor, float, kLamportRmsLanes>(
            square_sum, row_packs);
        if(threadIdx.x == 0)
            s_rms = rsqrtf(square_sum / hidden + eps);
    }
    else
    {
        // wave 0's group is in the row, so its partial round is the row's
        const uint32_t p_round = partial_round[group];
        const uint32_t p_rearm = (p_round + 2) % kLamportBuffers;
        const float part = warpReduce<AddFunctor, float, kLamportRmsLanes>(square_sum);
        if(threadIdx.x % kLamportRmsLanes == 0)
            lamportRmsPublish(partials, p_round, p_rearm, pack_id / kLamportRmsLanes, part);
        if(threadIdx.x < kLamportRmsLanes)
        {
            const int row_partials = row_packs / kLamportRmsLanes;
            float v                = 0.f;
            if((int)threadIdx.x < row_partials)
                v = lamportRmsPollPartial(partials + p_round * kLamportRmsMaxPartials +
                                          row * row_partials + threadIdx.x);
            // only thread 0's sum is used
            v = lamportRmsFold(v, lamportRmsWidth(row_partials));
            if(threadIdx.x == 0)
                s_rms = rsqrtf(v / hidden + eps);
        }
        if(threadIdx.x % kLamportWaveSize == 0)
            partial_round[group] = (p_round + 1) % kLamportBuffers;
    }
    __syncthreads();
    *(reinterpret_cast<P*>(output) + pack_id) = lamportRmsNorm<T>(acc, w, s_rms, gemma_norm);

    // re-arm last round's buffer, every peer's slot
    const ui32x4_t sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
#pragma unroll
    for(int i = 1; i < ngpus; ++i)
        __builtin_nontemporal_store(sentinel,
                                    self_inbox + rearm * buffer_packs +
                                        (rank + i) % ngpus * kLamportMaxPacks + pack_id);

    if(threadIdx.x % kLamportWaveSize == 0)
        inbox_round[group] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx9
