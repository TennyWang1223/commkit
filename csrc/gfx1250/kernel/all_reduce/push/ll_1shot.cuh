#pragma once
// all_reduce, LL proto, push, one-shot (aiter ar_ll_gfx1250).
#include "gfx1250/proto/ll.cuh"

namespace commkit::gfx1250 {

/*
 * Block = 2 x width threads: the first width send, the other width poll. A
 * sender takes U packets a round: all their loads, then their lines to
 * slot[rank] of every rank's FIFO, this rank's own first. The poller of
 * packet i polls all ngpus slots of this rank's FIFO in one batch, the own
 * slot included, and sums them. It takes the local value from the own line,
 * not from sendbuff: that line exists only once the sender has loaded the
 * packet, so with recvbuff == sendbuff no poller can overwrite a packet
 * before it is sent.
 *
 * peer_fifo comes last: the scalar arguments before it stay preloaded into
 * SGPRs (preloading stops at the first aggregate).
 */
template <typename T, int ngpus, int U>
__global__ void __launch_bounds__(1024, 1) arOneShotLL(T* __restrict__ recvbuff,
                                                                const T* __restrict__ sendbuff,
                                                                size_t n_pk, // 8-byte packets = bytes / 8
                                                                int rank,
                                                                uint32_t* __restrict__ block_epochs, // [kMaxBlocks]
                                                                RankData peer_fifo)
{
    constexpr int payload_size = 8 / sizeof(T); // elements per 8-byte payload
    using PL                   = typename opus::vector_t<T, payload_size>;
    constexpr size_t slot      = kLLPackCapacity;

    __shared__ uint32_t s_flag;
    if(threadIdx.x == 0)
        s_flag = llNextEpoch(block_epochs[blockIdx.x]);
    __syncthreads();
    const uint32_t flag = s_flag;

    LLLine* base[ngpus]; // base[k]: this call's bank of rank (rank + k) % ngpus
#pragma unroll
    for(int k = 0; k < ngpus; ++k)
        base[k] = reinterpret_cast<LLLine*>(const_cast<void*>(peer_fifo.ptrs[(rank + k) % ngpus])) +
                  (size_t)(flag & 1u) * ngpus * slot;

    const size_t width  = blockDim.x / 2;
    const size_t first  = (size_t)blockIdx.x * width + threadIdx.x % width;
    const size_t stride = (size_t)gridDim.x * width;

    if(threadIdx.x < width)
    {
        const uint2* in = reinterpret_cast<const uint2*>(sendbuff);
        for(size_t b = first; b < n_pk; b += stride * U)
        {
            uint2 d[U];
#pragma unroll
            for(int u = 0; u < U; ++u)
                if(b + u * stride < n_pk)
                    d[u] = in[b + u * stride];
#pragma unroll
            for(int k = 0; k < ngpus; ++k)
#pragma unroll
                for(int u = 0; u < U; ++u)
                    if(b + u * stride < n_pk)
                        llStoreB128(reinterpret_cast<uint32_t*>(base[k] + (size_t)rank * slot + b + u * stride),
                                    d[u].x,
                                    flag,
                                    d[u].y,
                                    flag);
        }
    }
    else
    {
        PL* out = reinterpret_cast<PL*>(recvbuff);
        for(size_t i = first; i < n_pk; i += stride)
        {
            uint32_t w[ngpus][4];
            uint32_t pending = (1u << ngpus) - 1u;
            while(pending)
            {
#pragma unroll
                for(int r = 0; r < ngpus; ++r)
                    if(pending & (1u << r))
                        llLoadB128(reinterpret_cast<const uint32_t*>(base[0] + (size_t)r * slot + i),
                                   w[r][0],
                                   w[r][1],
                                   w[r][2],
                                   w[r][3]);
#pragma unroll
                for(int r = 0; r < ngpus; ++r)
                    if((pending & (1u << r)) && w[r][1] == flag && w[r][3] == flag)
                        pending &= ~(1u << r);
            }
            opus::fp32_t acc[payload_size];
#pragma unroll
            for(int r = 0; r < ngpus; ++r)
            {
                const uint32_t pw[2] = {w[r][0], w[r][2]};
                const PL pv          = *reinterpret_cast<const PL*>(pw);
#pragma unroll
                for(int q = 0; q < payload_size; ++q)
                    acc[q] = r == 0 ? upcastS(pv[q]) : acc[q] + upcastS(pv[q]);
            }
            PL ov;
#pragma unroll
            for(int q = 0; q < payload_size; ++q)
                ov[q] = downcastS<T>(acc[q]);
            out[i] = ov;
        }
    }

    llPublishEpoch(block_epochs, flag);
}

} // namespace commkit::gfx1250
