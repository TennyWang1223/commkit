#pragma once
// all_gather, simple proto, pull (aiter ag_gfx1250_naive_unroll4 /
// ag_gfx1250_lastdim). Every thread copies 4 packs a round of every rank's
// staged input, read in place from the peers' memory, starting with its own
// rank's, into their places in the output.
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

// first dim: rank g's input is output packs [g * size, (g + 1) * size). A block
// copies 4 x blockDim.x packs a round, so size is whole multiples of that
// (1024 packs at 256 threads): a partial last tile is skipped.
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 2) agSimplePull(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int unroll    = 4;
    using P                 = typename opus::vector_t<T, pack_size>;
    int index               = blockIdx.x * blockDim.x * unroll + threadIdx.x;
    int stride              = blockDim.x * gridDim.x * unroll;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = index; idx + blockDim.x * (unroll - 1) < size; idx += stride)
    {
#pragma unroll
        for(int i = 0; i < ngpus; ++i)
        {
            int rank_idx = (rank + i) % ngpus;
#pragma unroll
            for(int j = 0; j < unroll; ++j)
            {
                *(reinterpret_cast<P*>(result) + size * rank_idx + idx + j * blockDim.x) =
                    ptrs[rank_idx][idx + j * blockDim.x];
            }
        }
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

// last dim: row y of the output is rank 0's row y, rank 1's row y, ...
// size: packs of the input; last_dim_size: elements of its last dim
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) agSimplePullLastDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size, int last_dim_size)
{
    constexpr int unroll    = 4;
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    int tid                 = blockIdx.x * blockDim.x * unroll + threadIdx.x;
    int stride              = gridDim.x * blockDim.x * unroll;

    last_dim_size /= pack_size;
    const P* ptrs[ngpus];

#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);

    for(int idx = tid; idx < size; idx += stride)
    {
#pragma unroll
        for(int i = 0; i < ngpus; ++i)
        {
            int rank_idx = (rank + i) % ngpus;
#pragma unroll
            for(int j = 0; j < unroll; ++j)
            {
                int read_idx = idx + j * blockDim.x;
                if(read_idx >= size)
                    break;
                int y         = read_idx / last_dim_size;
                int x         = read_idx % last_dim_size;
                int write_idx = (ngpus * y + rank_idx) * last_dim_size + x;
                *(reinterpret_cast<P*>(result) + write_idx) = ptrs[rank_idx][read_idx];
            }
        }
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
