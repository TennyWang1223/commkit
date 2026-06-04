#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

enum class StartSyncImpl : int {
    Original,    // start_sync<ngpus>
    LeaderOnce,  // start_sync_leader_once<ngpus>
};

inline const char* start_sync_impl_name(StartSyncImpl impl) {
    switch (impl) {
        case StartSyncImpl::Original:   return "start_sync";
        case StartSyncImpl::LeaderOnce: return "start_sync_leader_once";
    }
    return "?";
}

// ---------------- Correctness: same reduce_1stage, two start_sync variants ----------------
//
// Drop-in copy of cross_device_reduce_1stage; only the leading barrier is templated.
// end_sync_asm is reused as-is (it also resets arrival_cnt at line 138, which the
// leader-once variant relies on for the next launch).
template <typename T, int ngpus, StartSyncImpl impl>
__global__ void __launch_bounds__(512, 1)
reduce_1stage_with(RankData* _input_dp,
                   RankSignals sg,
                   Signal* self_sg,
                   T* __restrict__ result,
                   int rank,
                   int size) {
    constexpr int pack_size = 16 / sizeof(T);
    using P = typename opus::vector_t<T, pack_size>;
    using A = typename opus::vector_t<opus::fp32_t, pack_size>;

    auto dp = *_input_dp;

    if constexpr (impl == StartSyncImpl::Original) {
        start_sync<ngpus>(sg, self_sg, rank);
    } else {
        start_sync_leader_once<ngpus>(sg, self_sg, rank);
    }

    for (int idx = blockIdx.x * blockDim.x + threadIdx.x;
         idx < size;
         idx += gridDim.x * blockDim.x) {
        reinterpret_cast<P*>(result)[idx] =
            packed_reduce<P, ngpus, A>(reinterpret_cast<const P**>(&dp.ptrs[0]), idx);
    }
    end_sync_asm<ngpus>(sg, self_sg, rank);
}

// ---------------- Latency: back-to-back (start_sync, end_sync_asm) pairs ----------------
//
// The pair is the unit of measurement because:
//  * start_sync_leader_once depends on end_sync_asm to reset arrival_cnt
//    between iterations (otherwise arrival_cnt grows unboundedly and no block
//    is ever leader after the first one).
//  * start_sync also bumps _flag at end (same as end_sync_asm), so back-to-back
//    pairs are state-consistent across iterations.
// Both impls share the *same* end_sync_asm tail, so any per-iter delta is the
// start_sync delta.
template <int ngpus, StartSyncImpl impl, int Iters>
__global__ void __launch_bounds__(512, 1)
bench_start_sync(RankSignals sg, Signal* self_sg, int rank) {
    #pragma unroll 1
    for (int i = 0; i < Iters; ++i) {
        if constexpr (impl == StartSyncImpl::Original) {
            start_sync<ngpus>(sg, self_sg, rank);
        } else {
            start_sync_leader_once<ngpus>(sg, self_sg, rank);
        }
        end_sync_asm<ngpus>(sg, self_sg, rank);
    }
}

}  // namespace commkit::kernels
