#pragma once
// all_reduce + residual + RMSNorm, simple proto, pull, two-shot (aiter
// ar_rmsnorm_reduce_scatter_gfx1250 + ar_rmsnorm_gfx1250<TWO_STAGE>, without
// quantization or padding). One launch sequence:
//   startSyncKernel   every rank's input is staged
//   reduce            each rank owns one contiguous shard of every row (hidden
//                     / ngpus packs), reduces it in rank order straight from
//                     the peers' inputs and writes it to its tmp region
//   endSyncKernel     every shard is written (release / acquire)
//   norm              arRmsSimplePull<TWO_STAGE = true>: every rank
//                     reads each pack of a row from its owner's shard, adds the
//                     residual and normalizes the row
//   endSyncKernel     nobody rewrites its shard or its input before every rank
//                     is done reading them
// At TP4+ it halves or better the peer traffic of the one-shot, for three
// single-block barriers.
#include "gfx1250/kernel/all_reduce_rmsnorm/pull/simple_pull_1shot.cuh"

namespace commkit::gfx1250 {

// packs: 16-byte packs of a row, a multiple of ngpus; the tmp region holds
// tokens x packs / ngpus packs
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) arRmsTwoShotSimplePullReduce(
    RankData dp, Signal* self_sg, int rank, int tokens, int packs)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    const int shard_packs   = packs / ngpus;
    const int shard_size    = tokens * shard_packs;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
        ptrs[i] = reinterpret_cast<const P*>(dp.ptrs[i]);
    P* scratch = getTmpBuf<P>(self_sg);

    const int tid    = blockIdx.x * blockDim.x + threadIdx.x;
    const int stride = gridDim.x * blockDim.x;
    for(int out_idx = tid; out_idx < shard_size; out_idx += stride)
    {
        const int token = out_idx / shard_packs;
        const int col   = out_idx - token * shard_packs;
        const int idx   = token * packs + rank * shard_packs + col;
        A acc;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            acc[j] = upcastS(ptrs[0][idx][j]);
#pragma unroll
        for(int i = 1; i < ngpus; ++i)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                acc[j] += upcastS(ptrs[i][idx][j]);
        }
        P reduced;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            reduced[j] = downcastS<T>(acc[j]);
        scratch[out_idx] = reduced;
    }
}

} // namespace commkit::gfx1250
