#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "commkit/tmp_buf.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

// Two-stage all-reduce: stage 1 = reduce-scatter into the meta scratch tail
// (one shard per rank), stage 2 = all-gather from peers' scratch into the
// local output. Halves cross-device write traffic vs 1-stage at the cost of
// an extra peer barrier and scratch use.
//
// Ported from aiter's cross_device_reduce_2stage_naive
// (csrc/include/custom_all_reduce.cuh L306-362).
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1)
cross_device_reduce_2stage(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = gridDim.x * blockDim.x;
    using P = typename opus::vector_t<T, pack_size>;
    using A = typename opus::vector_t<opus::fp32_t, pack_size>;

    int part = size / ngpus;
    int start = rank * part;
    int end = (rank == ngpus - 1) ? size : start + part;
    int largest_part = part + size % ngpus;

    const P* ptrs[ngpus];
    P* tmps[ngpus];
#pragma unroll
    for (int i = 0; i < ngpus; ++i) {
        int target = (rank + i) % ngpus;
        ptrs[i] = reinterpret_cast<const P*>(_input_dp->ptrs[target]);
        tmps[i] = get_tmp_buf<P>(sg.signals[target]);
    }
    auto* tmp_out = tmps[0];

    start_sync<ngpus>(sg, self_sg, rank);

    // stage 1: reduce-scatter into local scratch shard
    for (int idx = start + tid; idx < end; idx += stride) {
        tmp_out[idx - start] = packed_reduce<P, ngpus, A>(ptrs, idx);
    }

    end_sync<ngpus>(sg, self_sg, rank);

    // stage 2: all-gather from peers' scratch into the local output
    for (int idx = tid; idx < largest_part; idx += stride) {
#pragma unroll
        for (int i = 0; i < ngpus; ++i) {
            int gather_from_rank = (rank + i) % ngpus;
            if (gather_from_rank == ngpus - 1 || idx < part) {
                int dst_idx = gather_from_rank * part + idx;
                reinterpret_cast<P*>(result)[dst_idx] = tmps[i][idx];
            }
        }
    }
}

template <typename T, int ngpus>
inline void launch_cross_device_reduce_2stage(RankData* in_dp,
                                              RankSignals sg,
                                              Signal* self_sg,
                                              T* result,
                                              int rank,
                                              int size_packed,
                                              int grid,
                                              hipStream_t stream) {
    cross_device_reduce_2stage<T, ngpus>
        <<<grid, 512, 0, stream>>>(in_dp, sg, self_sg, result, rank, size_packed);
}

}  // namespace commkit::kernels
