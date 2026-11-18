#pragma once
// all_reduce + residual + RMSNorm, simple proto, pull, two-shot, one kernel
// (aiter allreduce_fusion_kernel_2stage, without quantization).
// One block per row (hidden / pack_size threads in ngpus groups):
//   stage 1  group g pulls rank g's slice `rank` of the row into LDS, group 0
//            sums it in rank order, every group pushes the sum into rank g's
//            tmp
//   stage 2  after the barrier the row is complete in this rank's tmp: add
//            the residual and normalize
// hidden / pack_size must be a multiple of ngpus and of 32, at most 1024.
#include "gfx9/epilogue/rmsnorm.cuh"
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus, bool GEMMA_NORM>
__global__ void __launch_bounds__(1024, 1) arRmsTwoShotSimplePull(RankData dp,
                                                                           RankSignals sg,
                                                                           Signal* self_sg,
                                                                           int rank,
                                                                           const T* __restrict__ residual_inp,
                                                                           T* __restrict__ residual_out,
                                                                           T* __restrict__ output,
                                                                           const T* __restrict__ weight,
                                                                           int size,
                                                                           int hidden_dim,
                                                                           float eps)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int block_size    = hidden_dim / pack_size;
    const int tnum_gpu      = block_size / ngpus;
    extern __shared__ char smem_buf[];
    P* tmp_smem       = reinterpret_cast<P*>(smem_buf);
    const int warp_id = threadIdx.x / tnum_gpu;
    const int lane_id = threadIdx.x % tnum_gpu;
    const P* ptrs[ngpus];
    P* tmps[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        ptrs[i] = (const P*)dp.ptrs[i];
        tmps[i] = getTmpBuf<P>(sg.ptrs[i]);
    }
    A acc;
    startSync<ngpus>(sg, self_sg, rank);

    for(int idx = ((blockIdx.x * ngpus + rank) * tnum_gpu + lane_id) * pack_size; idx < size;
        idx += gridDim.x * ngpus * tnum_gpu * pack_size)
    {
        P vec                 = ptrs[warp_id][idx / pack_size];
        tmp_smem[threadIdx.x] = vec;
        __syncthreads();
        if(warp_id == 0)
        {
#pragma unroll
            for(int v = 0; v < pack_size; ++v)
                acc[v] = upcastS(vec[v]);
#pragma unroll
            for(int r = 1; r < ngpus; ++r)
            {
                vec = tmp_smem[r * tnum_gpu + lane_id];
#pragma unroll
                for(int v = 0; v < pack_size; ++v)
                    acc[v] += upcastS(vec[v]);
            }
#pragma unroll
            for(int v = 0; v < pack_size; ++v)
                vec[v] = downcastS<T>(acc[v]);
            tmp_smem[lane_id] = vec;
        }
        __syncthreads();
        vec                            = tmp_smem[lane_id];
        tmps[warp_id][idx / pack_size] = vec;
    }

    const int access_id_in_token = threadIdx.x * pack_size;
    const P weight_p             = *reinterpret_cast<const P*>(weight + access_id_in_token);
    endSync<ngpus>(sg, self_sg, rank);
    for(int idx = blockIdx.x * hidden_dim + access_id_in_token; idx < size; idx += gridDim.x * hidden_dim)
    {
        P vec = tmps[rank][idx / pack_size];
        // the residual add and the norm in fp32, as the one-shot kernel does;
        // only residual_out is rounded to T
#pragma unroll
        for(int v = 0; v < pack_size; ++v)
            acc[v] = upcastS(vec[v]);
        const P res = *reinterpret_cast<const P*>(residual_inp + idx);
#pragma unroll
        for(int v = 0; v < pack_size; ++v)
            acc[v] += upcastS(res[v]);
#pragma unroll
        for(int v = 0; v < pack_size; ++v)
            vec[v] = downcastS<T>(acc[v]);
        *reinterpret_cast<P*>(residual_out + idx) = vec;
        rmsnormEpilogue<P, A, T, pack_size, GEMMA_NORM>(acc, weight_p, hidden_dim, eps, idx, block_size, output, true);
    }
}

} // namespace commkit::gfx9
