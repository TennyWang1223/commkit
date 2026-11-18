#pragma once
// all_reduce, simple proto, pull, one-shot (aiter cross_device_reduce_1stage).
//
// The block splits into ngpus groups of 512 / ngpus threads; group g pulls
// rank g's packs into an LDS double buffer while group 0 sums the previous
// buffer in rank order and writes the result. Every rank reduces the whole
// message.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) arOneShotSimplePull(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    constexpr int tnum_gpu  = kSimpleThreads / ngpus;

    const int warp_id = threadIdx.x / tnum_gpu;
    const int lane_id = threadIdx.x % tnum_gpu;

    // double buffer, by source rank
    __shared__ P tmp_smem[2][tnum_gpu * ngpus];

    const int step  = gridDim.x * tnum_gpu;
    const int start = blockIdx.x * tnum_gpu + lane_id;

    startSync<ngpus>(sg, self_sg, rank);

    // uniform trip count, so every thread reaches every __syncthreads
    const int first = blockIdx.x * tnum_gpu;
    int iters       = 0;
    {
        int rem = size - first;
        iters   = rem > 0 ? (rem + step - 1) / step : 0;
    }

    int buf  = 0;
    int idx0 = start;
    if(warp_id < ngpus && idx0 < size)
        tmp_smem[buf][warp_id * tnum_gpu + lane_id] = ((const P**)&dp.ptrs[0])[warp_id][idx0];
    __syncthreads();

    for(int it = 0; it < iters; ++it)
    {
        const int cur_idx  = idx0 + it * step;
        const int next_idx = cur_idx + step;
        const int next_buf = buf ^ 1;

        // group 0 reduces the current buffer
        if(warp_id == 0 && cur_idx < size)
        {
            P v0 = tmp_smem[buf][lane_id];
            A acc;
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                acc[j] = upcastS(v0[j]);
#pragma unroll
            for(int g = 1; g < ngpus; ++g)
            {
                P vg = tmp_smem[buf][g * tnum_gpu + lane_id];
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                    acc[j] += upcastS(vg[j]);
            }
            P out;
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                out[j] = downcastS<T>(acc[j]);
            ((P*)result)[cur_idx] = out;
        }

        // every group prefetches the next buffer
        if(warp_id < ngpus && next_idx < size)
            tmp_smem[next_buf][warp_id * tnum_gpu + lane_id] =
                ((const P**)&dp.ptrs[0])[warp_id][next_idx];
        __syncthreads();
        buf = next_buf;
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
