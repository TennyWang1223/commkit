#pragma once
// all_reduce, simple proto, push, two-shot (aiter
// cross_device_reduce_2stage_write_mode, without the registered-output
// broadcast). The input is only read locally:
//   stage 1  group g writes chunk g of this rank's input into slot `rank` of
//            rank g's tmp
//   stage 2  every rank sums its chunk from its tmp in rank order and writes
//            the sum into slot `rank` of every rank's second tmp half
//   stage 3  every rank copies the gathered sums from its tmp to the output
// Needs equal chunks (size % ngpus == 0).
//
// The second tmp half starts at a fixed offset (the capacity), not at `size`
// as in aiter: nothing orders stage 3 against the next call's stage 1, so
// with a size-dependent offset a peer's next, larger call overwrites sums
// this rank is still copying out.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) arTwoShotSimplePush(
    const T* __restrict__ input,
    RankSignals sg,
    Signal* self_sg,
    T* __restrict__ result,
    int rank,
    int size,
    int stage3_offset) // packs, at least the largest size
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = kSimpleThreads / ngpus;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    __shared__ T tmp_smem[tnum_gpu * ngpus * pack_size];
    __shared__ T res_smem[tnum_gpu * pack_size];
    const int warp_id = threadIdx.x / tnum_gpu;
    const int lane_id = threadIdx.x % tnum_gpu;
    const int tid     = blockIdx.x * tnum_gpu + lane_id;
    const int stride  = gridDim.x * tnum_gpu;
    const int part    = size / ngpus;
    P* tmps[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
        tmps[i] = getTmpBuf<P>(sg.ptrs[i]);
    const P* input_ptr      = reinterpret_cast<const P*>(input);
    auto tmp_out            = tmps[rank];

    // stage 1: write this rank's data to the remote ranks
    const int start = warp_id * part;
    int end         = warp_id == ngpus - 1 ? size : start + part;
    for(int idx = start + tid; idx < end; idx += stride)
        tmps[warp_id][rank * part + idx - start] = input_ptr[idx];
    endSync<ngpus>(sg, self_sg, rank);

    // stage 2: reduce this rank's chunk and write it to every rank
    end = rank != ngpus - 1 ? part : size - part * (ngpus - 1);
    // uniform trip count, so every thread reaches every __syncthreads
    const int loop_end = (end + stride - 1) / stride * stride;
    for(int idx = tid; idx < loop_end; idx += stride)
    {
        const bool active = idx < end;
        if(active)
            *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = tmp_out[warp_id * part + idx];
        __syncthreads();
        if(warp_id == 0 && active)
        {
            A add_reg;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
                add_reg[i] = upcastS(tmp_smem[pack_size * threadIdx.x + i]);
            constexpr int smem_gpu_loop_stride = tnum_gpu * pack_size;
#pragma unroll
            for(int i = 1; i < ngpus; ++i)
            {
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                    add_reg[j] += upcastS(tmp_smem[i * smem_gpu_loop_stride + pack_size * threadIdx.x + j]);
            }
            P write_reg;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
                write_reg[i] = downcastS<T>(add_reg[i]);
            *(reinterpret_cast<P*>(&res_smem[0]) + lane_id) = write_reg;
        }
        __syncthreads();
        if(!active)
            continue;
        tmps[warp_id][rank * part + idx + stage3_offset] = *(reinterpret_cast<P*>(&res_smem[0]) + lane_id);
    }
    endSync<ngpus>(sg, self_sg, rank);

    // stage 3: the output from this rank's tmp
    end = warp_id == ngpus - 1 ? size : start + part;
    for(int idx = start + tid; idx < end; idx += stride)
        ((P*)result)[idx] = tmp_out[idx + stage3_offset];
}

} // namespace commkit::gfx9
