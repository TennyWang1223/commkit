#pragma once
// all_reduce, simple proto, pull, one-shot (aiter ar_gfx1250_naive_unroll4).
// Every thread sums 4 packs a round over every rank's staged input, read in
// place from the peers' memory, in rank order (fp32, rounded once) and writes
// them; every rank reduces the whole message between a start and an end
// barrier.
#include "gfx1250/proto/simple.cuh"

namespace commkit::gfx1250 {

// size: 16-byte packs of the message
template <typename T, int ngpus>
__global__ void __launch_bounds__(256, 2) arOneShotSimplePull(
    RankData dp, RankSignals sg, Signal* self_sg, T* __restrict__ result, int rank, int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int unroll    = 4;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int tid                 = blockIdx.x * blockDim.x + threadIdx.x;
    int nthds               = blockDim.x * gridDim.x;
    const P* ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        // Sum in rank order so every rank gets the same bits.
        ptrs[i] = (const P*)dp.ptrs[i];
    }
    startSync<ngpus>(sg, self_sg, rank);
    int aligned_size = (size / unroll) * unroll;
    for(int base = tid * unroll; base < aligned_size; base += nthds * unroll)
    {
        P inp_reg[ngpus][unroll];
#pragma unroll
        for(int i = 0; i < ngpus; ++i)
        {
#pragma unroll
            for(int j = 0; j < unroll; ++j)
                inp_reg[i][j] = ptrs[i][base + j];
        }
        A rslt_tmp[unroll];
        P rslt_reg[unroll];
#pragma unroll
        for(int u = 0; u < unroll; ++u)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                rslt_tmp[u][j] = upcastS(inp_reg[0][u][j]);
#pragma unroll
            for(int g = 1; g < ngpus; ++g)
            {
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                    rslt_tmp[u][j] += upcastS(inp_reg[g][u][j]);
            }
        }
#pragma unroll
        for(int u = 0; u < unroll; ++u)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                rslt_reg[u][j] = downcastS<T>(rslt_tmp[u][j]);
            *(reinterpret_cast<P*>(result) + base + u) = rslt_reg[u];
        }
    }
    for(int idx = aligned_size + tid; idx < size; idx += nthds)
    {
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
        P out_val;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            out_val[j] = downcastS<T>(acc[j]);
        *(reinterpret_cast<P*>(result) + idx) = out_val;
    }
    endSync<ngpus, true>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
