#pragma once
// all_reduce, LL proto, push, two-shot (aiter ar_2s_ll_gfx1250): a
// reduce-scatter and an all-gather over LL lines.
#include "gfx1250/proto/ll.cuh"

namespace commkit::gfx1250 {

/*
 * The message splits into ngpus chunks of chunk_pk 8-byte packets; rank c owns
 * chunk c. Each bank of this kernel's FIFO (bank = epoch parity) is a
 * reduce-scatter region, which holds rank s's lines in slot s, s * ar2sSrcLines
 * lines on, and an all-gather region, ar2sRegionPk lines on, laid out the same.
 * Every thread takes packet j of every chunk, in one of ROLES wave groups a
 * block:
 *   send:   send packet j of every other chunk c to rank c's reduce-scatter
 *           slot[rank]
 *   reduce: poll the ngpus - 1 contributions to packet j of the own chunk,
 *           reduce them with the own one in rank order, send the result to
 *           every peer's all-gather slot[rank] and write it to recvbuff (its
 *           polls come before its stores)
 *   gather: poll the other ranks' reduced packet j into recvbuff
 * ROLES = 3 runs them in three groups. ROLES = 2 runs gather in the send group,
 * after its stores: a reduced packet lands only after the stores it depends on,
 * about a round trip after they were sent, so waiting for them costs about
 * nothing, and a block of 2 x width threads covers more packets a CU.
 * Every rank moves 2 * (ngpus - 1) / ngpus * bytes of payload (the lines double
 * it) against (ngpus - 1) * bytes for the one-shot, for one more fabric
 * latency.
 * With recvbuff == sendbuff: reduce reads and writes only packet j of the own
 * chunk, in that order. gather writes packet j of chunk c only once rank c has
 * sent its reduction, which needs this rank's contribution, which send sent
 * after it loaded the packet; send reads no other packet of recvbuff.
 *
 * peer_fifo comes last: the scalar arguments before it stay preloaded into
 * SGPRs (preloading stops at the first aggregate).
 */
template <typename T, int ngpus, int ROLES>
__global__ void __launch_bounds__(1024) arTwoShotLL(T* __restrict__ recvbuff,
                                                             const T* __restrict__ sendbuff,
                                                             size_t chunk_pk, // packets a chunk = bytes / (8 * ngpus)
                                                             int rank,
                                                             uint32_t* __restrict__ block_epochs, // [kMaxBlocks]
                                                             RankData peer_fifo)
{
    static_assert(ROLES == 2 || ROLES == 3, "two or three wave groups");
    constexpr int payload_size = 8 / sizeof(T); // elements per 8-byte packet
    using PL                   = typename opus::vector_t<T, payload_size>;
    constexpr size_t region    = ar2sRegionPk(ngpus);
    constexpr size_t src       = ar2sSrcLines(ngpus);

    __shared__ uint32_t s_flag;
    if(threadIdx.x == 0)
        s_flag = llNextEpoch(block_epochs[blockIdx.x]);
    __syncthreads();
    const uint32_t flag = s_flag;

    LLLine* rs[ngpus]; // rs[k]: this call's reduce-scatter region of rank (rank + k) % ngpus
#pragma unroll
    for(int k = 0; k < ngpus; ++k)
        rs[k] = reinterpret_cast<LLLine*>(const_cast<void*>(peer_fifo.ptrs[(rank + k) % ngpus])) +
                (size_t)(flag & 1u) * 2 * region;

    const size_t width  = blockDim.x / ROLES;
    const size_t role   = threadIdx.x / width; // 0 send (+ gather at ROLES 2), 1 reduce, 2 gather
    const size_t first  = (size_t)blockIdx.x * width + threadIdx.x % width;
    const size_t stride = (size_t)gridDim.x * width;
    const uint2* in     = reinterpret_cast<const uint2*>(sendbuff);
    uint2* out          = reinterpret_cast<uint2*>(recvbuff);

    for(size_t j = first; j < chunk_pk; j += stride)
    {
        if(role == 0)
        {
            uint2 d[ngpus];
#pragma unroll
            for(int k = 1; k < ngpus; ++k)
                d[k] = in[(size_t)((rank + k) % ngpus) * chunk_pk + j];
#pragma unroll
            for(int k = 1; k < ngpus; ++k)
                llStoreB128(
                    reinterpret_cast<uint32_t*>(rs[k] + (size_t)rank * src + j), d[k].x, flag, d[k].y, flag);
        }
        if(role == 1)
        {
            const uint2 mine = in[(size_t)rank * chunk_pk + j];
            uint32_t w[ngpus][4];
            uint32_t pending = ((1u << ngpus) - 1u) & ~(1u << rank);
            while(pending)
            {
#pragma unroll
                for(int s = 0; s < ngpus; ++s)
                    if(pending & (1u << s))
                        llLoadB128(reinterpret_cast<const uint32_t*>(rs[0] + (size_t)s * src + j),
                                   w[s][0],
                                   w[s][1],
                                   w[s][2],
                                   w[s][3]);
#pragma unroll
                for(int s = 0; s < ngpus; ++s)
                    if((pending & (1u << s)) && w[s][1] == flag && w[s][3] == flag)
                        pending &= ~(1u << s);
            }
            opus::fp32_t acc[payload_size];
#pragma unroll
            for(int s = 0; s < ngpus; ++s)
            {
                const uint32_t pw[2] = {s == rank ? mine.x : w[s][0], s == rank ? mine.y : w[s][2]};
                const PL pv          = *reinterpret_cast<const PL*>(pw);
#pragma unroll
                for(int q = 0; q < payload_size; ++q)
                    acc[q] = s == 0 ? upcastS(pv[q]) : acc[q] + upcastS(pv[q]);
            }
            PL ov;
#pragma unroll
            for(int q = 0; q < payload_size; ++q)
                ov[q] = downcastS<T>(acc[q]);
            const uint2 r = *reinterpret_cast<const uint2*>(&ov);
#pragma unroll
            for(int k = 1; k < ngpus; ++k)
                llStoreB128(
                    reinterpret_cast<uint32_t*>(rs[k] + region + (size_t)rank * src + j), r.x, flag, r.y, flag);
            out[(size_t)rank * chunk_pk + j] = r;
        }
        if(role == (ROLES == 3 ? 2 : 0))
        {
            uint32_t g[ngpus][4];
            uint32_t pending = ((1u << ngpus) - 1u) & ~(1u << rank);
            while(pending)
            {
#pragma unroll
                for(int s = 0; s < ngpus; ++s)
                    if(pending & (1u << s))
                        llLoadB128(reinterpret_cast<const uint32_t*>(rs[0] + region + (size_t)s * src + j),
                                   g[s][0],
                                   g[s][1],
                                   g[s][2],
                                   g[s][3]);
#pragma unroll
                for(int s = 0; s < ngpus; ++s)
                    if((pending & (1u << s)) && g[s][1] == flag && g[s][3] == flag)
                        pending &= ~(1u << s);
            }
#pragma unroll
            for(int s = 0; s < ngpus; ++s)
                if(s != rank)
                    out[(size_t)s * chunk_pk + j] = make_uint2(g[s][0], g[s][2]);
        }
    }

    llPublishEpoch(block_epochs, flag);
}

} // namespace commkit::gfx1250
