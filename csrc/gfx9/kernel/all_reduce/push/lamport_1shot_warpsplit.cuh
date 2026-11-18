#pragma once
// all_reduce, lamport proto, push, one-shot, wave split (aiter lamportAllReduceWaveSplit).
#include "gfx9/proto/lamport.cuh"

namespace commkit::gfx9 {

/*
 * One-shot: wave w loads the block's packs, pushes them into slot[rank] of the
 * inbox of rank peer = (rank + w) % ngpus, polls slot[peer] of its own inbox
 * and puts what it got into LDS by source rank. Wave 0 puts its own packs
 * there. After one __syncthreads wave 0 sums in rank order and writes the
 * output while the other waves re-arm their slot.
 */
template <typename T, int ngpus>
__global__ void __launch_bounds__(ngpus * kLamportWaveSize, 1) arOneShotLamportWarpSplit(
    const T* __restrict__ input,
    T* __restrict__ result,
    LamportPeers peers,
    uint32_t* __restrict__ round_counter, // [kLamportMaxBlocks], rank-local
    int rank,
    int num_packs) // 16B packs in the message
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
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

    __shared__ uint32_t s_round;
    __shared__ P s_data[ngpus][kLamportWaveSize]; // by source rank
    if(threadIdx.x == 0)
        s_round = round_counter[blockIdx.x];
    __syncthreads();
    const uint32_t round = s_round;
    const uint32_t rearm = (round + 2) % kLamportBuffers;

    // wave-uniform, so the branches below are scalar and the pointers SGPRs
    const int wave_id    = __builtin_amdgcn_readfirstlane(threadIdx.x / kLamportWaveSize);
    const int lane_id    = threadIdx.x % kLamportWaveSize;
    const int peer       = (rank + wave_id) % ngpus;
    const int pack_id    = blockIdx.x * kLamportWaveSize + lane_id;
    const bool is_active = pack_id < num_packs;

    ui32x4_t* self_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[rank]);
    ui32x4_t* peer_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[peer]);

    if(is_active)
    {
        // every wave loads the same packs, the repeats mostly hit the cache
        pack pack_val;
        pack_val.data = *(reinterpret_cast<const P*>(input) + pack_id);
#pragma unroll
        for(int j = 0; j < 4; ++j)
            pack_val.i[j] = lamportCanonicalize(pack_val.i[j]);

        if(wave_id != 0)
        {
            __builtin_nontemporal_store(
                pack_val.i,
                peer_inbox + round * buffer_packs + rank * kLamportMaxPacks + pack_id);
            pack_val.i = lamportPollSlot(self_inbox + round * buffer_packs +
                                         peer * kLamportMaxPacks + pack_id);
        }
        s_data[peer][lane_id] = pack_val.data;
    }
    __syncthreads();

    if(wave_id != 0)
    {
        // re-arm slot[peer] of last round's buffer, on every lane
        const ui32x4_t sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
        __builtin_nontemporal_store(
            sentinel, self_inbox + rearm * buffer_packs + peer * kLamportMaxPacks + pack_id);
    }
    else if(is_active)
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
        P out_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            out_val[j] = downcastS<T>(acc[j]);
        *(reinterpret_cast<P*>(result) + pack_id) = out_val;
    }

    if(threadIdx.x == 0)
        round_counter[blockIdx.x] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx9
