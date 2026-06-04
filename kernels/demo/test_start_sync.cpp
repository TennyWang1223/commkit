#include <cstdio>
#include <cstring>
#include <random>
#include <vector>

#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "opus/opus.hpp"
#include "start_sync_demo.cuh"

using T = opus::bf16_t;
constexpr int WORLD = 8;
constexpr int M = 4;
constexpr int K = 7168;
constexpr int N = M * K;

namespace ck = commkit::kernels;

int main() {
    commkit::CommGroup g(WORLD);
    g.init();

    // ---- Inputs identical for both variants on a given rank ----
    std::vector<T> host_in(N);
    std::mt19937_64 rng(42 + g.rank());
    std::uniform_real_distribution<float> dist(-1.f, 1.f);
    for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));

    T* in = static_cast<T*>(g.registered_input_ptr());
    COMMKIT_HIP_CALL(hipMemcpy(in, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));

    T* out_orig = nullptr;
    T* out_leader = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&out_orig,   N * sizeof(T)));
    COMMKIT_HIP_CALL(hipMalloc(&out_leader, N * sizeof(T)));

    constexpr int pack_size = 16 / sizeof(T);
    int size_packed = N / pack_size;
    int grid = std::min(commkit::kMaxBlocks, (size_packed + 511) / 512);
    auto* dp = g.rank_data(in);

    // ---------------- Correctness ----------------
    //
    // Run the *same* reduce kernel with two different start_sync variants on
    // identical inputs; outputs must match element-wise. This validates:
    //   * leader_once does not deadlock under repeated launches,
    //   * arrival_cnt reset (in end_sync_asm) leaves clean state for next call,
    //   * gen / barrier_gen progression stays consistent across grid blocks.
    if (g.rank() == 0) std::printf("\n[correctness]\n");

    constexpr int kCorrectIters = 50;
    for (int it = 0; it < kCorrectIters; ++it) {
        g.barrier();
        ck::reduce_1stage_with<T, WORLD, ck::StartSyncImpl::Original>
            <<<grid, 512, 0, g.stream()>>>(
                dp, g.rank_signals(), g.self_signal(), out_orig, g.rank(), size_packed);
        COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));

        g.barrier();
        ck::reduce_1stage_with<T, WORLD, ck::StartSyncImpl::LeaderOnce>
            <<<grid, 512, 0, g.stream()>>>(
                dp, g.rank_signals(), g.self_signal(), out_leader, g.rank(), size_packed);
        COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    }

    std::vector<T> h_orig(N), h_leader(N);
    COMMKIT_HIP_CALL(hipMemcpy(h_orig.data(),   out_orig,   N * sizeof(T), hipMemcpyDeviceToHost));
    COMMKIT_HIP_CALL(hipMemcpy(h_leader.data(), out_leader, N * sizeof(T), hipMemcpyDeviceToHost));

    int mismatches = 0;
    float max_abs_diff = 0.f;
    for (int i = 0; i < N; ++i) {
        float a = static_cast<float>(h_orig[i]);
        float b = static_cast<float>(h_leader[i]);
        float d = std::fabs(a - b);
        if (d > max_abs_diff) max_abs_diff = d;
        // bf16 round-trip through reduce should be bit-identical when the
        // reduction order is the same; both variants share the reduce loop.
        if (a != b) ++mismatches;
    }

    g.barrier();
    std::printf("  rank=%d  iters=%d  mismatches=%d  max_abs_diff=%.6f  %s\n",
                g.rank(), kCorrectIters, mismatches, max_abs_diff,
                mismatches == 0 ? "OK" : "FAIL");
    g.barrier();

    // ---------------- Latency ----------------
    //
    // Pair (start_sync, end_sync_asm) is the measurement unit; end_sync_asm is
    // identical across both, so per-iter delta = start_sync delta.
    constexpr int kIters = 1000;
    constexpr int kReps  = 10;

    auto bench = [&](ck::StartSyncImpl impl, int g_size, auto launch_fn) {
        // Warm up (also primes _flag).
        launch_fn();
        COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
        g.barrier();

        hipEvent_t start, stop;
        COMMKIT_HIP_CALL(hipEventCreate(&start));
        COMMKIT_HIP_CALL(hipEventCreate(&stop));

        float best_ms = 1e30f;
        for (int r = 0; r < kReps; ++r) {
            g.barrier();  // align cross-rank start
            COMMKIT_HIP_CALL(hipEventRecord(start, g.stream()));
            launch_fn();
            COMMKIT_HIP_CALL(hipEventRecord(stop, g.stream()));
            COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
            float ms = 0.f;
            COMMKIT_HIP_CALL(hipEventElapsedTime(&ms, start, stop));
            if (ms < best_ms) best_ms = ms;
        }

        COMMKIT_HIP_CALL(hipEventDestroy(start));
        COMMKIT_HIP_CALL(hipEventDestroy(stop));

        if (g.rank() == 0) {
            std::printf("  grid=%-3d  %-26s  %7.3f us/pair  (best of %d, iters=%d)\n",
                        g_size, ck::start_sync_impl_name(impl),
                        best_ms * 1000.0 / kIters, kReps, kIters);
        }
    };

    if (g.rank() == 0) {
        std::printf("\n[latency: (start_sync + end_sync_asm) pair]\n");
    }

    // Sweep a few grid sizes — leader_once's win should grow with gridDim.x
    // because it converts (gridDim.x) spin loops into 1.
    const int grids[] = {1, 4, 16, 40, std::min(80, commkit::kMaxBlocks)};

#define BENCH_PAIR(IMPL, G)                                                                  \
    bench(ck::StartSyncImpl::IMPL, (G), [&]() {                                              \
        ck::bench_start_sync<WORLD, ck::StartSyncImpl::IMPL, kIters>                         \
            <<<(G), 512, 0, g.stream()>>>(g.rank_signals(), g.self_signal(), g.rank());      \
    })

    for (int gs : grids) {
        BENCH_PAIR(Original,   gs);
        BENCH_PAIR(LeaderOnce, gs);
        if (g.rank() == 0) std::printf("\n");
    }

#undef BENCH_PAIR

    COMMKIT_HIP_CALL(hipFree(out_orig));
    COMMKIT_HIP_CALL(hipFree(out_leader));
    g.barrier();
    return 0;
}
