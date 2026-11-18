#pragma once
// all_reduce + residual + RMSNorm, simple proto, pull, two-shot as two
// launches (aiter reduce_scatter_cross_device_store + local_device_load_rmsnorm):
//   reduce  per-peer thread groups pull chunk `rank` of the flattened input
//           into LDS, group 0 sums it in rank order, every group pushes the
//           sum into rank g's tmp
//   norm    after the kernel boundary every rank holds the whole all-reduce
//           result in its tmp: add the residual, normalize each row (LDS
//           tree reduction of the sum of squares)
#include "gfx9/epilogue/rmsnorm.cuh"
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) arRmsTwoShotSimplePullSplitReduce(
    RankData dp, RankSignals sg, Signal* self_sg, int rank, int m, int hidden_dim)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = kSimpleThreads / ngpus;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    __shared__ T tmp_smem[tnum_gpu * ngpus * pack_size];
    const int warp_id    = threadIdx.x / tnum_gpu;
    const int lane_id    = threadIdx.x % tnum_gpu;
    const int tid        = blockIdx.x * tnum_gpu + lane_id;
    const int pack_count = hidden_dim / pack_size;
    const P* ptrs[ngpus];
    P* tmps[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        ptrs[i] = (const P*)dp.ptrs[i];
        tmps[i] = getTmpBuf<P>(sg.ptrs[i]);
    }
    startSync<ngpus>(sg, self_sg, rank);

    const int part = m * pack_count / ngpus;
    // uniform trip count, so every thread reaches every __syncthreads
    const int stride   = gridDim.x * tnum_gpu;
    const int loop_end = (part + stride - 1) / stride * stride;
    for(int idx = tid; idx < loop_end; idx += stride)
    {
        const bool active = idx < part;
        if(active)
            *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][rank * part + idx];
        __syncthreads();
        if(warp_id == 0 && active)
        {
            A add_reg;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
                add_reg[i] = upcastS(tmp_smem[pack_size * threadIdx.x + i]);
#pragma unroll
            for(int i = 1; i < ngpus; ++i)
            {
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                    add_reg[j] += upcastS(tmp_smem[i * pack_size * tnum_gpu + pack_size * threadIdx.x + j]);
            }
            P add_rslt;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
                add_rslt[i] = downcastS<T>(add_reg[i]);
            *(reinterpret_cast<P*>(&tmp_smem[0]) + lane_id) = add_rslt;
        }
        __syncthreads();
        if(!active)
            continue;
        tmps[warp_id][rank * part + idx] = *(reinterpret_cast<P*>(&tmp_smem[0]) + lane_id);
    }
    // Not a final barrier: the norm launch reads the tmp the peers wrote
    // here, which the release / acquire of this barrier makes visible.
    // RELAXED corrupts the output above ~1.2 MB per rank (seen in sglang).
    endSync<ngpus, false>(sg, self_sg, rank);
}

// hidden / pack_size == tnum * n_loop exactly: no bounds checks
template <typename T, int tnum, int n_loop, bool GEMMA_NORM>
__global__ void __launch_bounds__(tnum, 1) arRmsTwoShotSimplePullSplitNormExact(Signal* self_sg,
                                                                                        const T* __restrict__ residual_inp,
                                                                                        T* __restrict__ residual_out,
                                                                                        T* __restrict__ results,
                                                                                        const T* __restrict__ weight,
                                                                                        float eps,
                                                                                        int m,
                                                                                        int n)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    __shared__ float smem[tnum];
    const P* tmps = getTmpBuf<P>(self_sg);

    for(int bid = blockIdx.x; bid < m; bid += gridDim.x)
    {
        float square_sum = 0.0f;
        A rms_inp_f32[n_loop];
        P w_arr[n_loop];
#pragma unroll
        for(int n_iter = 0; n_iter < n_loop; ++n_iter)
        {
            const int read_idx        = bid * n_loop * blockDim.x + n_iter * blockDim.x + threadIdx.x;
            const P reduce_out_pack   = tmps[read_idx];
            const P residual_inp_pack = *(reinterpret_cast<const P*>(residual_inp) + read_idx);
            w_arr[n_iter]             = *(reinterpret_cast<const P*>(weight) + n_iter * blockDim.x + threadIdx.x);
            A reduce_pack;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
            {
                const float rms_inp    = upcastS(reduce_out_pack[i]) + upcastS(residual_inp_pack[i]);
                rms_inp_f32[n_iter][i] = rms_inp;
                reduce_pack[i]         = rms_inp * rms_inp;
            }
            square_sum += packReduce<AddFunctor, float, pack_size>(reduce_pack);
        }
        smem[threadIdx.x] = square_sum;
        __syncthreads();
        smemReduceSum<tnum>(&smem[0]);
        square_sum        = smem[0];
        const float denom = rsqrtf(square_sum / n + eps);
#pragma unroll
        for(int n_iter = 0; n_iter < n_loop; ++n_iter)
        {
            P rmsnorm_rslt;
            P rmsnorm_inp;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
            {
                const float x_f32 = rms_inp_f32[n_iter][i];
                float w_f32       = upcastS(w_arr[n_iter][i]);
                if constexpr(GEMMA_NORM)
                    w_f32 += 1.0f;
                rmsnorm_inp[i]  = downcastS<T>(x_f32);
                rmsnorm_rslt[i] = downcastS<T>(x_f32 * w_f32 * denom);
            }
            const int write_idx = bid * n_loop * blockDim.x + n_iter * blockDim.x + threadIdx.x;
            *(reinterpret_cast<P*>(results) + write_idx)      = rmsnorm_rslt;
            *(reinterpret_cast<P*>(residual_out) + write_idx) = rmsnorm_inp;
        }
    }
}

// any hidden / pack_size <= tnum * n_loop: threads past the row idle
template <typename T, int tnum, int n_loop, bool GEMMA_NORM>
__global__ void __launch_bounds__(tnum, 1) arRmsTwoShotSimplePullSplitNorm(Signal* self_sg,
                                                                                   const T* __restrict__ residual_inp,
                                                                                   T* __restrict__ residual_out,
                                                                                   T* __restrict__ results,
                                                                                   const T* __restrict__ weight,
                                                                                   float eps,
                                                                                   int m,
                                                                                   int n)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    __shared__ float smem[tnum];
    const P* tmps           = getTmpBuf<P>(self_sg);
    const int in_pack_count = n / pack_size;

    for(int bid = blockIdx.x; bid < m; bid += gridDim.x)
    {
        float square_sum = 0.0f;
        A rms_inp_f32[n_loop];
        P w_arr[n_loop];
#pragma unroll
        for(int n_iter = 0; n_iter < n_loop; ++n_iter)
        {
            if(n_iter * tnum + threadIdx.x < in_pack_count)
            {
                const int read_idx        = bid * in_pack_count + n_iter * tnum + threadIdx.x;
                const P reduce_out_pack   = tmps[read_idx];
                const P residual_inp_pack = *(reinterpret_cast<const P*>(residual_inp) + read_idx);
                w_arr[n_iter]             = *(reinterpret_cast<const P*>(weight) + n_iter * tnum + threadIdx.x);
                A reduce_pack;
#pragma unroll
                for(int i = 0; i < pack_size; ++i)
                {
                    const float rms_inp    = upcastS(reduce_out_pack[i]) + upcastS(residual_inp_pack[i]);
                    rms_inp_f32[n_iter][i] = rms_inp;
                    reduce_pack[i]         = rms_inp * rms_inp;
                }
                square_sum += packReduce<AddFunctor, float, pack_size>(reduce_pack);
            }
        }
        smem[threadIdx.x] = square_sum;
        __syncthreads();
        smemReduceSum<tnum>(&smem[0]);
        square_sum        = smem[0];
        const float denom = rsqrtf(square_sum / n + eps);
#pragma unroll
        for(int n_iter = 0; n_iter < n_loop; ++n_iter)
        {
            if(n_iter * tnum + threadIdx.x < in_pack_count)
            {
                P rmsnorm_rslt;
                P rmsnorm_inp;
#pragma unroll
                for(int i = 0; i < pack_size; ++i)
                {
                    const float x_f32 = rms_inp_f32[n_iter][i];
                    float w_f32       = upcastS(w_arr[n_iter][i]);
                    if constexpr(GEMMA_NORM)
                        w_f32 += 1.0f;
                    rmsnorm_inp[i]  = downcastS<T>(x_f32);
                    rmsnorm_rslt[i] = downcastS<T>(x_f32 * w_f32 * denom);
                }
                const int idx = bid * in_pack_count + n_iter * tnum + threadIdx.x;
                *(reinterpret_cast<P*>(results) + idx)      = rmsnorm_rslt;
                *(reinterpret_cast<P*>(residual_out) + idx) = rmsnorm_inp;
            }
        }
    }
}

} // namespace commkit::gfx9
