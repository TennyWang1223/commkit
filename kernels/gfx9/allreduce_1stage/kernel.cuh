#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

// Single-stage all-reduce. Each rank reads all peers' inputs in parallel and
// reduces locally — no scratch buffer, no second exchange. Bandwidth-bound,
// best for small messages and high-bandwidth interconnects (XGMI, NVLink).
//
// Ported from aiter's cross_device_reduce_1stage_naive
// (csrc/include/custom_all_reduce.cuh L268-292).
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
    end_sync<ngpus, /*final_sync=*/true>(sg, self_sg, rank);
}

// Direct launch wrapper. Caller picks grid; block is fixed at 512 to match
// __launch_bounds__. `size` is in packed units (P = 16/sizeof(T) elements).
template <typename T, int ngpus>
inline void launch_cross_device_reduce_1stage(RankData* in_dp,
                                              RankSignals sg,
                                              Signal* self_sg,
                                              T* result,
                                              int rank,
                                              int size_packed,
                                              int grid,
                                              hipStream_t stream) {
    cross_device_reduce_1stage<T, ngpus>
        <<<grid, 512, 0, stream>>>(in_dp, sg, self_sg, result, rank, size_packed);
}

}  // namespace commkit::kernels
