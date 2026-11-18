#pragma once
// all_gather, simple proto, pull, naive (aiter allgather_naive): first dim,
// element by element, any size.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) agSimplePullNaive(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int tnum_gpu = kSimpleThreads / ngpus;
    const int warp_id      = threadIdx.x / tnum_gpu;
    const int lane_id      = threadIdx.x % tnum_gpu;
    const int tid          = blockIdx.x * tnum_gpu + lane_id;
    const int stride       = gridDim.x * tnum_gpu;
    const T* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const T*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = tid; idx < size; idx += stride)
        result[warp_id * size + idx] = ptrs[warp_id][idx];
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
