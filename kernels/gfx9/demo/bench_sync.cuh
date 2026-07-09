#pragma once

#include "sync_demo.cuh"

namespace commkit::kernels {

enum class SyncImpl : int {
    Ori,         // end_sync_ori<ngpus>            — compiler, acqrel, sc1 load
    OriRelaxed,  // end_sync_ori<ngpus, true>      — compiler, relaxed
    SystemLoad,  // end_sync_<ngpus>               — compiler, acqrel, sc0 sc1 load
    Asm,         // end_sync_asm<ngpus>            — hand-rolled, acqrel, sc1 load
    AsmRelOnly,  // end_sync_asm<ngpus, true, false> — hand-rolled, drop buffer_inv
};

inline const char* sync_impl_name(SyncImpl impl) {
    switch (impl) {
        case SyncImpl::Ori:        return "end_sync_ori<acqrel,dev-load>";
        case SyncImpl::OriRelaxed: return "end_sync_ori<relaxed>";
        case SyncImpl::SystemLoad: return "end_sync_<acqrel,sys-load>";
        case SyncImpl::Asm:        return "end_sync_asm<acqrel,dev-load>";
        case SyncImpl::AsmRelOnly: return "end_sync_asm<rel-only>";
    }
    return "?";
}

// Microbench kernel. No data work — just back-to-back end_sync calls — so the
// measured cost is the barrier itself. `Iters` is unrolled at constexpr time so
// the loop body is just one barrier per iter; the outer loop stays rolled
// (#pragma unroll 1) to keep code size bounded.
template <int ngpus, SyncImpl impl, int Iters>
__global__ void __launch_bounds__(512, 1)
bench_end_sync(RankSignals sg, Signal* self_sg, int rank) {
    #pragma unroll 1
    for (int i = 0; i < Iters; ++i) {
        if constexpr (impl == SyncImpl::Ori) {
            end_sync_ori<ngpus>(sg, self_sg, rank);
        } else if constexpr (impl == SyncImpl::OriRelaxed) {
            end_sync_ori<ngpus, true>(sg, self_sg, rank);
        } else if constexpr (impl == SyncImpl::SystemLoad) {
            end_sync_<ngpus>(sg, self_sg, rank);
        } else if constexpr (impl == SyncImpl::Asm) {
            end_sync_asm<ngpus>(sg, self_sg, rank);
        } else if constexpr (impl == SyncImpl::AsmRelOnly) {
            end_sync_asm<ngpus, true, false>(sg, self_sg, rank);
        }
    }
}

}  // namespace commkit::kernels
