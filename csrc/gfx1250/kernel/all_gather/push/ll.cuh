#pragma once
// all_gather, LL proto, push (aiter ag_ll_gfx1250).
#include "gfx1250/proto/ll.cuh"

namespace commkit::gfx1250 {

/*
 * Every rank pushes its input into each peer's FIFO as 16-byte lines, then
 * polls its own FIFO for the peers' lines and writes each to its place in the
 * output. A line is one llStoreB128 and is read with one llLoadB128, so a
 * single flag guards all of it: words 0-2 carry 12 bytes of payload and word 3
 * the epoch, where the all-reduce's lines carry 8 bytes and two flags. A rank
 * sends 1.33 x (ngpus - 1) x its input instead of 2 x.
 *
 * Word w of rank r, in row y = w / row32, lands at output word
 * (y * ngpus + r) * row32 + w % row32: row32 = n32 gathers along dim 0, the
 * last dim's words along the last dim. A thread takes U units of 12 bytes a
 * round: all their loads, then their (ngpus - 1) x U remote stores back to
 * back, then its own copies (on gfx1250 a load issued after a remote store
 * waits for that store's round trip), and its units' polls go out in one
 * batch. ALIGNED: input and output 4-byte aligned; otherwise their words move
 * byte by byte (same lines).
 *
 * The input is read while the output is written: it must lie clear of the
 * output, or be this rank's own slice of a dim-0 gather (rewritten with the
 * same bytes).
 *
 * peer_fifo comes last: the scalar arguments before it stay preloaded into
 * SGPRs (preloading stops at the first aggregate).
 */
template <int ngpus, int U, bool ALIGNED>
__global__ void __launch_bounds__(512, 1) agLL(uint8_t* __restrict__ result,
                                                          const uint8_t* __restrict__ sendbuff,
                                                          uint32_t n32,   // 4-byte words a rank sends
                                                          uint32_t row32, // 4-byte words of a gathered row
                                                          int rank,
                                                          uint32_t* __restrict__ block_epochs, // [kMaxBlocks]
                                                          RankData peer_fifo)
{
    constexpr size_t slot = kLLPackCapacity;

    __shared__ uint32_t s_flag;
    if(threadIdx.x == 0)
        s_flag = llNextEpoch(block_epochs[blockIdx.x]);
    __syncthreads();
    const uint32_t flag        = s_flag;
    const size_t bank_off_pkts = (size_t)(flag & 1u) * (size_t)ngpus * slot;

    const uint32_t n_units = (n32 + 2) / 3; // 12-byte units; the last may carry 4 or 8 bytes
    const uint32_t gtid    = blockIdx.x * blockDim.x + threadIdx.x;
    const uint32_t stride  = gridDim.x * blockDim.x;
    const auto load = [&](uint32_t w) {
        uint32_t d = 0u;
        if(w < n32)
        {
            if constexpr(ALIGNED)
                d = reinterpret_cast<const uint32_t*>(sendbuff)[w];
            else
                __builtin_memcpy(&d, sendbuff + (size_t)w * 4, 4);
        }
        return d;
    };
    // unit i of rank r: its words 3i..3i+2 go to row w / row32 of rank r in
    // the gathered tensor, which holds every rank's rows in rank order
    const auto storeUnit = [&](int r, uint32_t i, uint32_t a0, uint32_t a1, uint32_t a2) {
        const uint32_t d[3] = {a0, a1, a2};
        const uint32_t w0   = 3 * i;
        uint32_t y          = w0 / row32;
        uint32_t c          = w0 - y * row32;
#pragma unroll
        for(int q = 0; q < 3; ++q)
        {
            if(w0 + q < n32)
            {
                const size_t at = ((size_t)y * ngpus + r) * row32 + c;
                if constexpr(ALIGNED)
                    reinterpret_cast<uint32_t*>(result)[at] = d[q];
                else
                    __builtin_memcpy(result + at * 4, &d[q], 4);
            }
            if(++c == row32)
            {
                c = 0;
                ++y;
            }
        }
    };

    for(uint32_t base = gtid; base < n_units; base += stride * U)
    {
        uint32_t d[U][3];
#pragma unroll
        for(int u = 0; u < U; ++u)
        {
            const uint32_t i = base + u * stride;
#pragma unroll
            for(int q = 0; q < 3; ++q)
                d[u][q] = i < n_units ? load(3 * i + q) : 0u;
        }
#pragma unroll
        for(int k = 1; k < ngpus; ++k)
        {
            LLLine* dst = reinterpret_cast<LLLine*>(const_cast<void*>(peer_fifo.ptrs[(rank + k) % ngpus])) +
                          bank_off_pkts + (size_t)rank * slot;
#pragma unroll
            for(int u = 0; u < U; ++u)
            {
                const uint32_t i = base + u * stride;
                if(i < n_units)
                    llStoreB128(reinterpret_cast<uint32_t*>(&dst[i]), d[u][0], d[u][1], d[u][2], flag);
            }
        }
#pragma unroll
        for(int u = 0; u < U; ++u)
        {
            const uint32_t i = base + u * stride;
            if(i < n_units)
                storeUnit(rank, i, d[u][0], d[u][1], d[u][2]);
        }
    }

    const LLLine* my_base = reinterpret_cast<const LLLine*>(peer_fifo.ptrs[rank]) + bank_off_pkts;
    for(uint32_t base = gtid; base < n_units; base += stride * U)
    {
        // bit u * ngpus + k: unit u's line from rank (rank + k) % ngpus
        uint32_t pending = 0;
#pragma unroll
        for(int u = 0; u < U; ++u)
            if(base + u * stride < n_units)
                pending |= (((1u << ngpus) - 1u) & ~1u) << (u * ngpus);
        while(pending)
        {
            uint32_t line[U][ngpus][4];
#pragma unroll
            for(int u = 0; u < U; ++u)
#pragma unroll
                for(int k = 1; k < ngpus; ++k)
                    if(pending & (1u << (u * ngpus + k)))
                        llLoadB128(reinterpret_cast<const uint32_t*>(
                                       &my_base[(size_t)((rank + k) % ngpus) * slot + base + u * stride]),
                                   line[u][k][0],
                                   line[u][k][1],
                                   line[u][k][2],
                                   line[u][k][3]);
#pragma unroll
            for(int u = 0; u < U; ++u)
#pragma unroll
                for(int k = 1; k < ngpus; ++k)
                    if((pending & (1u << (u * ngpus + k))) && line[u][k][3] == flag)
                    {
                        storeUnit((rank + k) % ngpus, base + u * stride, line[u][k][0], line[u][k][1], line[u][k][2]);
                        pending &= ~(1u << (u * ngpus + k));
                    }
        }
    }

    llPublishEpoch(block_epochs, flag);
}

} // namespace commkit::gfx1250
