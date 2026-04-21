#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

// Reduce-scatter along the first dim. Each rank reads its own shard
// [rank * range, (rank + 1) * range) (in packed units) from every peer's
// input, sums them, and writes range packed elements to the local output.
//
// `range` is in packed units (P = 16/sizeof(T) elements). Caller must ensure
// total element count is divisible by pack_size * ngpus.
//
// Ported from aiter's reduce_scatter_first_dim
// (csrc/include/custom_all_reduce.cuh L774-799).
template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1)
reduce_scatter_first_dim(RankData* _input_dp,
                         RankSignals sg,
                         Signal* self_sg,
                         T* __restrict__ result,
                         int rank,
                         int range) {
    constexpr int pack_size = 16 / sizeof(T);
    using P = typename opus::vector_t<T, pack_size>;
    using A = typename opus::vector_t<opus::fp32_t, pack_size>;

    const P* ptrs[ngpus];
#pragma unroll
    for (int i = 0; i < ngpus; ++i) {
        int target = (rank + i) % ngpus;
        ptrs[i] = reinterpret_cast<const P*>(_input_dp->ptrs[target]);
    }

    start_sync<ngpus>(sg, self_sg, rank);

    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int idx = tid; idx < range; idx += stride) {
        int load_index = rank * range + idx;
        reinterpret_cast<P*>(result)[idx] =
            packed_reduce<P, ngpus, A>(ptrs, load_index);
    }
}

template <typename T, int ngpus>
inline void launch_reduce_scatter_first_dim(RankData* in_dp,
                                            RankSignals sg,
                                            Signal* self_sg,
                                            T* result,
                                            int rank,
                                            int range_packed,
                                            int grid,
                                            hipStream_t stream) {
    reduce_scatter_first_dim<T, ngpus>
        <<<grid, 512, 0, stream>>>(in_dp, sg, self_sg, result, rank, range_packed);
}

}  // namespace commkit::kernels
