#pragma once
// all_gather, simple proto, pull, naive (aiter ag_gfx1250_scalar): first dim,
// element by element, any size.
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

// size: elements of a rank's input
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) agSimplePullNaive(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    int tid    = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    const T* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        ptrs[i] = (const T*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = tid; idx < size; idx += stride)
    {
#pragma unroll
        for(int i = 0; i < ngpus; ++i)
        {
            int gpu_idx                    = (rank + i) % ngpus;
            result[gpu_idx * size + idx] = ptrs[gpu_idx][idx];
        }
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
