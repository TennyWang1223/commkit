#pragma once
// reduce_scatter, simple proto, pull, naive (aiter
// rs_gfx1250_split_{lastdim,middim}_naive): element by element, any shape whose
// scattered dim is a multiple of the world size. Rank r sums chunk r of every
// rank's staged input in rank order (fp32, rounded once), straight from the
// peers' memory.
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

// input (m, n) -> output (m, n / ngpus); n % ngpus == 0
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 1) rsSimplePullNaiveLastDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int m, int n)
{
    int size      = m * n / ngpus;
    int splited_n = n / ngpus;
    int index     = blockIdx.x * blockDim.x + threadIdx.x;
    const T* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        // Keep the sum order independent of the reduce-scatter owner.
        ptrs[i] = (const T*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        int index_x           = i % splited_n;
        int index_y           = i / splited_n;
        int load_index        = index_y * n + rank * splited_n + index_x;
        opus::fp32_t rslt_reg = 0.0f;
#pragma unroll
        for(int j = 0; j < ngpus; ++j)
            rslt_reg += upcastS(ptrs[j][load_index]);
        result[i] = downcastS<T>(rslt_reg);
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

// input (m, n, k) -> output (m, n / ngpus, k); n % ngpus == 0
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 1) rsSimplePullNaiveMidDim(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int m, int n, int k)
{
    int size      = m * n * k / ngpus;
    int splited_n = n / ngpus;
    int index     = blockIdx.x * blockDim.x + threadIdx.x;
    const T* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        // Keep the sum order independent of the reduce-scatter owner.
        ptrs[i] = (const T*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    for(int i = index; i < size; i += blockDim.x * gridDim.x)
    {
        int index_m           = i / (splited_n * k);
        int index_n           = (i % (splited_n * k)) / k;
        int index_k           = (i % (splited_n * k)) % k;
        int load_index        = index_m * (n * k) + (rank * splited_n + index_n) * k + index_k;
        opus::fp32_t rslt_reg = 0.0f;
#pragma unroll
        for(int j = 0; j < ngpus; ++j)
            rslt_reg += upcastS(ptrs[j][load_index]);
        result[i] = downcastS<T>(rslt_reg);
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
