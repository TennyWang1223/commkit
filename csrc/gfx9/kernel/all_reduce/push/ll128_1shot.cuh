#pragma once
// all_reduce, LL128 proto, push, one-shot (aiter ar_ll128_unroll2, 2-byte
// dtypes). 8-lane groups move 240 bytes as two 128-byte lines:
//   publish  every group writes its 15 packs of this rank's input, with the
//            epoch flag, into slot `rank` of every peer's FIFO
//   reduce   every group polls the flags of its lines in this rank's FIFO and
//            sums the peers' packs with its own input, in rank order
#include "gfx9/proto/ll128.cuh"

namespace commkit::gfx9 {

template <typename T, int ngpus, int block_size>
__global__ void __launch_bounds__(block_size) arOneShotLL128(const T* __restrict__ input,
                                                                      T* __restrict__ output,
                                                                      RankData peer_fifo,
                                                                      uint32_t* __restrict__ epochs,
                                                                      int self_rank,
                                                                      int size)
{
    static_assert(sizeof(T) == 2, "LL128 handles 2-byte dtypes");
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = opus::vector_t<T, pack_size>;
    using A                 = opus::vector_t<opus::fp32_t, pack_size>;

    constexpr int group_per_block = block_size / 8;
    constexpr int pack_per_group  = 15;
    const int total_bytes         = size * sizeof(T);
    const int total_pack          = total_bytes / 16;
    const int total_group         = (total_bytes + kLL128GroupBytes - 1) / kLL128GroupBytes;
    const int lane_id             = threadIdx.x % 8;
    const int group_id            = threadIdx.x / 8;
    const int g_index             = blockIdx.x * group_per_block + group_id;
    const int stride              = gridDim.x * group_per_block;
    const int last_group_pack_num = total_pack % 15 == 0 ? 15 : total_pack % 15;

    __shared__ uint32_t s_flag;
    const uint32_t flag   = ll128EpochBegin(epochs, blockIdx.x, s_flag);
    const int bank_offset = (flag & 1u) * ngpus * kLL128SlotStride;

    // publish
    for(int idx = g_index; idx < total_group; idx += stride)
    {
        P inp_reg[2];
        ll128LoadGroup<T>(idx, lane_id, total_group, last_group_pack_num, flag, input, inp_reg);
#pragma unroll
        for(int i = 1; i < ngpus; ++i)
        {
            const int peer         = (self_rank + i) % ngpus;
            uint32_t* scratch_dst = reinterpret_cast<uint32_t*>(const_cast<void*>(peer_fifo.ptrs[peer])) +
                                    bank_offset + self_rank * kLL128SlotStride + idx * 8 * 2 * 4 + lane_id * 4;
            ll128StoreB128<T>(inp_reg[0], scratch_dst);
            ll128StoreB128<T>(inp_reg[1], scratch_dst + 8 * 4);
        }
    }

    // reduce
    uint32_t* self_scratch = reinterpret_cast<uint32_t*>(const_cast<void*>(peer_fifo.ptrs[self_rank])) + bank_offset;
    for(int idx = g_index; idx < total_group; idx += stride)
    {
        P inp_reg[2];
        ll128LoadGroup<T>(idx, lane_id, total_group, last_group_pack_num, flag, input, inp_reg);
        A reduce_rslt_f32[2];
#pragma unroll
        for(int i = 0; i < pack_size; ++i)
        {
            reduce_rslt_f32[0][i] = upcastS(inp_reg[0][i]);
            reduce_rslt_f32[1][i] = upcastS(inp_reg[1][i]);
        }
        uint32_t* scratch_base[ngpus - 1];
        uint32_t* scratch_flag_addr[2][ngpus - 1];
#pragma unroll
        for(int i = 1; i < ngpus; ++i)
        {
            const int peer              = (i - 1) + (i - 1 >= self_rank);
            scratch_base[i - 1]         = self_scratch + peer * kLL128SlotStride + idx * 8 * 2 * 4;
            scratch_flag_addr[0][i - 1] = scratch_base[i - 1] + 7 * 4;
            scratch_flag_addr[1][i - 1] = scratch_flag_addr[0][i - 1] + 8 * 4;
        }
        uint32_t s_f[2][2 * (ngpus - 1)];
        bool still_loop;
        do
        {
            still_loop = false;
#pragma unroll
            for(int i = 0; i < ngpus - 1; ++i)
                ll128CheckFlag(s_f[0][2 * i], s_f[0][2 * i + 1], scratch_flag_addr[0][i]);
#pragma unroll
            for(int i = 0; i < ngpus - 1; ++i)
            {
                still_loop = still_loop || s_f[0][2 * i] != flag;
                still_loop = still_loop || s_f[0][2 * i + 1] != flag;
            }
        } while(still_loop);
        P reduce_elem[ngpus - 1];
#pragma unroll
        for(int i = 0; i < ngpus - 1; ++i)
        {
            ll128LoadB128<T>(reduce_elem[i], scratch_base[i] + lane_id * 4);
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
            {
                // this rank's value goes in at its rank, not before the peers
                if(i == 0 && self_rank != 0)
                    reduce_rslt_f32[0][j] = upcastS(reduce_elem[i][j]);
                else
                    reduce_rslt_f32[0][j] += upcastS(reduce_elem[i][j]);
                if(i + 1 == self_rank)
                    reduce_rslt_f32[0][j] += upcastS(inp_reg[0][j]);
            }
        }

        do
        {
            still_loop = false;
#pragma unroll
            for(int i = 0; i < ngpus - 1; ++i)
                ll128CheckFlag(s_f[1][2 * i], s_f[1][2 * i + 1], scratch_flag_addr[1][i]);
#pragma unroll
            for(int i = 0; i < ngpus - 1; ++i)
            {
                still_loop = still_loop || s_f[1][2 * i] != flag;
                still_loop = still_loop || s_f[1][2 * i + 1] != flag;
            }
        } while(still_loop);
#pragma unroll
        for(int i = 0; i < ngpus - 1; ++i)
        {
            ll128LoadB128<T>(reduce_elem[i], scratch_base[i] + lane_id * 4 + 8 * 4);
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
            {
                if(i == 0 && self_rank != 0)
                    reduce_rslt_f32[1][j] = upcastS(reduce_elem[i][j]);
                else
                    reduce_rslt_f32[1][j] += upcastS(reduce_elem[i][j]);
                if(i + 1 == self_rank)
                    reduce_rslt_f32[1][j] += upcastS(inp_reg[1][j]);
            }
        }

        // write the output (lane 7 reassembles pack 7 from the two lines)
        P reduce_rslt[2];
#pragma unroll
        for(int i = 0; i < 2; ++i)
        {
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                reduce_rslt[i][j] = downcastS<T>(reduce_rslt_f32[i][j]);
        }
        if(lane_id == 7)
        {
#pragma unroll
            for(int i = 0; i < pack_size / 2; ++i)
                reduce_rslt[0][pack_size / 2 + i] = reduce_rslt[1][i];
        }
        const bool is_last_group = (idx == total_group - 1);
        if(!is_last_group || lane_id < last_group_pack_num)
            *(reinterpret_cast<P*>(output) + idx * pack_per_group + lane_id) = reduce_rslt[0];
        if(lane_id != 7 && (!is_last_group || lane_id + 8 < last_group_pack_num))
            *(reinterpret_cast<P*>(output) + idx * pack_per_group + lane_id + 8) = reduce_rslt[1];
    }
    ll128EpochEnd(epochs, blockIdx.x, gridDim.x, kLL128MaxBlocks, flag);
}

} // namespace commkit::gfx9
