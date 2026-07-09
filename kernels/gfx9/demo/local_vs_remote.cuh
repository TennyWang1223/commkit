#pragma once

#include <hip/hip_runtime.h>

#include "commkit/signal.hpp"
#include "commkit/tmp_buf.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

// Single-wave, fully-serialized r/w for measuring UNLOADED single-op latency
// in ATT (not throughput). Each load/store is followed by `s_waitcnt vmcnt(0)`
// so the per-instruction cycle gap in the trace IS the round-trip time.
//
//   Phase 1: local r/w   — load `local_in[i]`,   store `local_out[i]`
//   Phase 2: remote r/w  — load peer's input,    store peer's tmp_buf (XGMI)
//
// Launch with grid=1, block=64 (1 wavefront) so XGMI is not saturated.
template <typename T>
__global__ void __launch_bounds__(64, 1) local_vs_remote_rw_demo(
    RankData* dp, RankSignals sg,
    T* local_in, T* local_out,
    int peer, int n_packed)
{
    constexpr int pack_size = 16 / sizeof(T);
    using P = typename opus::vector_t<T, pack_size>;

    P*       l_in  = reinterpret_cast<P*>(local_in);
    P*       l_out = reinterpret_cast<P*>(local_out);
    const P* r_in  = reinterpret_cast<const P*>(dp->ptrs[peer]);
    P*       r_out = get_tmp_buf<P>(sg.signals[peer]);

    int tid    = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = gridDim.x * blockDim.x;

    // ===== Phase 1: LOCAL read + LOCAL write (serialized) ===================
    for (int i = tid; i < n_packed; i += stride) {
        P x = l_in[i];
        asm volatile("s_waitcnt vmcnt(0)" ::: "memory");  // expose load RTT
        l_out[i] = x;
        asm volatile("s_waitcnt vmcnt(0)" ::: "memory");  // expose store RTT
    }
    __syncthreads();

    // Prime remote TLB / L2 with a forced load. Writing the load in inline asm
    // bypasses the compiler's dead-code elimination — `(void)warmup` on a
    // plain C++ load gets removed because the load itself has no side effects.
    {
        int4 dummy;
        asm volatile(
            "flat_load_dwordx4 %0, %1\n\t"
            "s_waitcnt vmcnt(0)\n\t"
            : "=v"(dummy) : "v"(r_in + tid) : "memory");
        (void)dummy;
    }
    __syncthreads();

    // ===== Phase 2: REMOTE read + REMOTE write (XGMI, serialized) ===========
    for (int i = tid; i < n_packed; i += stride) {
        P x = r_in[i];
        asm volatile("s_waitcnt vmcnt(0)" ::: "memory");  // expose XGMI load RTT
        r_out[i] = x;
        asm volatile("s_waitcnt vmcnt(0)" ::: "memory");  // expose XGMI store RTT
    }
}

}  // namespace commkit::kernels
