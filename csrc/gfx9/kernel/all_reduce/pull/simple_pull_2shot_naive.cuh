#pragma once
// all_reduce, simple proto, pull, two-shot, naive (aiter
// cross_device_reduce_2stage_naive): rank r sums chunk r of every rank's
// input into its tmp (reduce-scatter), then every rank pulls every chunk
// from the owners' tmp (all-gather).
#include "gfx9/proto/simple.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus>
__global__ void __launch_bounds__(kSimpleThreads, 1) arTwoShotSimplePullNaive(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int tid           = blockIdx.x * blockDim.x + threadIdx.x;
    const int stride        = gridDim.x * blockDim.x;
    const int part          = size / ngpus;
    const int start         = rank * part;
    const int end           = rank == ngpus - 1 ? size : start + part;
    const int largest_part  = part + size % ngpus;
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
    for(int idx = start + tid; idx < end; idx += stride)
        tmp_out[idx - start] = packedReduce<P, ngpus, A>(ptrs, idx);
    endSync<ngpus>(sg, self_sg, rank);

    // stage 2: all-gather. Thread i gathers start + i, the pack it reduced in
    // stage 1: cross-device visibility only holds between equal tids.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
#pragma unroll
        for(int i = 0; i < ngpus; i++)
        {
            const int gather_from_rank = (rank + i) % ngpus;
            if(gather_from_rank == ngpus - 1 || idx < part)
                ((P*)result)[gather_from_rank * part + idx] = tmps[i][idx];
        }
    }
}

} // namespace commkit::gfx9
