#pragma once

#include <hip/hip_runtime.h>

#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "opus/opus.hpp"

// =============================================================================
// Plain copy-based allgather (pull model) -- the "ordinary" baseline to compare
// against the LL-proto kernel. Mirrors aiter's allgather_vec: one start_sync
// barrier, then every rank directly reads each peer's owned slice and writes it
// into the right place in its local output. Single-pass, no in-line flag, no 2x
// FIFO traffic, no decode -- just a barrier + a vectorized peer read/local write.
//
// Layout matches ll_allgather: rank r owns [r*part, (r+1)*part) of a `size`-
// element buffer; after the collective every rank holds the full `size` elems.
// =============================================================================

namespace commkit::kernels {

constexpr int kThreadNumCopy = 512;  // THREAD_NUM in aiter allgather_vec

// copy_allgather: pull each peer's owned slice into result. warp group `w` reads
// peer w's slice (peer w's input at offset w*part) and writes result[w*part..].
template <typename T, int ngpus>
__global__ void __launch_bounds__(kThreadNumCopy, 1)
copy_allgather(RankData* _dp, RankSignals sg, Signal* self_sg,
               T* __restrict__ result, int rank, int size) {
    constexpr int pack_size = 16 / sizeof(T);
    using P = opus::vector_t<T, pack_size>;

    int part   = size / ngpus;          // elements each rank owns
    int ppart  = part / pack_size;      // packed elements per slice

    constexpr int tnum_gpu = kThreadNumCopy / ngpus;
    int warp_id = threadIdx.x / tnum_gpu;   // which peer this thread pulls from
    int lane_id = threadIdx.x % tnum_gpu;
    int tid     = blockIdx.x * tnum_gpu + lane_id;
    int stride  = gridDim.x * tnum_gpu;

    // Peer bases as packed pointers; peer i's own slice sits at i*ppart.
    const P* ptrs[ngpus];
#pragma unroll
    for (int i = 0; i < ngpus; ++i) {
        ptrs[i] = reinterpret_cast<const P*>(_dp->ptrs[i]) + i * ppart;
    }
    P* out = reinterpret_cast<P*>(result) + warp_id * ppart;

    start_sync<ngpus>(sg, self_sg, rank);

    for (int idx = tid; idx < ppart; idx += stride) {
        out[idx] = ptrs[warp_id][idx];
    }
}

template <typename T, int ngpus>
inline void launch_copy_allgather(RankData* dp, RankSignals sg, Signal* self_sg,
                                  T* result, int rank, int size, int grid,
                                  hipStream_t stream) {
    copy_allgather<T, ngpus>
        <<<grid, kThreadNumCopy, 0, stream>>>(dp, sg, self_sg, result, rank, size);
}

}  // namespace commkit::kernels
