#pragma once
// all_gather, simple proto, pull (aiter allgather_vec / allgather_lastdim).
// The block splits into ngpus groups of 512 / ngpus threads; group g copies
// rank g's input, 16-byte packs, into its place in the output.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

// first dim: rank g's input is output rows [g * rows, (g + 1) * rows)
template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) agSimplePull(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int tnum_gpu  = kSimpleThreads / ngpus;
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    const int warp_id       = threadIdx.x / tnum_gpu;
    const int lane_id       = threadIdx.x % tnum_gpu;
    const int tid           = blockIdx.x * tnum_gpu + lane_id;
    const int stride        = gridDim.x * tnum_gpu;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const P*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = tid; idx < size; idx += stride)
        *(reinterpret_cast<P*>(result) + warp_id * size + idx) = ptrs[warp_id][idx];
    endSync<ngpus, true>(sg, self_sg, rank);
}

// last dim: row y of the output is rank 0's row y, rank 1's row y, ...
template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) agSimplePullLastDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size, int last_dim_size)
{
    constexpr int tnum_gpu  = kSimpleThreads / ngpus;
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    const int warp_id       = threadIdx.x / tnum_gpu;
    const int lane_id       = threadIdx.x % tnum_gpu;
    const int tid           = blockIdx.x * tnum_gpu + lane_id;
    const int stride        = gridDim.x * tnum_gpu;
    last_dim_size /= pack_size;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const P*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = tid; idx < size; idx += stride)
    {
        const int y         = idx / last_dim_size;
        const int x         = idx % last_dim_size;
        const int write_idx = (ngpus * y + warp_id) * last_dim_size + x;
        *(reinterpret_cast<P*>(result) + write_idx) = ptrs[warp_id][idx];
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
