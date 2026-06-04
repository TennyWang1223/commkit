#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

template <int ngpus, bool final_sync = false>
COMMKIT_DINLINE void end_sync_ori(const RankSignals& sg, Signal* self_sg, int rank) {
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

template <int ngpus, bool final_sync = false>
COMMKIT_DINLINE void end_sync_(const RankSignals& sg, Signal* self_sg, int rank) {
    __syncthreads();
    uint32_t flag = self_sg->_flag[blockIdx.x] + 1;
    if (threadIdx.x < ngpus) {
        __scoped_atomic_store_n(&sg.signals[threadIdx.x]->end[blockIdx.x][rank],
                                flag,
                                final_sync ? __ATOMIC_RELAXED : __ATOMIC_RELEASE,
                                __MEMORY_SCOPE_SYSTEM);
        while (__scoped_atomic_load_n(&self_sg->end[blockIdx.x][threadIdx.x],
                                      final_sync ? __ATOMIC_RELAXED : __ATOMIC_ACQUIRE,
                                      __MEMORY_SCOPE_SYSTEM) < flag)
            ;
    }
    __syncthreads();
    if (threadIdx.x == 0) {
        self_sg->_flag[blockIdx.x] = flag;
    }
}

// Hand-rolled asm variant. release_store and acquire_load are independent
// because buffer_inv lives inside the spin loop — saving it can dwarf the
// one-shot wbl2 cost when the spin runs many iterations.
//
// Scope choice:
//   store side -> sc0 sc1 (system) — peer GPU is the consumer.
//   load  side -> sc1     (device) — fine-grained signal alloc keeps MALL out,
//                                    so local L2 inv suffices when needed.
template <int ngpus, bool release_store = true, bool acquire_load = true>
COMMKIT_DINLINE void end_sync_asm_split(const RankSignals& sg, Signal* self_sg, int rank) {
    __syncthreads();
    uint32_t flag = self_sg->_flag[blockIdx.x] + 1;
    if (threadIdx.x < ngpus) {
        uint32_t* dst = &sg.signals[threadIdx.x]->end[blockIdx.x][rank];
        uint32_t* src = &self_sg->end[blockIdx.x][threadIdx.x];

        if constexpr (release_store) {
            asm volatile(
                "buffer_wbl2 sc0 sc1\n\t"
                "global_store_dword %0, %1, off sc0 sc1\n\t"
                : : "v"(dst), "v"(flag) : "memory");
        } else {
            asm volatile(
                "global_store_dword %0, %1, off sc0 sc1\n\t"
                : : "v"(dst), "v"(flag) : "memory");
        }

        if constexpr (acquire_load) {
            uint32_t observed;
            do {
                asm volatile(
                    "global_load_dword %0, %1, off sc1\n\t"
                    "s_waitcnt vmcnt(0)\n\t"
                    "buffer_inv sc1\n\t"
                    : "=v"(observed) : "v"(src) : "memory");
            } while (observed < flag);
        } else {
            // Drop buffer_inv; bypass cache via 'nt' on the load instead.
            // __builtin_nontemporal_load was tried but LICM eliminated the
            // entire spin (LLVM treats !nontemporal as "may be removed").
            // inline asm + "memory" clobber prevents that.
            uint32_t observed;
            do {
                asm volatile(
                    "global_load_dword %0, %1, off sc1 nt\n\t"
                    "s_waitcnt vmcnt(0)\n\t"
                    : "=v"(observed) : "v"(src) : "memory");
            } while (observed < flag);
        }
    }
    __syncthreads();
    if (threadIdx.x == 0) {
        self_sg->_flag[blockIdx.x] = flag;
    }
}


template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1)
cross_device_reduce_1stage(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    using P = typename opus::vector_t<T, pack_size>;
    using A = typename opus::vector_t<opus::fp32_t, pack_size>;

    auto dp = *_input_dp;
    start_sync<ngpus>(sg, self_sg, rank);
    for (int idx = blockIdx.x * blockDim.x + threadIdx.x;
         idx < size;
         idx += gridDim.x * blockDim.x) {
        reinterpret_cast<P*>(result)[idx] =
            packed_reduce<P, ngpus, A>(reinterpret_cast<const P**>(&dp.ptrs[0]), idx);
    }
    end_sync_ori<ngpus>(sg, self_sg, rank);
    end_sync_ori<ngpus, true>(sg, self_sg, rank);
    end_sync_<ngpus>(sg, self_sg, rank);
    end_sync_asm_split<ngpus>(sg, self_sg, rank);                  // baseline: release + acquire
    end_sync_asm_split<ngpus, true, false>(sg, self_sg, rank);     // release-only: keep wbl2, drop inv
}

}
