#include <cstdio>
#include <cstring>
#include <random>
#include <vector>

#include "bench_sync.cuh"
#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "sync_demo.cuh"
#include "opus/opus.hpp"

using T = opus::bf16_t;
constexpr int WORLD = 8;
constexpr int M = 4;
constexpr int K = 7168;
constexpr int N = M * K;

int main() {
    commkit::CommGroup g(WORLD);
    g.init();

    std::vector<T> host_in(N);
    std::mt19937_64 rng(42 + g.rank());
    std::uniform_real_distribution<float> dist(-1.f, 1.f);
    for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));

    T* in = static_cast<T*>(g.registered_input_ptr());
    COMMKIT_HIP_CALL(hipMemcpy(in, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));

    T* out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&out, N * sizeof(T)));

    constexpr int pack_size = 16 / sizeof(T);
    int size_packed = N / pack_size;
    int grid = std::min(commkit::kMaxBlocks, (size_packed + 511) / 512);

    auto* dp = g.rank_data(in);
    commkit::kernels::cross_device_reduce_1stage<T, WORLD>
        <<<grid, 512, 0, g.stream()>>>(
            dp, g.rank_signals(), g.self_signal(), out, g.rank(), size_packed);
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));

    std::printf("[sync_demo bf16 N=%d world=%d grid=%d rank=%d] launched\n",
                N, WORLD, grid, g.rank());

    // ---------------- end_sync microbench ----------------
    constexpr int kIters = 1000;
    constexpr int kReps  = 10;

    auto bench = [&](commkit::kernels::SyncImpl impl, auto launch_fn) {
        // Warm up (also primes the spin loop's flag counter).
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
            std::printf("  %-36s  %7.3f us/sync  (best of %d, iters=%d, grid=%d)\n",
                        commkit::kernels::sync_impl_name(impl),
                        best_ms * 1000.0 / kIters, kReps, kIters, grid);
        }
    };

    if (g.rank() == 0) std::printf("\n[end_sync microbench]\n");

#define BENCH(IMPL)                                                                          \
    bench(commkit::kernels::SyncImpl::IMPL, [&]() {                                          \
        commkit::kernels::bench_end_sync<WORLD, commkit::kernels::SyncImpl::IMPL, kIters>    \
            <<<grid, 512, 0, g.stream()>>>(g.rank_signals(), g.self_signal(), g.rank());     \
    })

    BENCH(Ori);
    BENCH(OriRelaxed);
    BENCH(SystemLoad);
    BENCH(Asm);
    BENCH(AsmRelOnly);

#undef BENCH

    COMMKIT_HIP_CALL(hipFree(out));
    g.barrier();
    return 0;
}
