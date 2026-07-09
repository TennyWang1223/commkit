#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "commkit/tmp_buf.cuh"
#include "opus/opus.hpp"

// for tp4 kernel only
namespace commkit::kernels {

template <typename T>
__global__ void __launch_bounds__(256, 1) ar_tp4_overlap(RankData* _input_dp,
                                                                     RankData* _output_dp,
                                                                     RankSignals sg,
                                                                     Signal* self_sg,
                                                                     T* __restrict__ result,
                                                                     int rank,
                                                                     int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = 256 / 4;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id             = threadIdx.x / tnum_gpu;
    int lane_id             = threadIdx.x % tnum_gpu;
    int tid                 = blockIdx.x * tnum_gpu + lane_id;
    int stride              = gridDim.x * tnum_gpu;
    int part                = size / 4;
    int start               = rank * part;
    int end                 = rank == 4 - 1 ? size : start + part;
    int largest_part        = part + size % 4;
    __shared__ T tmp_smem[256 * pack_size * 2];
    const P* ptrs[4];
    P* tmps[4];
#pragma unroll
    for(int i = 0; i < 4; i++)
    {
        int target = (rank + i) % 4;
        ptrs[i]    = (const P*)_input_dp->ptrs[target];
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto tmp_out = tmps[0];
    start_sync<4>(sg, self_sg, rank);
    // ss<8>(sg, self_sg, rank);
    // stage 1: reduce scatter

    int loop_time = 0;
    for(int idx = start + tid; idx < end; idx += stride) ++loop_time;

    *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][start + tid];
    __syncthreads();

    for (int i = 0; i < loop_time - 1; ++i)
    {
      const P* gptr = &ptrs[warp_id][start + tid + stride * (i + 1)];
      int4 remote_data_reg;
      asm volatile("flat_load_dwordx4 %0, %1"
                   : "=v"(remote_data_reg)
                   : "v"(gptr)
                   : "memory");
      int store_lds_start = 256 * pack_size * ((i + 1) - (((i + 1) >> 1) << 1));
      int load_lds_start = 256 * pack_size * (i - ((i >> 1) << 1));
      if (warp_id == 0)
      {
        A add_reg;
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] = upcast_s(tmp_smem[load_lds_start + pack_size * threadIdx.x + j]);
        }
#pragma unroll
        for (int j = 1; j < 4; ++j)
        {
#pragma unroll
          for (int k = 0; k < pack_size; ++k)
          {
            add_reg[k] += upcast_s(tmp_smem[load_lds_start + pack_size * threadIdx.x + k + j * 64 * pack_size]);
          }
        }
        P write_reg;
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          write_reg[j] = downcast_s<T>(add_reg[j]);
        }
        tmp_out[tid + i * stride] = write_reg;
        asm volatile("s_waitcnt vmcnt(1) lgkmcnt(0)" ::: "memory");
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x) = remote_data_reg;
      }
      else
      {
        asm volatile("s_waitcnt vmcnt(0) lgkmcnt(0)" ::: "memory");
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x) = remote_data_reg;
      }
      __syncthreads();
    }
    if (warp_id == 0)
    {
      A add_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        add_reg[i] = upcast_s(tmp_smem[256 * pack_size * ((loop_time - 1) - (((loop_time - 1) >> 1) << 1)) + pack_size * threadIdx.x + i]);
      }
#pragma unroll
      for (int i = 1; i < 8; ++i)
      {
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] += upcast_s(tmp_smem[((loop_time - 1) - (((loop_time - 1) >> 1) << 1)) * 256 * pack_size + pack_size * threadIdx.x + j + i * 64 * pack_size]);
        }
      }
      P write_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        write_reg[i] = downcast_s<T>(add_reg[i]);
      }
      tmp_out[tid + (loop_time - 1) * stride] = write_reg;
    }
    end_sync_asm<4>(sg, self_sg, rank);

    // stage 2: allgather. Note: it's important to match the tid between
    // the two stages, because visibility across devices is only guaranteed
    // between threads that have the same tid. If thread i computes the sum of
    // start + i in the first stage, then thread i also gathers start + i from all
    // ranks.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
        int dst_idx           = (warp_id + rank) % 4 * part + idx;
        ((P*)result)[dst_idx] = tmps[warp_id][idx];
    }
}

// 320 threads per block, 5 waves
// 1 wave compute, 4 waves memory
template <typename T>
__global__ void __launch_bounds__(320, 1) ar_tp4_5wave_overlap(RankData* _input_dp,
                                                                     RankData* _output_dp,
                                                                     RankSignals sg,
                                                                     Signal* self_sg,
                                                                     T* __restrict__ result,
                                                                     int rank,
                                                                     int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = 256 / 4;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id             = threadIdx.x / tnum_gpu;
    int lane_id             = threadIdx.x % tnum_gpu;
    int tid                 = blockIdx.x * tnum_gpu + lane_id;
    int stride              = gridDim.x * tnum_gpu;
    int part                = size / 4;
    int start               = rank * part;
    int end                 = rank == 4 - 1 ? size : start + part;
    int largest_part        = part + size % 4;
    __shared__ T tmp_smem[256 * pack_size * 2];
    const P* ptrs[4];
    P* tmps[4];
#pragma unroll
    for(int i = 0; i < 4; i++)
    {
        int target = (rank + i) % 4;
        ptrs[i]    = (const P*)_input_dp->ptrs[target];
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto tmp_out = tmps[0];
    start_sync<4>(sg, self_sg, rank);
    // ss<8>(sg, self_sg, rank);
    // stage 1: reduce scatter

    int loop_time = 0;
    for(int idx = start + tid; idx < end; idx += stride) ++loop_time;

    if (warp_id < 4)
    {
      *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][start + tid];
    }
    __syncthreads();

    for (int i = 0; i < loop_time - 1; ++i)
    {
      if (warp_id < 4)
      {
        const P* gptr = &ptrs[warp_id][start + tid + stride * (i + 1)];
        int4 remote_data_reg;
        asm volatile("flat_load_dwordx4 %0, %1\n\t"
                     "s_waitcnt vmcnt(0) lgkmcnt(0)"
                    : "=v"(remote_data_reg)
                    : "v"(gptr)
                    : "memory");
        int store_lds_start = 256 * pack_size * ((i + 1) - (((i + 1) >> 1) << 1));
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x) = remote_data_reg;
      }
      else
      {
        int load_lds_start = 256 * pack_size * (i - ((i >> 1) << 1));
        A add_reg;
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] = upcast_s(tmp_smem[load_lds_start + pack_size * lane_id + j]);
        }
#pragma unroll
        for (int j = 1; j < 4; ++j)
        {
#pragma unroll
          for (int k = 0; k < pack_size; ++k)
          {
            add_reg[k] += upcast_s(tmp_smem[load_lds_start + pack_size * lane_id + k + j * 64 * pack_size]);
          }
        }
        P write_reg;
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          write_reg[j] = downcast_s<T>(add_reg[j]);
        }
        tmp_out[tid + i * stride] = write_reg;
      }
      __syncthreads();
    }
    if (warp_id == 4)
    {
      A add_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        add_reg[i] = upcast_s(tmp_smem[256 * pack_size * ((loop_time - 1) - (((loop_time - 1) >> 1) << 1)) + pack_size * lane_id + i]);
      }
#pragma unroll
      for (int i = 1; i < 4; ++i)
      {
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] += upcast_s(tmp_smem[((loop_time - 1) - (((loop_time - 1) >> 1) << 1)) * 256 * pack_size + pack_size * lane_id + j + i * 64 * pack_size]);
        }
      }
      P write_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        write_reg[i] = downcast_s<T>(add_reg[i]);
      }
      tmp_out[tid + (loop_time - 1) * stride] = write_reg;
    }
    end_sync_asm<4>(sg, self_sg, rank);

    // stage 2: allgather. Note: it's important to match the tid between
    // the two stages, because visibility across devices is only guaranteed
    // between threads that have the same tid. If thread i computes the sum of
    // start + i in the first stage, then thread i also gathers start + i from all
    // ranks.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
      if (warp_id < 4)
      {
        int dst_idx           = (warp_id + rank) % 4 * part + idx;
        ((P*)result)[dst_idx] = tmps[warp_id][idx];
      }
    }
}

}
