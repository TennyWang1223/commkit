#pragma once

#include "commkit/signal.hpp"

namespace commkit {

#define COMMKIT_DINLINE __device__ __forceinline__

// Initial barrier across all ranks. No visibility guarantees on prior memory
// accesses are required, since this is the first sync of the kernel.
template <int ngpus>
COMMKIT_DINLINE void start_sync(const RankSignals& sg, Signal* self_sg, int rank) {
    uint32_t flag = self_sg->_flag[blockIdx.x] + 1;
    if (threadIdx.x < ngpus) {
        // Single peer-store per rank: latency = 1 p2p write.
        __scoped_atomic_store_n(&sg.signals[threadIdx.x]->start[blockIdx.x][rank],
                                flag,
                                __ATOMIC_RELAXED,
                                __MEMORY_SCOPE_SYSTEM);
        while (__scoped_atomic_load_n(&self_sg->start[blockIdx.x][threadIdx.x],
                                      __ATOMIC_RELAXED,
                                      __MEMORY_SCOPE_DEVICE) < flag)
            ;
    }
    __syncthreads();
    if (threadIdx.x == 0) {
        self_sg->_flag[blockIdx.x] = flag;
    }
}

template <int ngpus>
COMMKIT_DINLINE void ss(const RankSignals& sg, Signal* self_sg, int rank) {
    uint32_t flag = self_sg->_flag[blockIdx.x] + 1;
    if (threadIdx.x == 0)
    {
      uint32_t* addr = &self_sg->start[0][rank];
      uint32_t observed;
      asm volatile(
          "global_load_dword %0, %1, off nt\n\t"
          "s_waitcnt vmcnt(0)\n\t"
          : "=v"(observed) : "v"(addr) : "memory"
          );
      if (observed < flag)
      {
        asm volatile(
            "global_store_dword %0, %1, off nt\n\t"
            :: "v"(addr), "v"(flag) : "memory"
            );
      }
    }
    if (threadIdx.x < ngpus) {
        while (__scoped_atomic_load_n(&sg.signals[threadIdx.x]->start[0][threadIdx.x],
                                      __ATOMIC_RELAXED,
                                      __MEMORY_SCOPE_DEVICE) < flag)
            ;
    }
    __syncthreads();
    if (threadIdx.x == 0) {
        self_sg->_flag[blockIdx.x] = flag;
    }
}

template <int ngpus>
COMMKIT_DINLINE void start_sync_leader_once(const RankSignals& sg, Signal* self_sg, int rank) {
  // Plan 3: fix block 0 as the leader. No arrival_cnt race, no per-iter
  // counter to reset. Other blocks just spin on barrier_gen.
  uint32_t gen = self_sg->_flag[blockIdx.x] + 1;

  if (blockIdx.x == 0) {
    if (threadIdx.x < ngpus) {
      __scoped_atomic_store_n(&sg.signals[threadIdx.x]->start_g[rank], gen, __ATOMIC_RELAXED, __MEMORY_SCOPE_SYSTEM);
      while (__scoped_atomic_load_n(&self_sg->start_g[threadIdx.x], __ATOMIC_RELAXED, __MEMORY_SCOPE_DEVICE) < gen);
    }
    __syncthreads();
    if (threadIdx.x == 0) {
      __scoped_atomic_store_n(&self_sg->barrier_gen, gen, __ATOMIC_RELEASE, __MEMORY_SCOPE_DEVICE);
    }
  } else {
    if (threadIdx.x == 0) {
      while (
          __scoped_atomic_load_n(&self_sg->barrier_gen, __ATOMIC_ACQUIRE, __MEMORY_SCOPE_DEVICE) < gen
          );
    }
    __syncthreads();
  }
}

// Mid- or final-stage barrier. final_sync skips the visibility fence/release
// because no subsequent reads of peer-written data follow.
template <int ngpus, bool final_sync = false>
COMMKIT_DINLINE void end_sync(const RankSignals& sg, Signal* self_sg, int rank) {
    __syncthreads();
    uint32_t flag = self_sg->_flag[blockIdx.x] + 1;
    if (threadIdx.x < ngpus) {
        __scoped_atomic_store_n(&sg.signals[threadIdx.x]->end[blockIdx.x][rank],
                                flag,
                                final_sync ? __ATOMIC_RELAXED : __ATOMIC_RELEASE,
                                __MEMORY_SCOPE_SYSTEM);
        while (__scoped_atomic_load_n(&self_sg->end[blockIdx.x][threadIdx.x],
                                      final_sync ? __ATOMIC_RELAXED : __ATOMIC_ACQUIRE,
                                      __MEMORY_SCOPE_DEVICE) < flag)
            ;
    }
    __syncthreads();
    if (threadIdx.x == 0) {
        self_sg->_flag[blockIdx.x] = flag;
    }
}

template <int ngpus, bool wbl2 = true, bool inv = true>
COMMKIT_DINLINE void end_sync_asm(const RankSignals& sg, Signal* self_sg, int rank)
{
  // asm volatile ("s_waitcnt vmcnt(0)":::"memory");
  __syncthreads();
  uint32_t flag = self_sg->_flag[blockIdx.x] + 1;
  if (threadIdx.x < ngpus)
  {
    uint32_t* dst = &sg.signals[threadIdx.x]->end[blockIdx.x][rank];
    uint32_t* src = &self_sg->end[blockIdx.x][threadIdx.x];
    
    if constexpr (wbl2)
    {
      asm volatile(
          "buffer_wbl2 sc0 sc1\n\t"
          "global_store_dword %0, %1, off sc0 sc1\n\t"::"v"(dst), "v"(flag): "memory"
          );
    }
    else
    {
      asm volatile(
          "global_store_dword %0, %1, off sc0 sc1\n\t"::"v"(dst), "v"(flag): "memory"
          );
    }

    uint32_t observerd;
    do
    {
      if constexpr (inv)
      {
        asm volatile(
            "global_load_dword %0, %1, off sc1\n\t"
            "s_waitcnt vmcnt(0)\n\t"
            "buffer_inv sc1\n\t"
            : "=v"(observerd) : "v"(src): "memory"
            );
      }
      else
      {
        asm volatile(
            "global_load_dword %0, %1, off sc1\n\t"
            "s_waitcnt vmcnt(0)\n\t"
            : "=v"(observerd) : "v"(src): "memory"
            );
      }
    }
    while (observerd < flag);
  }
  __syncthreads();

  if (threadIdx.x == 0)
  {
    self_sg->_flag[blockIdx.x] = flag;
  }
}

}  // namespace commkit
