#pragma once
// gfx9 RMSNorm epilogues of the fused all-reduce + residual + RMSNorm kernels.
//
// Every kernel rounds the all-reduce result to T, adds the residual in fp32
// (residual_out is that sum rounded), and normalizes the fp32 sum:
//   out = acc * rsqrt(sum(acc^2) / hidden + eps) * w,  w = weight (+1 gemma)
// They differ in how the row's sum of squares is reduced, which decides the
// last bit of out:
//   rmsnormBlockReduce   32-lane groups, then a butterfly over the groups
//                        (allreduce_fusion_kernel_1stage / 2stage)
//   smemReduceSum        LDS tree (local_device_load_rmsnorm)
#include "commkit/common.cuh"
#include "gfx9/proto/lamport.cuh"

namespace commkit::gfx9 {

// Block reduce in 32-lane groups: warpReduce over 32 lanes, the groups'
// partials meet in LDS, then a butterfly over their count rounded up to a
// power of two (zero padded). Every lane returns the result.
template <template <typename> class Functor, typename T, int WARP_SIZE = 32>
DINLINE T rmsnormBlockReduce(T val, int block_size)
{
    static __shared__ T shared[32]; // max 1024 / 32
    const int tid       = threadIdx.x;
    const int w_tid     = tid % WARP_SIZE;
    const int wid       = tid / WARP_SIZE;
    const int num_warps = block_size / WARP_SIZE;
    int reduce_width    = 1;
    while(reduce_width < num_warps)
        reduce_width <<= 1;
    val = warpReduce<Functor, T, WARP_SIZE>(val);
    if(w_tid == 0)
        shared[wid] = val;
    __syncthreads();
    val = (w_tid < num_warps) ? shared[w_tid] : T(0);
    __syncthreads();
    val = warpReduceRuntime<Functor, T>(val, reduce_width);
    return val;
}

// out = in * rsqrt(sum(in^2) / hidden + eps) * w over the block's row
template <typename P, typename A, typename T, int PACK_SIZE, bool GEMMA_NORM>
DINLINE void rmsnormApply(P& out, const A& in, const P& weight, float eps, int hidden_dim, int block_size)
{
    __shared__ float s_val;
    float acc = 0.f;
#pragma unroll
    for(int i = 0; i < PACK_SIZE; ++i)
    {
        float v = upcastS(in[i]);
        acc += v * v;
    }
    acc = rmsnormBlockReduce<AddFunctor, float, 32>(acc, block_size);
    if(threadIdx.x == 0)
        s_val = rsqrtf(acc / hidden_dim + eps);
    __syncthreads();
#pragma unroll
    for(int i = 0; i < PACK_SIZE; ++i)
    {
        float w = upcastS(weight[i]);
        if constexpr(GEMMA_NORM)
            w += 1.0f;
        out[i] = downcastS<T>(pinFloat(in[i] * s_val * w));
    }
}

// Normalizes the block's row and stores this thread's pack (all threads of
// the block take part in the reduction, `active` ones store).
template <typename P, typename A, typename T, int PACK_SIZE, bool GEMMA_NORM>
DINLINE void rmsnormEpilogue(
    const A& in, const P& weight, int hidden_dim, float eps, int idx, int block_size, T* __restrict__ output, bool active)
{
    P out;
    rmsnormApply<P, A, T, PACK_SIZE, GEMMA_NORM>(out, in, weight, eps, hidden_dim, block_size);
    if(active)
        *reinterpret_cast<P*>(output + idx) = out;
}

// LDS tree sum of smem_addr[0, reduce_range) into smem_addr[0] (wave64: the
// last 64 values fold inside one wave without barriers)
template <int reduce_range>
DINLINE void smemReduceSum(float* smem_addr)
{
#pragma unroll
    for(int stride = reduce_range / 2; stride > 32; stride >>= 1)
    {
        if(threadIdx.x < stride)
            smem_addr[threadIdx.x] += smem_addr[threadIdx.x + stride];
        __syncthreads();
    }
    volatile float* v_smem = &smem_addr[0];
    if(threadIdx.x < 32)
    {
        v_smem[threadIdx.x] += v_smem[threadIdx.x + 32];
        v_smem[threadIdx.x] += v_smem[threadIdx.x + 16];
        v_smem[threadIdx.x] += v_smem[threadIdx.x + 8];
        v_smem[threadIdx.x] += v_smem[threadIdx.x + 4];
        v_smem[threadIdx.x] += v_smem[threadIdx.x + 2];
        v_smem[threadIdx.x] += v_smem[threadIdx.x + 1];
    }
    __syncthreads();
}

// ---------------------------------------------------------------------------
// lamport fused kernels: the 1-stage epilogue step by step, so out and
// residual_out match allreduce_fusion_kernel_1stage bit for bit
// ---------------------------------------------------------------------------
// Butterfly width over a row's partials: the next power of two, as
// rmsnormBlockReduce pads its warps.
DINLINE int lamportRmsWidth(int row_partials)
{
    int width = 1;
    while(width < row_partials)
        width <<= 1;
    return width;
}

// Row sum of squares: lane l holds partial l % width of the row (zero past
// it), folded by the butterfly of rmsnormBlockReduce. Every
// width-lane segment folds the same values the same way, so every lane gets
// the bits lane 0 of the 1-stage kernel gets.
DINLINE float lamportRmsFold(float v, int width)
{
    return warpReduceRuntime<AddFunctor, float>(v, width);
}

// The 1-stage residual step on a rank-order sum: acc becomes the fp32
// residual_out, res_out its rounding; returns the pack's sum of squares.
template <typename T, typename P, typename A>
DINLINE float lamportRmsResidual(A& acc, const P& res, P& res_out)
{
    constexpr int pack_size = 16 / sizeof(T);
    float square_sum        = 0.f;
#pragma unroll
    for(int j = 0; j < pack_size; ++j)
    {
        acc[j]     = upcastS(downcastS<T>(acc[j])) + upcastS(res[j]);
        res_out[j] = downcastS<T>(acc[j]);
    }
    // The fma chain the 1-stage kernel's `acc = 0; acc += v * v` compiles to
    // with ROCm 7.0 on gfx942 and gfx950: v_mul for element 1, v_fmac for
    // element 0 onto it, then elements 2.. in order. HIP contracts with
    // -ffp-contract=fast, so the order is the backend's choice: it folds the
    // first fmul of fadd(fmul, fmul) into an fma. Spelled out here: left to
    // itself the compiler squares this code with v_pk_mul_f32 and adds apart,
    // and either other order rounds differently, which now and then moves an
    // output by one bf16 ulp.
    square_sum = acc[1] * acc[1];
    square_sum = __builtin_fmaf(acc[0], acc[0], square_sum);
#pragma unroll
    for(int j = 2; j < pack_size; ++j)
        square_sum = __builtin_fmaf(acc[j], acc[j], square_sum);
    return square_sum;
}

// lamportRmsResidual, storing residual_out.
template <typename T, typename P, typename A>
DINLINE float lamportRmsAddResidual(A& acc, const P& res, P* residual_out_ptr)
{
    P res_out;
    const float square_sum = lamportRmsResidual<T>(acc, res, res_out);
    *residual_out_ptr      = res_out;
    return square_sum;
}

template <typename T, typename P, typename A>
DINLINE P lamportRmsNorm(const A& acc, const P& w, float rms, bool gemma_norm)
{
    constexpr int pack_size = 16 / sizeof(T);
    P out;
#pragma unroll
    for(int j = 0; j < pack_size; ++j)
    {
        float wj = upcastS(w[j]);
        if(gemma_norm)
            wj += 1.0f;
        out[j] = downcastS<T>(pinFloat(acc[j] * rms * wj));
    }
    return out;
}

} // namespace commkit::gfx9
