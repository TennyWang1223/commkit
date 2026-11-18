#pragma once
// all_gather, simple proto, pull, first dim, one pack a thread a round (aiter
// ag_gfx1250_naive_vec): every rank's staged input, read in place from the
// peers' memory, starting with its own rank's, into its place in the output.
// Any whole number of packs.
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

// size: packs of a rank's input
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 2) agSimplePullVec(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    int index               = blockIdx.x * blockDim.x + threadIdx.x;
    int stride              = blockDim.x * gridDim.x;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = index; idx < size; idx += stride)
    {
#pragma unroll
        for(int i = 0; i < ngpus; ++i)
        {
            int rank_idx = (rank + i) % ngpus;
            *(reinterpret_cast<P*>(result) + size * rank_idx + idx) = ptrs[rank_idx][idx];
        }
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
