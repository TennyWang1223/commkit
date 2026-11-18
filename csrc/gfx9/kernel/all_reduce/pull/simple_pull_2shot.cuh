#pragma once
// all_reduce, simple proto, pull, two-shot (aiter cross_device_reduce_2stage).
//
// reduce-scatter: per-peer thread groups (512 / ngpus threads each) pull pack
// idx of chunk `rank` from every rank into LDS, group 0 sums in rank order
// into this rank's tmp. all-gather: group g pulls chunk (rank + g) % ngpus
// from its owner's tmp. Needs equal chunks (size % ngpus == 0); HAS_TAIL
// handles a chunk that is not whole 512 / ngpus-thread tiles.
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus, bool HAS_TAIL>
__global__ void __launch_bounds__(kSimpleThreads, 1) arTwoShotSimplePull(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = kSimpleThreads / ngpus;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int warp_id       = threadIdx.x / tnum_gpu;
    const int lane_id       = threadIdx.x % tnum_gpu;
    const int tid           = blockIdx.x * tnum_gpu + lane_id;
    const int stride        = gridDim.x * tnum_gpu;
    const int part          = size / ngpus;
    const int start         = rank * part;
    const int end           = rank == ngpus - 1 ? size : start + part;
    const int largest_part  = part + size % ngpus;
    __shared__ T tmp_smem[tnum_gpu * ngpus * pack_size];
    const P* ptrs[ngpus];
    P* tmps[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        const int target = (rank + i) % ngpus;
        // the sum order does not depend on the chunk owner
        ptrs[i] = (const P*)dp.ptrs[i];
        tmps[i] = getTmpBuf<P>(sg.ptrs[target]);
    }
    auto tmp_out = tmps[0];
    startSync<ngpus>(sg, self_sg, rank);

    // stage 1: reduce-scatter
    int loop_end = end;
    if constexpr(HAS_TAIL)
        loop_end -= (end - start) % tnum_gpu;
    int idx = start + tid;
    for(; idx < loop_end; idx += stride)
    {
        *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][idx];
        __syncthreads();
        if(warp_id == 0)
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
            tmp_out[idx - start] = write_reg;
        }
        __syncthreads();
    }
    if constexpr(HAS_TAIL)
    {
        // the remaining packs, by their owner threads, without LDS
        if(warp_id == 0 && idx < end)
            tmp_out[idx - start] = packedReduce<P, ngpus, A>(ptrs, idx);
    }
    endSync<ngpus>(sg, self_sg, rank);

    // stage 2: all-gather. Thread i gathers start + i, the pack it reduced in
    // stage 1: cross-device visibility only holds between equal tids.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
        const int dst_idx      = (warp_id + rank) % ngpus * part + idx;
        ((P*)result)[dst_idx] = tmps[warp_id][idx];
    }
}

} // namespace commkit::gfx9
