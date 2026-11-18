#pragma once
// reduce_scatter, simple proto, pull, element by element (aiter
// reduce_scatter_split_{last,mid}dim_naive): for inner dims that are not
// whole 16-byte packs. The input is seen as (m, n, k), scattered along n.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

// input (m, n) -> output (m, n / ngpus)
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 1) rsSimplePullNaiveLastDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int m, int n)
{
    const int size      = m * n / ngpus;
    const int splited_n = n / ngpus;
    const int index     = blockIdx.x * blockDim.x + threadIdx.x;
    const T* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const T*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        const int index_x    = i % splited_n;
        const int index_y    = i / splited_n;
        const int load_index = index_y * n + rank * splited_n + index_x;
        opus::fp32_t rslt_reg = 0.0f;
#pragma unroll
        for(int j = 0; j < ngpus; ++j)
            rslt_reg += upcastS(ptrs[j][load_index]);
        result[i] = downcastS<T>(rslt_reg);
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

// input (m, n, k) -> output (m, n / ngpus, k)
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 1) rsSimplePullNaiveMidDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int m, int n, int k)
{
    const int size      = m * n * k / ngpus;
    const int splited_n = n / ngpus;
    const int index     = blockIdx.x * blockDim.x + threadIdx.x;
    const T* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const T*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        const int index_m    = i / (splited_n * k);
        const int index_n    = (i % (splited_n * k)) / k;
        const int index_k    = (i % (splited_n * k)) % k;
        const int load_index = index_m * (n * k) + (rank * splited_n + index_n) * k + index_k;
        opus::fp32_t rslt_reg = 0.0f;
#pragma unroll
        for(int j = 0; j < ngpus; ++j)
            rslt_reg += upcastS(ptrs[j][load_index]);
        result[i] = downcastS<T>(rslt_reg);
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
