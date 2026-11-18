#pragma once
// all_reduce, LL proto, push, one-shot (aiter ar_ll_gfx9).
//   publish  every rank writes its whole input, as LL lines carrying the
//            epoch, into slot `rank` of every peer's FIFO
//   reduce   every rank polls its own FIFO's slots until the lines of the
//            epoch arrived and sums them with its own input, in rank order
// No barrier: the per-block epoch tells this call's lines from older ones,
// and the double-buffered banks keep a fast rank off the slot a slow one is
// still reading.
#include "gfx9/proto/ll.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus, int BLOCK_SIZE>
__global__ void __launch_bounds__(BLOCK_SIZE) arOneShotLL(RankData peer_fifo,
                                                                   T* __restrict__ recvbuff,
                                                                   const T* __restrict__ sendbuff,
                                                                   size_t n_pk, // 8-byte payloads
                                                                   int rank,
                                                                   uint32_t* __restrict__ block_epochs,
                                                                   size_t slot_stride_pk)
{
    constexpr int payload_size = 8 / sizeof(T); // elements per 8-byte payload
    using PL                   = typename opus::vector_t<T, payload_size>;
    using AL                   = typename opus::vector_t<opus::fp32_t, payload_size>;
    const size_t slot          = slot_stride_pk;

    __shared__ uint32_t s_flag;
    if(threadIdx.x == 0)
        s_flag = llNextEpoch(block_epochs[blockIdx.x]);
    __syncthreads();
    const uint32_t flag         = s_flag;
    const size_t bank_off_pkts  = (size_t)(flag & 1u) * (size_t)ngpus * slot;
    const size_t gtid           = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    const size_t stride         = (size_t)gridDim.x * blockDim.x;
    const uint32_t* in          = reinterpret_cast<const uint32_t*>(sendbuff);

    // publish: this rank's payload into slot `rank` of every peer
    for(size_t pk = gtid; pk < n_pk; pk += stride)
    {
        const uint32_t d0 = in[2 * pk];
        const uint32_t d1 = in[2 * pk + 1];
#pragma unroll
        for(int r = 1; r < ngpus; ++r)
        {
            const int peer = (rank + r) % ngpus;
            LLLine* dst    = reinterpret_cast<LLLine*>(const_cast<void*>(peer_fifo.ptrs[peer])) + bank_off_pkts +
                          (size_t)rank * slot;
            llStoreB128(reinterpret_cast<uint32_t*>(&dst[pk]), d0, flag, d1, flag);
        }
    }

    // reduce: poll the peers' slots of this rank's FIFO, sum in rank order
    LLLine* my_base = reinterpret_cast<LLLine*>(const_cast<void*>(peer_fifo.ptrs[rank])) + bank_off_pkts;
    for(size_t pk = gtid; pk < n_pk; pk += stride)
    {
        const PL selfv = *reinterpret_cast<const PL*>(&in[2 * pk]);
        AL acc;
#pragma unroll
        for(int j = 0; j < payload_size; ++j)
            acc[j] = upcastS(selfv[j]);

        uint32_t load_reg[ngpus - 1][4];
        volatile LLLine* src[ngpus - 1];
#pragma unroll
        for(int i = 1; i < ngpus; ++i)
        {
            const int peer = (i - 1) + (i - 1 >= rank);
            src[i - 1]     = my_base + (size_t)peer * slot;
        }
        bool still_loop;
        do
        {
            still_loop = false;
#pragma unroll
            for(int i = 0; i < ngpus - 1; ++i)
                llLoadB128(reinterpret_cast<const uint32_t*>(const_cast<LLLine*>(&src[i][pk])),
                           load_reg[i][0],
                           load_reg[i][1],
                           load_reg[i][2],
                           load_reg[i][3]);
#pragma unroll
            for(int i = 0; i < ngpus - 1; ++i)
            {
                still_loop = still_loop || load_reg[i][1] != flag;
                still_loop = still_loop || load_reg[i][3] != flag;
            }
        } while(still_loop);
#pragma unroll
        for(int i = 0; i < ngpus - 1; ++i)
        {
            const uint32_t w[2] = {load_reg[i][0], load_reg[i][2]};
            const PL pv         = *reinterpret_cast<const PL*>(w);
#pragma unroll
            for(int j = 0; j < payload_size; ++j)
            {
                // this rank's value goes in at its rank, not before the peers
                if(i == 0 && rank != 0)
                    acc[j] = upcastS(pv[j]);
                else
                    acc[j] += upcastS(pv[j]);
                if(i + 1 == rank)
                    acc[j] += upcastS(selfv[j]);
            }
        }
        PL ov;
#pragma unroll
        for(int j = 0; j < payload_size; ++j)
            ov[j] = downcastS<T>(acc[j]);
        reinterpret_cast<PL*>(recvbuff)[pk] = ov;
    }

    if(threadIdx.x == 0)
        block_epochs[blockIdx.x] = flag;
}

} // namespace commkit::gfx9
