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

}  // namespace commkit
