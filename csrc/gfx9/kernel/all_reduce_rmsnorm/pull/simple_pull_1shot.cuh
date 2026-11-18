#pragma once
// all_reduce + residual + RMSNorm, simple proto, pull, one-shot (aiter
// allreduce_fusion_kernel_1stage, without quantization or padding).
// One block per row (hidden / pack_size threads, rounded up to 32): each
// thread sums its pack over every rank's input from the peers' memory,
// rounds, adds the residual, then the block normalizes the row.
#include "gfx9/epilogue/rmsnorm.cuh"
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus, bool GEMMA_NORM>
__global__ void __launch_bounds__(1024, 1) arRmsOneShotSimplePull(RankData dp,
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
    constexpr int pack_size      = 16 / sizeof(T);
    using P                      = typename opus::vector_t<T, pack_size>;
    using A                      = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int block_size         = hidden_dim / pack_size;
    const bool active            = (int)threadIdx.x < block_size;
    const int token_num          = size / hidden_dim;
    const int access_id_in_token = threadIdx.x * pack_size;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = (const P*)dp.ptrs[i];
    startSync<ngpus>(sg, self_sg, rank);
    for(int tidx = blockIdx.x; tidx < token_num; tidx += gridDim.x)
    {
        const int idx = tidx * hidden_dim + access_id_in_token;
        A acc{};
        P vec{};
        P weight_p{};
        if(active)
        {
            vec = ptrs[0][idx / pack_size];
#pragma unroll
            for(int v = 0; v < pack_size; ++v)
                acc[v] = upcastS(vec[v]);
#pragma unroll
            for(int r = 1; r < ngpus; ++r)
            {
                vec = ptrs[r][idx / pack_size];
#pragma unroll
                for(int v = 0; v < pack_size; ++v)
                    acc[v] += upcastS(vec[v]);
            }
            // round the all-reduce result to T before the residual add, as
            // all-reduce followed by a separate add does
#pragma unroll
            for(int v = 0; v < pack_size; ++v)
                acc[v] = upcastS(downcastS<T>(acc[v]));
            const P res = *reinterpret_cast<const P*>(residual_inp + idx);
#pragma unroll
            for(int v = 0; v < pack_size; ++v)
                acc[v] += upcastS(res[v]);
#pragma unroll
            for(int v = 0; v < pack_size; ++v)
                vec[v] = downcastS<T>(acc[v]);
            *reinterpret_cast<P*>(residual_out + idx) = vec;
            weight_p = *reinterpret_cast<const P*>(weight + access_id_in_token);
        }
        // padding threads join the reduction with zeros but store nothing
        rmsnormEpilogue<P, A, T, pack_size, GEMMA_NORM>(
            acc, weight_p, hidden_dim, eps, idx, (int)blockDim.x, output, active);
    }
    // nobody reuses the input or this block's flags before every rank is done
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx9
