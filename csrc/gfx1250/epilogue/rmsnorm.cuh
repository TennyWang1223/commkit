#pragma once
// gfx1250 RMSNorm epilogue of the fused all-reduce + residual + RMSNorm
// kernels (aiter ar_rmsnorm_gfx1250 / lamport_ar_rmsnorm_gfx1250).
//
// Every kernel rounds the rank-order fp32 all-reduce sum to T (as all-reduce
// followed by a separate add does), adds the residual in fp32 (residual_out
// is that sum rounded), and normalizes the fp32 sum:
//   out = x * (rsqrt(sum(x^2) / hidden + eps) * w),  w = weight (+1 gemma)
// The row's sum of squares is a wave32 butterfly per wave, then a serial sum of
// the wave partials in wave order (blockAllreduceF32, or the cluster fold of
// the lamport kernel), so every kernel gets the same bits.
#include "gfx1250/proto/arch.cuh"

namespace commkit::gfx1250 {

// Sum over the block; every thread gets the result. Threads past the row
// contribute 0, so the block may be wider than the row as long as it is a
// whole number of waves. (aiter block_allreduce_f32<false>; its max and
// parallel-wave forms served the FP8 quantization only.)
DINLINE float blockAllreduceF32(float v)
{
    __shared__ float partial[32];
    __shared__ float result;
    for(int off = warpSize / 2; off > 0; off >>= 1)
    {
        const float o = __shfl_xor(v, off);
        v             = v + o;
    }
    if(threadIdx.x % warpSize == 0)
        partial[threadIdx.x / warpSize] = v;
    __syncthreads();
    if(threadIdx.x == 0)
    {
        float r = partial[0];
        for(int w = 1; w < (int)(blockDim.x / warpSize); ++w)
            r = r + partial[w];
        result = r;
    }
    __syncthreads();
    return result;
}

// The residual step on a pack's rank-order fp32 sum x: round x to T, add the
// residual in fp32; sum is that rounded (residual_out). Returns the pack's sum
// of squares.
template <typename T, typename P, int N>
DINLINE float rmsnormAddResidual(float (&x)[N], const P& res, P& sum)
{
    float square_sum = 0.f;
#pragma unroll
    for(int j = 0; j < N; j++)
    {
        x[j]   = upcastS(downcastS<T>(x[j])) + upcastS(res[j]);
        sum[j] = downcastS<T>(x[j]);
        square_sum += x[j] * x[j];
    }
    return square_sum;
}

// x * (inv_rms * w) rounded to T, w = weight (+1 with gemma_norm). The
// product is pinned as fp32 first (pinFloat): otherwise the compiler may fuse
// the multiply and the conversion into one v_fma_mix (a single rounding,
// straight to fp16) in one kernel and not in another, and the kernels that
// must match bit for bit then differ by 1 ulp on near-ties.
template <typename T, typename P, int N>
DINLINE P rmsnormScale(const float (&x)[N], const P& w, float inv_rms, bool gemma_norm)
{
    P o;
#pragma unroll
    for(int j = 0; j < N; j++)
    {
        const float wj = upcastS(w[j]) + (gemma_norm ? 1.f : 0.f);
        o[j]           = downcastS<T>(pinFloat(x[j] * (inv_rms * wj)));
    }
    return o;
}

} // namespace commkit::gfx1250
