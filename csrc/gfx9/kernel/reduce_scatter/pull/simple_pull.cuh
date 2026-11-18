#pragma once
// reduce_scatter, simple proto, pull, 16-byte packs (aiter
// reduce_scatter_split_{first,last,mid}_dim). Rank r sums chunk r of every
// rank's input in rank order, straight from the peers' memory. The input is
// seen as (m, n, k), scattered along n:
//   first dim  m == 1: chunk r is a contiguous range
//   last dim   k == 1: (m, n) rows, chunk r is columns [r n / ngpus, ...)
//   middle     (m, n, k), chunk r is n-slice [r n / ngpus, ...)
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

// range: packs per rank, numel / (ngpus * pack_size)
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) rsSimplePullFirstDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int range)
{
    const int tid           = blockIdx.x * blockDim.x + threadIdx.x;
    const int stride        = blockDim.x * gridDim.x;
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
        ptrs[i] = (const P*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = tid; idx < range; idx += stride)
        *(reinterpret_cast<P*>(result) + idx) = packedReduce<P, ngpus, A>(ptrs, rank * range + idx);
    endSync<ngpus, true>(sg, self_sg, rank);
}

// input (m, n) -> output (m, n / ngpus); n % (ngpus * pack_size) == 0
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 1) rsSimplePullLastDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int m, int n)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int size          = m * n / (ngpus * pack_size);
    const int splited_n     = n / (ngpus * pack_size);
    const int packed_dim_n  = n / pack_size;
    const int index         = blockIdx.x * blockDim.x + threadIdx.x;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const P*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        const int index_x    = i % splited_n;
        const int index_y    = i / splited_n;
        const int load_index = index_y * packed_dim_n + rank * splited_n + index_x;
        *(reinterpret_cast<P*>(result) + i) = packedReduce<P, ngpus, A>(ptrs, load_index);
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

// input (m, n, k) -> output (m, n / ngpus, k); k % pack_size == 0
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 1) rsSimplePullMidDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int m, int n, int k)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int size          = m * n * k / (pack_size * ngpus);
    const int splited_n     = n / ngpus;
    const int packed_dim_k  = k / pack_size;
    const int index         = blockIdx.x * blockDim.x + threadIdx.x;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const P*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        const int index_m    = i / (splited_n * packed_dim_k);
        const int index_n    = (i % (splited_n * packed_dim_k)) / packed_dim_k;
        const int index_k    = (i % (splited_n * packed_dim_k)) % packed_dim_k;
        const int load_index = index_m * (n * packed_dim_k) + (rank * splited_n + index_n) * packed_dim_k + index_k;
        *(reinterpret_cast<P*>(result) + i) = packedReduce<P, ngpus, A>(ptrs, load_index);
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
