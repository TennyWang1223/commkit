#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "commkit/tmp_buf.cuh"
#include "opus/opus.hpp"

#include "block_size_256_kernel_tp4.cuh"

namespace commkit::kernels {

constexpr int kThreadNum2Stage = 512;
#define THREAD_NUM 512

template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) cross_device_reduce_2stage(RankData* _input_dp,
                                                                     RankData* _output_dp,
                                                                     RankSignals sg,
                                                                     Signal* self_sg,
                                                                     T* __restrict__ result,
                                                                     int rank,
                                                                     int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = THREAD_NUM / ngpus;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id             = threadIdx.x / tnum_gpu;
    int lane_id             = threadIdx.x % tnum_gpu;
    int tid                 = blockIdx.x * tnum_gpu + lane_id;
    int stride              = gridDim.x * tnum_gpu;
    int part                = size / ngpus;
    int start               = rank * part;
    int end                 = rank == ngpus - 1 ? size : start + part;
    int largest_part        = part + size % ngpus;
    __shared__ T tmp_smem[tnum_gpu * ngpus * pack_size];
    const P* ptrs[ngpus];
    P* tmps[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        int target = (rank + i) % ngpus;
        ptrs[i]    = (const P*)_input_dp->ptrs[target];
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto tmp_out = tmps[0];
    start_sync<ngpus>(sg, self_sg, rank);
    // stage 1: reduce scatter
    for(int idx = start + tid; idx < end; idx += stride)
    {
        *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][idx];
        __syncthreads();
        // cal add in first 64 threads
        if(warp_id == 0)
        {
            A add_reg;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
            {
                add_reg[i] = upcast_s(tmp_smem[pack_size * threadIdx.x + i]);
            }
            constexpr int smem_gpu_loop_stride = tnum_gpu * pack_size;
#pragma unroll
            for(int i = 1; i < ngpus; ++i)
            {
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                {
                    add_reg[j] +=
                        upcast_s(tmp_smem[i * smem_gpu_loop_stride + pack_size * threadIdx.x + j]);
                }
            }
            P write_reg;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
            {
                write_reg[i] = downcast_s<T>(add_reg[i]);
            }
            tmp_out[idx - start] = write_reg;
        }
        __syncthreads();
    }
    end_sync<ngpus>(sg, self_sg, rank);

    // stage 2: allgather. Note: it's important to match the tid between
    // the two stages, because visibility across devices is only guaranteed
    // between threads that have the same tid. If thread i computes the sum of
    // start + i in the first stage, then thread i also gathers start + i from all
    // ranks.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
        int dst_idx           = (warp_id + rank) % ngpus * part + idx;
        ((P*)result)[dst_idx] = tmps[warp_id][idx];
    }
}

template <typename T>
__global__ void __launch_bounds__(512, 1) ar_naive_overlap(RankData* _input_dp,
                                                                     RankData* _output_dp,
                                                                     RankSignals sg,
                                                                     Signal* self_sg,
                                                                     T* __restrict__ result,
                                                                     int rank,
                                                                     int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = THREAD_NUM / 8;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id             = threadIdx.x / tnum_gpu;
    int lane_id             = threadIdx.x % tnum_gpu;
    int tid                 = blockIdx.x * tnum_gpu + lane_id;
    int stride              = gridDim.x * tnum_gpu;
    int part                = size / 8;
    int start               = rank * part;
    int end                 = rank == 8 - 1 ? size : start + part;
    int largest_part        = part + size % 8;
    __shared__ T tmp_smem[512 * pack_size * 2];
    const P* ptrs[8];
    P* tmps[8];
#pragma unroll
    for(int i = 0; i < 8; i++)
    {
        int target = (rank + i) % 8;
        ptrs[i]    = (const P*)_input_dp->ptrs[target];
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto tmp_out = tmps[0];
    // start_sync<8>(sg, self_sg, rank);
    ss<8>(sg, self_sg, rank);
    // stage 1: reduce scatter

    int loop_time = 0;
    for(int idx = start + tid; idx < end; idx += stride) ++loop_time;

    *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][start + tid];
    __syncthreads();

    for (int i = 0; i < loop_time; ++i)
    {
      const P* gptr = &ptrs[warp_id][start + tid + stride * (i + 1)];
      int4 remote_data_reg;
      asm volatile("flat_load_dwordx4 %0, %1"
                   : "=v"(remote_data_reg)
                   : "v"(gptr)
                   : "memory");
      int store_lds_start = 512 * pack_size * ((i + 1) - (((i + 1) >> 1) << 1));
      int load_lds_start = 512 * pack_size * (i - ((i >> 1) << 1));
      if (warp_id == 0)
      {
        A add_reg;
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] = upcast_s(tmp_smem[load_lds_start + pack_size * threadIdx.x + j]);
        }
#pragma unroll
        for (int j = 1; j < 8; ++j)
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
        add_reg[i] = upcast_s(tmp_smem[512 * pack_size * (loop_time - ((loop_time >> 1) << 1)) + pack_size * threadIdx.x + i]);
      }
#pragma unroll
      for (int i = 1; i < 8; ++i)
      {
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] += upcast_s(tmp_smem[(loop_time - ((loop_time >> 1) << 1)) * 512 * pack_size + pack_size * threadIdx.x + j + i * 64 * pack_size]);
        }
      }
      P write_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        write_reg[i] = downcast_s<T>(add_reg[i]);
      }
      tmp_out[tid + loop_time * stride] = write_reg;
    }
    end_sync_asm<8>(sg, self_sg, rank);

    // stage 2: allgather. Note: it's important to match the tid between
    // the two stages, because visibility across devices is only guaranteed
    // between threads that have the same tid. If thread i computes the sum of
    // start + i in the first stage, then thread i also gathers start + i from all
    // ranks.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
        int dst_idx           = (warp_id + rank) % 8 * part + idx;
        ((P*)result)[dst_idx] = tmps[warp_id][idx];
    }
}

template <typename T>
__global__ void __launch_bounds__(256, 1) ar_4wave_overlap(RankData* _input_dp,
                                                                     RankData* _output_dp,
                                                                     RankSignals sg,
                                                                     Signal* self_sg,
                                                                     T* __restrict__ result,
                                                                     int rank,
                                                                     int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = 64;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id             = threadIdx.x / tnum_gpu;
    int lane_id             = threadIdx.x % tnum_gpu;
    int tid                 = blockIdx.x * tnum_gpu + lane_id;
    int stride              = gridDim.x * tnum_gpu;
    int part                = size / 8;
    int start               = rank * part;
    int end                 = rank == 8 - 1 ? size : start + part;
    int largest_part        = part + size % 8;
    __shared__ T tmp_smem[512 * pack_size * 2];
    const P* ptrs[8];
    P* tmps[8];
#pragma unroll
    for(int i = 0; i < 8; i++)
    {
        int target = (rank + i) % 8;
        ptrs[i]    = (const P*)_input_dp->ptrs[target];
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto tmp_out = tmps[0];
    start_sync<8>(sg, self_sg, rank);
    // stage 1: reduce scatter

    int loop_time = 0;
    for(int idx = start + tid; idx < end; idx += stride) ++loop_time;

    *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = ptrs[warp_id][start + tid];
    *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x + 256) = ptrs[warp_id + 4][start + tid];
    __syncthreads();

    for (int i = 0; i < loop_time; ++i)
    {
      const P* gptr0 = &ptrs[warp_id][start + tid + stride * (i + 1)];
      const P* gptr1 = &ptrs[warp_id + 4][start + tid + stride * (i + 1)];
      int4 remote_data_reg0;
      int4 remote_data_reg1;
      asm volatile("flat_load_dwordx4 %0, %2\n\t"
                   "flat_load_dwordx4 %1, %3\n\t"
                   : "=v"(remote_data_reg0), "=v"(remote_data_reg1)
                   : "v"(gptr0), "v"(gptr1)
                   : "memory");
      int store_lds_start = 512 * pack_size * ((i + 1) - (((i + 1) >> 1) << 1));
      int load_lds_start = 512 * pack_size * (i - ((i >> 1) << 1));
      if (warp_id == 0)
      {
        A add_reg;
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] = upcast_s(tmp_smem[load_lds_start + pack_size * threadIdx.x + j]);
        }
#pragma unroll
        for (int j = 1; j < 8; ++j)
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
        asm volatile("s_waitcnt vmcnt(2) lgkmcnt(0)" ::: "memory");
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x) = remote_data_reg0;
        asm volatile("s_waitcnt vmcnt(1) lgkmcnt(0)" ::: "memory");
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x + 256) = remote_data_reg1;
      }
      else
      {
        asm volatile("s_waitcnt vmcnt(1) lgkmcnt(0)" ::: "memory");
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x) = remote_data_reg0;
        asm volatile("s_waitcnt vmcnt(0) lgkmcnt(0)" ::: "memory");
        *(reinterpret_cast<int4*>(&tmp_smem[store_lds_start]) + threadIdx.x + 256) = remote_data_reg1;
      }
      __syncthreads();
    }
    if (warp_id == 0)
    {
      A add_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        add_reg[i] = upcast_s(tmp_smem[512 * pack_size * (loop_time - ((loop_time >> 1) << 1)) + pack_size * threadIdx.x + i]);
      }
#pragma unroll
      for (int i = 1; i < 8; ++i)
      {
#pragma unroll
        for (int j = 0; j < pack_size; ++j)
        {
          add_reg[j] += upcast_s(tmp_smem[(loop_time - ((loop_time >> 1) << 1)) * 512 * pack_size + pack_size * threadIdx.x + j + i * 64 * pack_size]);
        }
      }
      P write_reg;
#pragma unroll
      for (int i = 0; i < pack_size; ++i)
      {
        write_reg[i] = downcast_s<T>(add_reg[i]);
      }
      tmp_out[tid + loop_time * stride] = write_reg;
    }
    end_sync<8>(sg, self_sg, rank);

    // stage 2: allgather. Note: it's important to match the tid between
    // the two stages, because visibility across devices is only guaranteed
    // between threads that have the same tid. If thread i computes the sum of
    // start + i in the first stage, then thread i also gathers start + i from all
    // ranks.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
        int dst_idx0           = (warp_id + rank) % 8 * part + idx;
        int dst_idx1           = (warp_id  + 4 + rank) % 8 * part + idx;
        ((P*)result)[dst_idx0] = tmps[warp_id][idx];
        ((P*)result)[dst_idx1] = tmps[warp_id + 4][idx];
    }
}

template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) car_wt(RankData* _input_dp,
                                                                     RankData* _output_dp,
                                                                     RankSignals sg,
                                                                     Signal* self_sg,
                                                                     T* __restrict__ result,
                                                                     int rank,
                                                                     int size)
{
    constexpr int pack_size = 16 / sizeof(T);
    constexpr int tnum_gpu  = THREAD_NUM / ngpus;
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id             = threadIdx.x / tnum_gpu;
    int lane_id             = threadIdx.x % tnum_gpu;
    int tid                 = blockIdx.x * tnum_gpu + lane_id;
    int stride              = gridDim.x * tnum_gpu;
    int part                = size / ngpus;
    int start               = rank * part;
    int end                 = rank == ngpus - 1 ? size : start + part;
    int largest_part        = part + size % ngpus;
    __shared__ T tmp_smem[tnum_gpu * ngpus * pack_size];
    const P* ptrs[ngpus];
    P* tmps[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
    {
        int target = (rank + i) % 8;
        ptrs[i]    = (const P*)_input_dp->ptrs[target];
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }

    auto self_inp = ptrs[0];
    auto self_tmp = tmps[0];

    int rank_id = warp_id - rank;
    if (rank_id < 0)
    {
      rank_id += 8;
    }

    for (int idx = tid; idx < part; idx += stride)
    {
      tmps[rank_id][rank * part + idx] = self_inp[warp_id * part + idx];
    }
    end_sync_asm<ngpus>(sg, self_sg, rank);

    // stage 1: reduce scatter
    for(int idx = tid; idx < part; idx += stride)
    {
      *(reinterpret_cast<P*>(&tmp_smem[0]) + threadIdx.x) = self_tmp[warp_id * part + idx];
      __syncthreads();
        // cal add in first 64 threads
        if(warp_id == 0)
        {
            A reduce_rslt_fp32;
            P reduce_elem[ngpus];
#pragma unroll
            for (int i = 0; i < ngpus; ++i)
            {
              reduce_elem[i] = *(reinterpret_cast<P*>(&tmp_smem[0]) + i * tnum_gpu + lane_id);
            }
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
            {
              reduce_rslt_fp32[i] = upcast_s(reduce_elem[0][i]);
            }
#pragma unroll
            for(int i = 1; i < ngpus; ++i)
            {
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                {
                  reduce_rslt_fp32[j] += upcast_s(reduce_elem[i][j]);
                }
            }
            P reduce_rslt;
#pragma unroll
            for(int i = 0; i < pack_size; ++i)
            {
                reduce_rslt[i] = downcast_s<T>(reduce_rslt_fp32[i]);
            }
#pragma unroll
            for (int i = 0; i < ngpus; ++i)
            {
              *(reinterpret_cast<P*>(&tmp_smem[0]) + i * tnum_gpu + lane_id) = reduce_rslt;
            }
        }
        __syncthreads();
        tmps[warp_id][size + start + idx] = *(reinterpret_cast<P*>(&tmp_smem[0]) + warp_id * tnum_gpu + lane_id);
        __syncthreads();
    }
    end_sync_asm<ngpus>(sg, self_sg, rank);

    // stage 2: allgather. Note: it's important to match the tid between
    // the two stages, because visibility across devices is only guaranteed
    // between threads that have the same tid. If thread i computes the sum of
    // start + i in the first stage, then thread i also gathers start + i from all
    // ranks.
    for(int idx = tid; idx < largest_part; idx += stride)
    {
        int dst_idx           = warp_id * part + idx;
        ((P*)result)[dst_idx] = self_tmp[size + dst_idx];
    }
}

// car tp8 special, 512 threads, 8wave, 4wave double buffer
/*
 * double buffer
 * A means first buffer, B means second buffer
 * allreduce stage 1: c->a->b
 * c: cross device load, store to LDS
 * a: load LDS by 8 warp, reduce by 1 warp
 * b: load LDS, cross device store
 * */
template <typename T, bool LoopA>
__device__ __forceinline__ void step_a(T* lds_addr, int warp_id, int lane_id)
{
  constexpr int pack_size = 16 / sizeof(T);
  using P = typename opus::vector_t<T, pack_size>;
  using A = typename opus::vector_t<opus::fp32_t, pack_size>;
  int warp = warp_id - (LoopA ? 0 : 8);

  if (warp == 0)
  {
    A reduce_rslt_fp32;
    P reduce_elem = *(reinterpret_cast<P*>(lds_addr) + lane_id);
#pragma unroll
    for (int i = 0; i < pack_size; ++i)
    {
      reduce_rslt_fp32[i] = upcast_s(reduce_elem[i]);
    }
#pragma unroll
    for (int i = 1; i < 8; ++i)
    {
      reduce_elem = *(reinterpret_cast<P*>(lds_addr) + i * 32 + lane_id);
#pragma unroll
      for (int j = 0; j < pack_size; ++j)
      {
        reduce_rslt_fp32[j] += upcast_s(reduce_elem[j]);
      }
    }
    P reduce_rslt;
#pragma unroll
    for (int i = 0; i < pack_size; ++i)
    {
      reduce_rslt[i] = downcast_s<T>(reduce_rslt_fp32[i]);
    }
#pragma unroll
    for (int i = 0; i < 8; ++i)
    {
      *(reinterpret_cast<P*>(lds_addr) + i * 32 + lane_id) = reduce_rslt;
    }
  }
}

template <typename T>
__global__ void __launch_bounds__(512, 1)
car_tp8(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    // constexpr int tnum_gpu  = kThreadNum2Stage / 8; = 64
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    /*
     * 8 wave 2 slot
     * 2 warp per wave, 32 threads per warp
     * total 16 warp, 512 threads
     * warp_id in [0,15], lane_id in [0, 31]
     * */
    int warp_id      = threadIdx.x >> 5; // tid / 32, 32 threads per warp, split 1 wave into 2 warp
    int lane_id      = threadIdx.x - warp_id * 32;
    int tid          = blockIdx.x * 32 + lane_id;
    int stride       = gridDim.x * 32;
    int part         = size / 8;
    int start        = rank * part;
    int end          = (rank == 7) ? size : start + part;
    // int largest_part = part + size % 8;

    __shared__ T lds_A[256 * pack_size];
    __shared__ T lds_B[256 * pack_size];
    // T* lds = warp_id < 8 ? lds_A : lds_B;

    const P* ptrs[8];
    P* tmps[8];
#pragma unroll
    for (int i = 0; i < 8; ++i) {
        int target = (rank + i) % 8;
        ptrs[i]    = reinterpret_cast<const P*>(_input_dp->ptrs[target]);
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto* tmp_out = tmps[0];

    int loop_time = 0;
    for (int idx = start + tid; idx < end; idx += stride) ++loop_time;
    // int first_loop = (loop_time + 1) / 2;
    int second_loop = loop_time / 2;

    start_sync<8>(sg, self_sg, rank);

    if (loop_time > 1)
    {
      // prologue step 1: A run step-c
      if (warp_id < 8)
      {
        // cross device load
        // store to lds
        *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x) = ptrs[warp_id][start + tid];
      }
      __syncthreads();
      // prologue step 2: A run step-a, B run step-c
      // A run step-a
      if (warp_id < 8)
      {
        step_a<T, true>(&lds_A[0], warp_id, lane_id);
      }
      // B run step-c
      else
      {
        *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256) = ptrs[warp_id - 8][start + tid + stride];
      }
      __syncthreads();

      int steady = second_loop - 1; // second_loop is min
      for (int i = 0; i < steady; ++i)
      {
        // A run step-b and step-c, B run step-a
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + i * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
          // A run step-c
          *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x) = ptrs[warp_id][start + tid + (i + 1) * 2 * stride];
        }
        else
        {
          // B run step-a
          step_a<T, false>(&lds_B[0], warp_id, lane_id);
        }
        __syncthreads();
        // A run step-a, B run step-b, step-c
        if (warp_id < 8)
        {
          // A run step-a
          step_a<T, true>(&lds_A[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 8][start + tid + (i * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
          // B run step-c
          *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256) = ptrs[warp_id - 8][start + tid + ((i + 1) * 2 + 1) * stride];
        }
        __syncthreads();
      }
      // epilogue
      if ((loop_time & 1) == 0) // B last
      {
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
        }
        else
        {
          // B run step-a
          step_a<T, false>(&lds_B[0], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id > 7)
        {
          // B run step-b
          tmps[warp_id - 8][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
        }
      }
      else // A last
      {
        // A run step-b, step-c
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
          // A run step-c
          *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x) = ptrs[warp_id][start + tid + (steady + 1) * 2 * stride];
        }
        else
        {
          // B run step-a
          step_a<T, false>(&lds_B[0], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id < 8)
        {
          // A run step-a
          step_a<T, true>(&lds_A[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 8][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
        }
        __syncthreads();
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + (steady + 1) * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
        }
      }
    }
    else
    {
      // loop_time == 1
      // c->a->b
      if (warp_id < 8)
      {
        *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x) = ptrs[warp_id][start + tid];
        __syncthreads();
        step_a<T, true>(&lds_A[0], warp_id, lane_id);
        __syncthreads();
        tmps[warp_id][start + tid] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
      }
    }

    end_sync_asm<8, true, false>(sg, self_sg, rank);

    int dst_index;
    for (int i = 0; i < second_loop; ++i)
    {
      if (warp_id < 8)
      {
        dst_index = warp_id * part + tid + i * 2 * stride;
      }
      else
      {
        dst_index = (warp_id - 8) * part + tid + (i * 2 + 1) * stride;
      }
      *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
    }
    if ((loop_time & 1) == 0)
    {
      if (warp_id < 8)
      {
        dst_index = warp_id * part + tid + (loop_time - 1) * stride;
        *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
      }
    }
}

// ===========================================================================================
template <typename T, int ngpus, int cal_warp>
__device__ __forceinline__ void vmemload_cal_vmemstore(T* lds_addr, int warp_id, int lane_id)
{
  constexpr int pack_size = 16 / sizeof(T);
  using P = typename opus::vector_t<T, pack_size>;
  using A = typename opus::vector_t<opus::fp32_t, pack_size>;

  if (warp_id == cal_warp)
  {
    A reduce_rslt_fp32;
    P reduce_elem = *(reinterpret_cast<P*>(lds_addr) + lane_id);
#pragma unroll
    for (int i = 0; i < pack_size; ++i)
    {
      reduce_rslt_fp32[i] = upcast_s(reduce_elem[i]);
    }
#pragma unroll
    for (int i = 1; i < ngpus; ++i)
    {
      reduce_elem = *(reinterpret_cast<P*>(lds_addr) + i * 64 + lane_id);
#pragma unroll
      for (int j = 0; j < pack_size; ++j)
      {
        reduce_rslt_fp32[j] += upcast_s(reduce_elem[j]);
      }
    }
    P reduce_rslt;
#pragma unroll
    for (int i = 0; i < pack_size; ++i)
    {
      reduce_rslt[i] = downcast_s<T>(reduce_rslt_fp32[i]);
    }
#pragma unroll
    for (int i = 0; i < ngpus; ++i)
    {
      *(reinterpret_cast<P*>(lds_addr) + i * 64 + lane_id) = reduce_rslt;
    }
  }
}
/*
 * todo:
 * 8 wave inner overlap, run both cross device load/store and vmem add instruction in 1 wave
 * 4wave pingpong, load 2 device per wave - ongoing
 * 4wave pingpong with 2 wave calculate, load data count 2 times bigger than front task
 * */

// Issue both xGMI loads back-to-back so the two remote reads overlap on the
// fabric, then a single waitcnt covers both before the LDS writes.
/*
template <typename P>
__device__ __forceinline__ void load2_remote_to_lds(const P* gptr_a, const P* gptr_b,
                                                    P* lptr_a, P* lptr_b)
{
    uint32_t lds_off_a = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(lptr_a));
    uint32_t lds_off_b = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(lptr_b));
    int4 va, vb;
    asm volatile(
        "flat_load_dwordx4 %0, %2\n\t"
        "flat_load_dwordx4 %1, %3\n\t"
        "s_waitcnt vmcnt(0) lgkmcnt(0)\n\t"
        "ds_write_b128 %4, %0\n\t"
        "ds_write_b128 %5, %1\n\t"
        : "=&v"(va), "=&v"(vb)
        : "v"(gptr_a), "v"(gptr_b), "v"(lds_off_a), "v"(lds_off_b)
        : "memory");
}

template <typename T>
__global__ void __launch_bounds__(512, 1)
allreduce_double_buffer(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    // constexpr int tnum_gpu  = kThreadNum2Stage / 8; = 64
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id      = threadIdx.x >> 6; // tid / 32, 32 threads per warp, split 1 wave into 2 warp
    int lane_id      = threadIdx.x - warp_id * 64;
    int tid          = blockIdx.x * 64 + lane_id;
    int stride       = gridDim.x * 64;
    int part         = size / 8;
    int start        = rank * part;
    int end          = (rank == 7) ? size : start + part;

    __shared__ T lds_A[512 * pack_size];
    __shared__ T lds_B[512 * pack_size];
    // T* lds = warp_id < 8 ? lds_A : lds_B;

    const P* ptrs[8];
    P* tmps[8];
#pragma unroll
    for (int i = 0; i < 8; ++i) {
        int target = (rank + i) % 8;
        ptrs[i]    = reinterpret_cast<const P*>(_input_dp->ptrs[target]);
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto* tmp_out = tmps[0];

    int loop_time = 0;
    for (int idx = start + tid; idx < end; idx += stride) ++loop_time;
    // int first_loop = (loop_time + 1) / 2;
    int second_loop = loop_time / 2;

    start_sync<8>(sg, self_sg, rank);

    if (loop_time > 1)
    {
      // prologue step 1: A run step-c
      if (warp_id < 4)
      {
        load2_remote_to_lds<P>(ptrs[warp_id] + start + tid,
                               ptrs[warp_id + 4] + start + tid,
                               reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x,
                               reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
      }
      __syncthreads();
      // prologue step 2: A run step-a, B run step-c
      // A run step-a
      if (warp_id < 4)
      {
        sa<T, true>(&lds_A[0], warp_id, lane_id);
      }
      // B run step-c
      else
      {
        load2_remote_to_lds<P>(ptrs[warp_id] + start + tid + stride,
                               ptrs[warp_id - 4] + start + tid + stride,
                               reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x,
                               reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
      }
      __syncthreads();

      int steady = second_loop - 1; // second_loop is min
      for (int i = 0; i < steady; ++i)
      {
        // A run step-b and step-c, B run step-a
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + i * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
          tmps[warp_id + 4][start + tid + i * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
          // A run step-c
          load2_remote_to_lds<P>(ptrs[warp_id] + start + tid + (i + 1) * 2 * stride,
                                 ptrs[warp_id + 4] + start + tid + (i + 1) * 2 * stride,
                                 reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x,
                                 reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
        }
        else
        {
          // B run step-a
          sa<T, false>(&lds_B[0], warp_id, lane_id);
        }
        __syncthreads();
        // A run step-a, B run step-b, step-c
        if (warp_id < 4)
        {
          // A run step-a
          sa<T, true>(&lds_A[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 4][start + tid + (i * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
          tmps[warp_id][start + tid + (i * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x);
          // B run step-c
          load2_remote_to_lds<P>(ptrs[warp_id] + start + tid + ((i + 1) * 2 + 1) * stride,
                                 ptrs[warp_id - 4] + start + tid + ((i + 1) * 2 + 1) * stride,
                                 reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x,
                                 reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
        }
        __syncthreads();
      }
      // epilogue
      if ((loop_time & 1) == 0) // B last
      {
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
          tmps[warp_id + 4][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
        }
        else
        {
          // B run step-a
          sa<T, false>(&lds_B[0], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id > 3)
        {
          // B run step-b
          tmps[warp_id][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x);
          tmps[warp_id - 4][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
        }
      }
      else // A last
      {
        // A run step-b, step-c
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
          tmps[warp_id + 4][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
          // A run step-c
          load2_remote_to_lds<P>(ptrs[warp_id] + start + tid + (steady + 1) * 2 * stride,
                                 ptrs[warp_id + 4] + start + tid + (steady + 1) * 2 * stride,
                                 reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x,
                                 reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
        }
        else
        {
          // B run step-a
          sa<T, false>(&lds_B[0], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id < 4)
        {
          // A run step-a
          sa<T, true>(&lds_A[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x);
          tmps[warp_id - 4][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds_B[0]) + threadIdx.x - 256);
        }
        __syncthreads();
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + (steady + 1) * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
          tmps[warp_id + 4][start + tid + (steady + 1) * 2 * stride] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
        }
      }
    }
    else
    {
      // loop_time == 1
      // c->a->b
      if (warp_id < 4)
      {
        load2_remote_to_lds<P>(ptrs[warp_id] + start + tid,
                               ptrs[warp_id + 4] + start + tid,
                               reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x,
                               reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
        __syncthreads();
        sa<T, true>(&lds_A[0], warp_id, lane_id);
        __syncthreads();
        tmps[warp_id][start + tid] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x);
        tmps[warp_id + 4][start + tid] = *(reinterpret_cast<P*>(&lds_A[0]) + threadIdx.x + 256);
      }
    }

    end_sync_asm<8, true, false>(sg, self_sg, rank);

    int dst_index;
    for (int i = 0; i < loop_time; ++i)
    {
      dst_index = warp_id * part + tid + i * stride;
      *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
    }
}

*/
template <typename T>
__global__ void __launch_bounds__(1024, 4)
allreduce_double_buffer(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    // constexpr int tnum_gpu  = kThreadNum2Stage / 8; = 64
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id      = threadIdx.x >> 6; // tid / 32, 32 threads per warp, split 1 wave into 2 warp
    int lane_id      = threadIdx.x - warp_id * 64;
    int tid          = blockIdx.x * 64 + lane_id;
    int stride       = gridDim.x * 64;
    int part         = size / 8;
    int start        = rank * part;
    int end          = (rank == 7) ? size : start + part;
    // int largest_part = part + size % 8;

    __shared__ T lds[1024 * pack_size];
    // T* lds = warp_id < 8 ? lds_A : lds_B;

    const P* ptrs[8];
    P* tmps[8];
#pragma unroll
    for (int i = 0; i < 8; ++i) {
        int target = (rank + i) % 8;
        ptrs[i]    = reinterpret_cast<const P*>(_input_dp->ptrs[target]);
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto* tmp_out = tmps[0];

    int loop_time = 0;
    for (int idx = start + tid; idx < end; idx += stride) ++loop_time;
    // int first_loop = (loop_time + 1) / 2;
    int second_loop = loop_time / 2;

    start_sync<8>(sg, self_sg, rank);

    if (loop_time > 1)
    {
      // prologue step 1: A run step-c
      if (warp_id < 8)
      {
        // cross device load
        // store to lds
        *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid];
      }
      __syncthreads();
      // prologue step 2: A run step-a, B run step-c
      // A run step-a
      if (warp_id < 8)
      {
        vmemload_cal_vmemstore<T, 8, 0>(&lds[0], warp_id, lane_id);
      }
      // B run step-c
      else
      {
        *(reinterpret_cast<P*>(&lds[512 * pack_size]) + 64 * (warp_id - 8) + lane_id) = ptrs[warp_id - 8][start + tid + stride];
      }
      __syncthreads();

      int steady = second_loop - 1; // second_loop is min
      for (int i = 0; i < steady; ++i)
      {
        // A run step-b and step-c, B run step-a
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + i * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
          // A run step-c
          *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid + (i + 1) * 2 * stride];
        }
        else
        {
          // B run step-a
          vmemload_cal_vmemstore<T, 8, 8>(&lds[512 * pack_size], warp_id, lane_id);
        }
        __syncthreads();
        // A run step-a, B run step-b, step-c
        if (warp_id < 8)
        {
          // A run step-a
          vmemload_cal_vmemstore<T, 8, 0>(&lds[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 8][start + tid + (i * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds[512 * pack_size]) + 64 * (warp_id - 8) + lane_id);
          // B run step-c
          *(reinterpret_cast<P*>(&lds[512 * pack_size]) + 64 * (warp_id - 8) + lane_id) = ptrs[warp_id - 8][start + tid + ((i + 1) * 2 + 1) * stride];
        }
        __syncthreads();
      }
      // epilogue
      if ((loop_time & 1) == 0) // B last
      {
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
        }
        else
        {
          // B run step-a
          vmemload_cal_vmemstore<T, 8, 8>(&lds[512 * pack_size], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id > 7)
        {
          // B run step-b
          tmps[warp_id - 8][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds[512 * pack_size]) + 64 * (warp_id - 8) + lane_id);
        }
      }
      else // A last
      {
        // A run step-b, step-c
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
          // A run step-c
          *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid + (steady + 1) * 2 * stride];
        }
        else
        {
          // B run step-a
          vmemload_cal_vmemstore<T, 8, 8>(&lds[512 * pack_size], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id < 8)
        {
          // A run step-a
          vmemload_cal_vmemstore<T, 8, 0>(&lds[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 8][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds[512 * pack_size]) + 64 * (warp_id - 8) + lane_id);
        }
        __syncthreads();
        if (warp_id < 8)
        {
          // A run step-b
          tmps[warp_id][start + tid + (steady + 1) * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
        }
      }
    }
    else
    {
      // loop_time == 1
      // c->a->b
      if (warp_id < 8)
      {
        *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid];
        __syncthreads();
        vmemload_cal_vmemstore<T, 8, 0>(&lds[0], warp_id, lane_id);
        __syncthreads();
        tmps[warp_id][start + tid] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
      }
    }

    end_sync_asm<8, true, false>(sg, self_sg, rank);
    int dst_index;
    for (int i = 0; i < second_loop; ++i)
    {
      if (warp_id < 8)
      {
        dst_index = warp_id * part + tid + i * 2 * stride;
      }
      else
      {
        dst_index = (warp_id - 8) * part + tid + (i * 2 + 1) * stride;
      }
      *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
    }
    if ((loop_time & 1) == 0)
    {
      if (warp_id < 8)
      {
        dst_index = warp_id * part + tid + (loop_time - 1) * stride;
        *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
      }
    }
}

template <typename T>
__global__ void __launch_bounds__(512, 2)
car_db_tp4(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    // constexpr int tnum_gpu  = kThreadNum2Stage / 8; = 64
    using P                 = typename opus::vector_t<T, pack_size>;
    using A                 = typename opus::vector_t<opus::fp32_t, pack_size>;
    int warp_id      = threadIdx.x >> 6; // tid / 32, 32 threads per warp, split 1 wave into 2 warp
    int lane_id      = threadIdx.x - warp_id * 64;
    int tid          = blockIdx.x * 64 + lane_id;
    int stride       = gridDim.x * 64;
    int part         = size / 4;
    int start        = rank * part;
    int end          = (rank == 3) ? size : start + part;
    // int largest_part = part + size % 8;

    __shared__ T lds[512 * pack_size];
    // T* lds = warp_id < 8 ? lds_A : lds_B;

    const P* ptrs[4];
    P* tmps[4];
#pragma unroll
    for (int i = 0; i < 4; ++i) {
        int target = (rank + i) % 4;
        ptrs[i]    = reinterpret_cast<const P*>(_input_dp->ptrs[target]);
        tmps[i]    = get_tmp_buf<P>(sg.signals[target]);
    }
    auto* tmp_out = tmps[0];

    int loop_time = 0;
    for (int idx = start + tid; idx < end; idx += stride) ++loop_time;
    // int first_loop = (loop_time + 1) / 2;
    int second_loop = loop_time / 2;

    start_sync<4>(sg, self_sg, rank);

    if (loop_time > 1)
    {
      // prologue step 1: A run step-c
      if (warp_id < 4)
      {
        // cross device load
        // store to lds
        *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid];
      }
      __syncthreads();
      // prologue step 2: A run step-a, B run step-c
      // A run step-a
      if (warp_id < 4)
      {
        vmemload_cal_vmemstore<T, 4, 0>(&lds[0], warp_id, lane_id);
      }
      // B run step-c
      else
      {
        *(reinterpret_cast<P*>(&lds[256 * pack_size]) + 64 * (warp_id - 4) + lane_id) = ptrs[warp_id - 4][start + tid + stride];
      }
      __syncthreads();

      int steady = second_loop - 1; // second_loop is min
      for (int i = 0; i < steady; ++i)
      {
        // A run step-b and step-c, B run step-a
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + i * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
          // A run step-c
          *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid + (i + 1) * 2 * stride];
        }
        else
        {
          // B run step-a
          vmemload_cal_vmemstore<T, 4, 4>(&lds[256 * pack_size], warp_id, lane_id);
        }
        __syncthreads();
        // A run step-a, B run step-b, step-c
        if (warp_id < 4)
        {
          // A run step-a
          vmemload_cal_vmemstore<T, 4, 0>(&lds[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 4][start + tid + (i * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds[256 * pack_size]) + 64 * (warp_id - 4) + lane_id);
          // B run step-c
          *(reinterpret_cast<P*>(&lds[256 * pack_size]) + 64 * (warp_id - 4) + lane_id) = ptrs[warp_id - 4][start + tid + ((i + 1) * 2 + 1) * stride];
        }
        __syncthreads();
      }
      // epilogue
      if ((loop_time & 1) == 0) // B last
      {
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
        }
        else
        {
          // B run step-a
          vmemload_cal_vmemstore<T, 4, 4>(&lds[256 * pack_size], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id > 3)
        {
          // B run step-b
          tmps[warp_id - 4][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds[256 * pack_size]) + 64 * (warp_id - 4) + lane_id);
        }
      }
      else // A last
      {
        // A run step-b, step-c
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + steady * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
          // A run step-c
          *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid + (steady + 1) * 2 * stride];
        }
        else
        {
          // B run step-a
          vmemload_cal_vmemstore<T, 4, 4>(&lds[256 * pack_size], warp_id, lane_id);
        }
        __syncthreads();
        if (warp_id < 4)
        {
          // A run step-a
          vmemload_cal_vmemstore<T, 4, 0>(&lds[0], warp_id, lane_id);
        }
        else
        {
          // B run step-b
          tmps[warp_id - 4][start + tid + (steady * 2 + 1) * stride] = *(reinterpret_cast<P*>(&lds[256 * pack_size]) + 64 * (warp_id - 4) + lane_id);
        }
        __syncthreads();
        if (warp_id < 4)
        {
          // A run step-b
          tmps[warp_id][start + tid + (steady + 1) * 2 * stride] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
        }
      }
    }
    else
    {
      // loop_time == 1
      // c->a->b
      if (warp_id < 4)
      {
        *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id) = ptrs[warp_id][start + tid];
        __syncthreads();
        vmemload_cal_vmemstore<T, 4, 0>(&lds[0], warp_id, lane_id);
        __syncthreads();
        tmps[warp_id][start + tid] = *(reinterpret_cast<P*>(&lds[0]) + 64 * warp_id + lane_id);
      }
    }

    end_sync_asm<4, true, false>(sg, self_sg, rank);
    int dst_index;
    for (int i = 0; i < second_loop; ++i)
    {
      if (warp_id < 4)
      {
        dst_index = warp_id * part + tid + i * 2 * stride;
      }
      else
      {
        dst_index = (warp_id - 4) * part + tid + (i * 2 + 1) * stride;
      }
      *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
    }
    if ((loop_time & 1) == 0)
    {
      if (warp_id < 4)
      {
        dst_index = warp_id * part + tid + (loop_time - 1) * stride;
        *(reinterpret_cast<P*>(result) + dst_index) = tmp_out[dst_index];
      }
    }
}
// =============================================================================

template <typename T, int ngpus>
inline void launch_cross_device_reduce_2stage(RankData* in_dp,
                                              RankSignals sg,
                                              Signal* self_sg,
                                              T* result,
                                              int rank,
                                              int size_packed,
                                              int grid,
                                              hipStream_t stream,
                                              RankData* out_dp = nullptr) {
    cross_device_reduce_2stage<T, ngpus>
        <<<grid, kThreadNum2Stage, 0, stream>>>(in_dp, out_dp, sg, self_sg, result, rank, size_packed);
}

template <typename T, int ngpus>
inline void launch_car_wt(RankData* in_dp,
                          RankSignals sg,
                          Signal* self_sg,
                          T* result,
                          int rank,
                          int size_packed,
                          int grid,
                          hipStream_t stream,
                          RankData* out_dp = nullptr) {
    car_wt<T, ngpus>
        <<<grid, kThreadNum2Stage, 0, stream>>>(in_dp, out_dp, sg, self_sg, result, rank, size_packed);
}

constexpr int kThreadNumCarTp8 = 512;

template <typename T>
inline void launch_car_tp8(RankData* in_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* result,
                           int rank,
                           int size_packed,
                           int grid,
                           hipStream_t stream) {
    car_tp8<T><<<grid, kThreadNumCarTp8, 0, stream>>>(
        in_dp, sg, self_sg, result, rank, size_packed);
}

constexpr int kThreadNumAllreduceDB = 1024;

template <typename T>
inline void launch_allreduce_double_buffer(RankData* in_dp,
                                           RankSignals sg,
                                           Signal* self_sg,
                                           T* result,
                                           int rank,
                                           int size_packed,
                                           int grid,
                                           hipStream_t stream) {
    allreduce_double_buffer<T><<<grid, kThreadNumAllreduceDB, 0, stream>>>(
        in_dp, sg, self_sg, result, rank, size_packed);
}

constexpr int kThreadNumCarDbTp4 = 512;

template <typename T>
inline void launch_car_db_tp4(RankData* in_dp,
                              RankSignals sg,
                              Signal* self_sg,
                              T* result,
                              int rank,
                              int size_packed,
                              int grid,
                              hipStream_t stream) {
    car_db_tp4<T><<<grid, kThreadNumCarDbTp4, 0, stream>>>(
        in_dp, sg, self_sg, result, rank, size_packed);
}

template <typename T>
inline void launch_ar_naive_overlap(RankData* in_dp,
                                    RankSignals sg,
                                    Signal* self_sg,
                                    T* result,
                                    int rank,
                                    int size_packed,
                                    int grid,
                                    hipStream_t stream,
                                    RankData* out_dp = nullptr) {
    ar_naive_overlap<T><<<grid, kThreadNum2Stage, 0, stream>>>(
        in_dp, out_dp, sg, self_sg, result, rank, size_packed);
}

template <typename T>
inline void launch_ar_4wave_overlap(RankData* in_dp,
                                    RankSignals sg,
                                    Signal* self_sg,
                                    T* result,
                                    int rank,
                                    int size_packed,
                                    int grid,
                                    hipStream_t stream,
                                    RankData* out_dp = nullptr) {
    // 256-thread block, each thread handles 2x data, so grid matches the
    // 512-thread launchers' grid (no doubling needed).
    ar_4wave_overlap<T><<<grid, 256, 0, stream>>>(
        in_dp, out_dp, sg, self_sg, result, rank, size_packed);
}

// 256-thread block (tp4), 4 warps of 64 lanes: warps 0..3 each load a different
// remote rank into LDS, warp 0 reduces and stores. tnum_gpu = 64, same as
// car_db_tp4, so use the same grid (`grid_db`).
template <typename T>
inline void launch_ar_tp4_overlap(RankData* in_dp,
                                  RankSignals sg,
                                  Signal* self_sg,
                                  T* result,
                                  int rank,
                                  int size_packed,
                                  int grid,
                                  hipStream_t stream,
                                  RankData* out_dp = nullptr) {
    ar_tp4_overlap<T><<<grid, 256, 0, stream>>>(
        in_dp, out_dp, sg, self_sg, result, rank, size_packed);
}

// 320-thread block (tp4), 5 warps of 64 lanes: warps 0..3 load remote ranks,
// warp 4 does the reduce/store. tnum_gpu still = 64, so reuse `grid_db`.
template <typename T>
inline void launch_ar_tp4_5wave_overlap(RankData* in_dp,
                                        RankSignals sg,
                                        Signal* self_sg,
                                        T* result,
                                        int rank,
                                        int size_packed,
                                        int grid,
                                        hipStream_t stream,
                                        RankData* out_dp = nullptr) {
    ar_tp4_5wave_overlap<T><<<grid, 320, 0, stream>>>(
        in_dp, out_dp, sg, self_sg, result, rank, size_packed);
}

}  // namespace commkit::kernels
