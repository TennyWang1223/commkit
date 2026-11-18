#pragma once
// all_reduce + residual + RMSNorm, simple proto, pull, one-shot (aiter
// ar_rmsnorm_gfx1250, without quantization or padding).
#include "gfx1250/epilogue/rmsnorm.cuh"
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

/*
 * One block per row (grid-stride over the rows), one thread per 16-byte pack of
 * the row, the block a whole number of waves. Matches the unfused path: the
 * all-reduce result is rounded to T before the residual add, and ranks are
 * summed in rank order so every rank gets the same bits.
 *   TWO_STAGE = false  the one-shot: every thread sums its pack over every
 *                      rank's staged input, read in place, between a start and
 *                      an end barrier
 *   TWO_STAGE = true   the second launch of the two-shot (simple_pull_2shot):
 *                      the pack comes reduced from its owner's shard, the tmp
 *                      region of rank owner's Signal; the launches around it
 *                      synchronize, so dp is unused
 */
template <typename T, int ngpus, bool GEMMA_NORM, bool TWO_STAGE = false>
__global__ void __launch_bounds__(1024, 1) arRmsSimplePull(RankData dp,
                                                                      RankSignals sg,
                                                                      Signal* self_sg,
                                                                      int rank,
                                                                      const T* __restrict__ residual_inp,
                                                                      T* __restrict__ residual_out,
                                                                      T* __restrict__ output,
                                                                      const T* __restrict__ weight,
                                                                      int tokens,
                                                                      int hidden,
                                                                      float eps)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    const int packs         = hidden / pack_size;
    const bool active       = (int)threadIdx.x < packs;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        if constexpr(TWO_STAGE)
            ptrs[i] = getTmpBuf<const P>(sg.ptrs[i]);
        else
            ptrs[i] = reinterpret_cast<const P*>(dp.ptrs[i]);
    }
    P w{};
    if(active)
        w = reinterpret_cast<const P*>(weight)[threadIdx.x];

    if constexpr(!TWO_STAGE)
        startSync<ngpus>(sg, self_sg, rank);
    for(int t = blockIdx.x; t < tokens; t += gridDim.x)
    {
        const int idx      = t * packs + threadIdx.x;
        float x[pack_size] = {};
        float square_sum   = 0.f;
        if(active)
        {
            if constexpr(TWO_STAGE)
            {
                const int shard_packs = packs / ngpus;
                const int owner       = threadIdx.x / shard_packs;
                const int col         = threadIdx.x - owner * shard_packs;
                const P v             = ptrs[owner][t * shard_packs + col];
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                    x[j] = upcastS(v[j]);
            }
            else
            {
#pragma unroll
                for(int i = 0; i < ngpus; i++)
                {
                    const P v = ptrs[i][idx];
#pragma unroll
                    for(int j = 0; j < pack_size; j++)
                        x[j] += upcastS(v[j]);
                }
            }
            const P res = reinterpret_cast<const P*>(residual_inp)[idx];
            P sum;
            square_sum                              = rmsnormAddResidual<T>(x, res, sum);
            reinterpret_cast<P*>(residual_out)[idx] = sum;
        }
        const float inv_rms = rsqrtf(blockAllreduceF32(square_sum) / hidden + eps);
        if(active)
            reinterpret_cast<P*>(output)[idx] = rmsnormScale<T>(x, w, inv_rms, GEMMA_NORM);
    }
    if constexpr(!TWO_STAGE)
        endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
