#pragma once
// all_reduce, simple proto, pull, one-shot, naive (aiter
// cross_device_reduce_1stage_naive, the vLLM original): every thread sums its
// pack over every rank's input straight from the peers' memory.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) arOneShotSimplePullNaive(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    // the addresses are not reordered, so every rank sums in the same order
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = blockIdx.x * blockDim.x + threadIdx.x; idx < size; idx += gridDim.x * blockDim.x)
        ((P*)result)[idx] = packedReduce<P, ngpus, A>((const P**)&dp.ptrs[0], idx);
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
