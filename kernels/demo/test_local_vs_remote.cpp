// Driver for `local_vs_remote_rw_demo`. Launches a single block / single wave
// so the ATT capture is one wavefront with two clearly demarcated phases:
//   Phase 1: local memory r/w
//   Phase 2: cross-device r/w over XGMI (read peer's input, write peer's tmp)
//
// Inspect the per-instruction cycle stamps in the ATT viewer; vmcnt(0) at the
// end of each phase marks the visible boundary.
//
// Run:  ./run.sh 8 ./test_local_vs_remote

#include <cstdio>
#include <random>
#include <vector>

#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "local_vs_remote.cuh"
#include "opus/opus.hpp"

using T = opus::bf16_t;

constexpr int WORLD    = 8;
// Fallback: 1 block per SE so whichever CU 0 ATT samples is guaranteed to
// host a wave. XGMI is still nowhere near saturated at this scale.
constexpr int GRID     = 8;
constexpr int BLOCK    = 64;          // 1 wavefront per block
constexpr int ITERS    = 16;          // r/w samples per thread (per phase)
constexpr int N_PACKED = GRID * BLOCK * ITERS;
constexpr int N_ELEMS  = N_PACKED * (16 / sizeof(T));

int main() {
    commkit::CommGroup g(WORLD);
    g.init();

    // local_in goes through the registered IPC pool so peers can read it.
    T* local_in = static_cast<T*>(g.registered_input_ptr());

    std::vector<T> host(N_ELEMS);
    std::mt19937_64 rng(42 + g.rank());
    std::uniform_real_distribution<float> dist(-1.f, 1.f);
    for (int i = 0; i < N_ELEMS; ++i) host[i] = static_cast<T>(dist(rng));
    COMMKIT_HIP_CALL(hipMemcpy(local_in, host.data(),
                               N_ELEMS * sizeof(T), hipMemcpyHostToDevice));

    T* local_out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&local_out, N_ELEMS * sizeof(T)));

    auto* dp   = g.rank_data(local_in);
    int   peer = (g.rank() + 1) % WORLD;

    auto launch = [&] {
        commkit::kernels::local_vs_remote_rw_demo<T><<<GRID, BLOCK, 0, g.stream()>>>(
            dp, g.rank_signals(), local_in, local_out, peer, N_PACKED);
    };

    // Warmup so the first launch's lazy paging / TLB fills aren't in the trace.
    launch();
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    g.barrier();

    // Steady-state launch the profiler should target.
    launch();
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    g.barrier();

    if (g.rank() == 0) {
        std::printf("[local_vs_remote_rw_demo] grid=%d block=%d iters=%d "
                    "(%d B / phase, single-wave serialized) world=%d\n",
                    GRID, BLOCK, ITERS, N_PACKED * 16, WORLD);
    }

    COMMKIT_HIP_CALL(hipFree(local_out));
    g.barrier();
    return 0;
}
