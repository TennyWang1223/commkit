#pragma once
// all_reduce + residual + RMSNorm, lamport proto, push, one-shot (aiter
// lamport_ar_rmsnorm_gfx1250).
#include "gfx1250/epilogue/rmsnorm.cuh"
#include "gfx1250/proto/lamport.cuh"

namespace commkit::gfx1250 {

/*
 * No barrier and no copy-in: every thread owns one 16B pack, pushes it into
 * slot[rank] of each peer's inbox, then polls its own inbox until no half-word
 * is the 0xffff sentinel. The epilogue then follows the simple one-shot
 * (arRmsSimplePull) step by step (rank-order fp32 sum, round to T,
 * add the residual, a 32-lane butterfly then a serial sum over the waves of the
 * row), so out and residual_out match it bit for bit.
 *
 * The grid covers whole rows. The sum of squares of a row is reduced
 *   - row:     one block a row (blockDim = hidden / 8), on chip.
 *   - cluster: the blocks of a row are one workgroup cluster (2 to 16 blocks);
 *              the wave partials go through rank-local memory, ordered by the
 *              cluster barrier. Spreads a row over more CUs while the rows do
 *              not fill the device.
 *
 * MAX_THREADS only bounds the block; blockDim.x is the block size, a multiple
 * of kLamportWave.
 */
template <typename T, int ngpus, int MAX_THREADS, bool CLUSTER>
__global__ void __launch_bounds__(MAX_THREADS, 1) arRmsOneShotLamport(
    const T* __restrict__ input,
    const T* __restrict__ residual_inp,
    T* __restrict__ residual_out,
    T* __restrict__ output,
    const T* __restrict__ weight,
    LamportPeers peers,
    float* __restrict__ cluster_partials, // [slot / 32], CLUSTER only, rank-local
    uint32_t* __restrict__ round_counter, // [slot / 32], one a wave of packs, rank-local
    int slot,                             // inbox packs per sender
    int rank,
    int hidden,
    float eps,
    bool gemma_norm)
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
    static_assert(MAX_THREADS % kLamportWave == 0, "blocks are whole waves");
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    union pack
    {
        P data;
        u32x4 i;
    };

    // the grid covers whole rows, so every thread owns a pack
    const int row_packs = hidden / pack_size;
    const int tid       = blockIdx.x * blockDim.x + threadIdx.x;
    const int row       = tid / row_packs;
    const int col       = tid - row * row_packs;
    // blocks are whole waves, so this is uniform over the wave
    const int wave       = __builtin_amdgcn_readfirstlane(tid / kLamportWave);
    const uint32_t round = round_counter[wave];
    const uint32_t rearm = (round + 2) % kLamportBuffers;

    pack local;
    local.data = reinterpret_cast<const P*>(input)[tid];
#pragma unroll
    for(int j = 0; j < 4; ++j)
        local.i[j] = lamportCanonicalize(local.i[j]);

#pragma unroll
    for(int i = 1; i < ngpus; ++i)
    {
        P* dst = reinterpret_cast<P*>(peers.ptrs[(rank + i) % ngpus]) + (round * ngpus + rank) * slot + tid;
        lamportStoreB128(dst, local.i);
    }

    // local operands of the epilogue, loaded before the wait
    const P res = reinterpret_cast<const P*>(residual_inp)[tid];
    const P w   = reinterpret_cast<const P*>(weight)[col];

    const P* inbox = reinterpret_cast<const P*>(peers.ptrs[rank]) + round * ngpus * slot + tid;
    pack scratch[ngpus];
    lamportPollInbox<ngpus>(scratch, inbox, slot, rank);

    // same steps as arRmsSimplePull
    float x[pack_size] = {};
#pragma unroll
    for(int g = 0; g < ngpus; ++g)
    {
        const P v = g == rank ? local.data : scratch[g].data;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            x[j] += upcastS(v[j]);
    }
    P sum;
    const float square_sum                  = rmsnormAddResidual<T>(x, res, sum);
    reinterpret_cast<P*>(residual_out)[tid] = sum;

    float inv_rms;
    if constexpr(CLUSTER)
    {
#if CK_GFX1250_HAVE_CLUSTER
        // the row is this cluster: publish a partial per wave, then every wave
        // folds the row's partials in wave order, as blockAllreduceF32 does.
        // The partials move as their uint32 bits: clang 20 takes no float in
        // the __scoped_atomic_*_n builtins.
        float part = square_sum;
        for(int off = kLamportWave / 2; off > 0; off >>= 1)
            part = part + __shfl_xor(part, off);
        const int lane      = threadIdx.x % kLamportWave;
        uint32_t* part_bits = reinterpret_cast<uint32_t*>(cluster_partials);
        if(lane == 0)
            __scoped_atomic_store_n(
                part_bits + wave, __builtin_bit_cast(uint32_t, part), __ATOMIC_RELAXED, __MEMORY_SCOPE_CLUSTR);
        __builtin_amdgcn_fence(__ATOMIC_RELEASE, "cluster");
        __builtin_amdgcn_s_cluster_barrier();
        __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "cluster");
        const int row_groups = row_packs / kLamportWave;
        const float v        = lane < row_groups
                                   ? __builtin_bit_cast(float,
                                                        __scoped_atomic_load_n(part_bits + row * row_groups + lane,
                                                                               __ATOMIC_RELAXED,
                                                                               __MEMORY_SCOPE_CLUSTR))
                                   : 0.f;
        float total          = __shfl(v, 0);
        for(int g = 1; g < row_groups; ++g)
            total += __shfl(v, g);
        inv_rms = rsqrtf(total / hidden + eps);
#else
        // never launched: the host takes this path only with cluster launch
        __builtin_trap();
        inv_rms = 0.f;
#endif
    }
    else
    {
        inv_rms = rsqrtf(blockAllreduceF32(square_sum) / hidden + eps);
    }

    reinterpret_cast<P*>(output)[tid] = rmsnormScale<T>(x, w, inv_rms, gemma_norm);

    const u32x4 sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
#pragma unroll
    for(int i = 1; i < ngpus; ++i)
    {
        P* dst = reinterpret_cast<P*>(peers.ptrs[rank]) + (rearm * ngpus + (rank + i) % ngpus) * slot + tid;
        lamportStoreB128(dst, sentinel);
    }

    if(threadIdx.x % kLamportWave == 0)
        round_counter[wave] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx1250
