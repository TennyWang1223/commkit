#pragma once
// reduce_scatter, simple proto, pull, 16-byte packs (aiter
// rs_gfx1250_split_{first_dim,lastdim,middim}). Rank r sums chunk r of every
// rank's staged input in rank order (fp32, rounded once), straight from the
// peers' memory. The input is seen as (m, n, k), scattered along n:
//   first dim  m == 1: chunk r is a contiguous range
//   last dim   k == 1: (m, n) rows, chunk r is columns [r n / ngpus, ...)
//   middle     (m, n, k), chunk r is n-slice [r n / ngpus, ...)
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

// range: packs per rank, numel / (ngpus * pack_size)
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) rsSimplePullFirstDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int range)
{
    int tid                 = blockIdx.x * blockDim.x + threadIdx.x;
    int stride              = blockDim.x * gridDim.x;
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        // Keep the sum order independent of the reduce-scatter owner.
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int idx = tid; idx < range; idx += stride)
    {
        int load_index = rank * range + idx;
        A acc;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            acc[j] = upcastS(ptrs[0][load_index][j]);
#pragma unroll
        for(int g = 1; g < ngpus; ++g)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                acc[j] += upcastS(ptrs[g][load_index][j]);
        }
        P out_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            out_val[j] = downcastS<T>(acc[j]);
        *(reinterpret_cast<P*>(result) + idx) = out_val;
    }
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
    int size                = m * n / (ngpus * pack_size);
    int splited_n           = n / (ngpus * pack_size);
    int packed_dim_n        = n / pack_size;
    int index               = blockIdx.x * blockDim.x + threadIdx.x;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        // Keep the sum order independent of the reduce-scatter owner.
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        int index_x    = i % splited_n;
        int index_y    = i / splited_n;
        int load_index = index_y * packed_dim_n + rank * splited_n + index_x;
        P inp_reg[ngpus];
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            inp_reg[g] = ptrs[g][load_index];
        A acc;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            acc[j] = upcastS(inp_reg[0][j]);
#pragma unroll
        for(int g = 1; g < ngpus; ++g)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                acc[j] += upcastS(inp_reg[g][j]);
        }
        P out_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            out_val[j] = downcastS<T>(acc[j]);
        *(reinterpret_cast<P*>(result) + i) = out_val;
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
    int size                = m * n * k / (pack_size * ngpus);
    int splited_n           = n / ngpus;
    int packed_dim_k        = k / pack_size;
    int index               = blockIdx.x * blockDim.x + threadIdx.x;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        // Keep the sum order independent of the reduce-scatter owner.
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        int index_m    = i / (splited_n * packed_dim_k);
        int index_n    = (i % (splited_n * packed_dim_k)) / packed_dim_k;
        int index_k    = (i % (splited_n * packed_dim_k)) % packed_dim_k;
        int load_index = index_m * (n * packed_dim_k) + (rank * splited_n + index_n) * packed_dim_k + index_k;
        P inp_reg[ngpus];
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            inp_reg[g] = ptrs[g][load_index];
        A acc;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            acc[j] = upcastS(inp_reg[0][j]);
#pragma unroll
        for(int g = 1; g < ngpus; ++g)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                acc[j] += upcastS(inp_reg[g][j]);
        }
        P out_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            out_val[j] = downcastS<T>(acc[j]);
        *(reinterpret_cast<P*>(result) + i) = out_val;
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
