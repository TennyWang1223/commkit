// Test for ATT (advanced thread trace) capture.
// Only one kernel runs in the steady-state loop; pick which by editing
// `selected` below to one of the call_xxx lambdas defined in main().
//
// Steady-state loop count is kATTIters; matches kernel_iteration_range in
// input.yaml (set it to capture a couple of mid-loop iters).
//
// Run:  ./run.sh 8 ./test_allreduce_2stage_att
// Capture: rocprof / rocprofv3 with input.yaml as usual.

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <random>
#include <vector>

#include "commkit/bench.hpp"
#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"
#include "kernel.cuh"
#include "opus/opus.hpp"

using T = opus::bf16_t;

constexpr int WORLD     = 8;
constexpr int M         = 64;
constexpr int K         = 8192;
constexpr int N         = M * K;
constexpr int kATTIters = 8;   // steady-state launches captured by ATT

int main() {
    commkit::CommGroup g(WORLD);
    g.init();

    // ---- Inputs ----
    std::vector<T> host_in(N);
    {
        std::mt19937_64 rng(42 + g.rank());
        std::uniform_real_distribution<float> dist(-1.f, 1.f);
        for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));
    }

    T* graph_in = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&graph_in, N * sizeof(T)));
    COMMKIT_HIP_CALL(
        hipMemcpy(graph_in, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));
    g.register_input_buffer(graph_in);
    auto* dp = g.rank_data(graph_in);

    T* out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&out, N * sizeof(T)));

    constexpr int pack_size   = 16 / sizeof(T);
    const int     size_packed = N / pack_size;
    const int     per_rank    = size_packed / WORLD;
    const int     grid        = std::min(commkit::kMaxBlocks, (per_rank + 511) / 512);
    const int     grid_db     = std::min(commkit::kMaxBlocks, grid * 2);

    // -------------------------------------------------------------------------
    // Per-kernel call wrappers. Each one is a no-arg lambda that issues a
    // single kernel launch on g.stream(). Pick one and assign to `selected`
    // below.
    // -------------------------------------------------------------------------
    auto call_cross_device_reduce_2stage = [&] {
        commkit::kernels::launch_cross_device_reduce_2stage<T, WORLD>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    auto call_car_wt = [&] {
        commkit::kernels::launch_car_wt<T, WORLD>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    auto call_car_tp8 = [&] {
        commkit::kernels::launch_car_tp8<T>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid_db, g.stream());
    };

    auto call_allreduce_double_buffer = [&] {
        commkit::kernels::launch_allreduce_double_buffer<T>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    auto call_ar_naive_overlap = [&] {
        commkit::kernels::launch_ar_naive_overlap<T>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    auto call_ar_4wave_overlap = [&] {
        commkit::kernels::launch_ar_4wave_overlap<T>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    // === pick one ===========================================================
    // auto selected      = call_cross_device_reduce_2stage;
    // const char* picked = "cross_device_reduce_2stage";
    auto selected      = call_ar_naive_overlap;
    const char* picked = "ar_naive_overlap";
    // auto selected      = call_ar_4wave_overlap;
    // const char* picked = "ar_4wave_overlap";
    // auto selected      = call_wt;
    // const char* picked = "car_wt";
    // ========================================================================

    // ---- One untimed warmup so any lazy init is out of the trace ----
    selected();
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    g.barrier();

    if (g.rank() == 0) {
        std::printf("[att] kernel=%s shape=[%d,%d] world=%d grid=%d iters=%d\n",
                    picked, M, K, WORLD, grid, kATTIters);
    }

    // ---- Steady-state loop captured by ATT ----
    for (int i = 0; i < kATTIters; ++i) {
        selected();
    }
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    g.barrier();

    COMMKIT_HIP_CALL(hipFree(graph_in));
    COMMKIT_HIP_CALL(hipFree(out));
    g.barrier();
    return 0;
}
