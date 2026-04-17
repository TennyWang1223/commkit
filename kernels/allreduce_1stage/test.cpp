#include <algorithm>
#include <cstdio>
#include <cstring>
#include <vector>

#include "commkit/bench.hpp"
#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"
#include "kernel.cuh"
#include "opus/opus.hpp"

using T = opus::bf16_t;

// Build the bitwise-identical reference: every rank uploads its host input to
// rank 0 via TCPStore, rank 0 sums elementwise, then broadcasts back. Every
// rank's output should match this sum (custom_all_reduce is bitwise-identical
// regardless of starting rank).
static std::vector<float> build_reference(commkit::CommGroup& g,
                                          const std::vector<float>& my_in_f) {
    int rank = g.rank(), W = g.world_size();
    std::size_t N = my_in_f.size();
    auto* store = g.store();
    std::string base = "ref/" + std::to_string(N) + "/";

    std::vector<uint8_t> my_bytes(N * sizeof(float));
    std::memcpy(my_bytes.data(), my_in_f.data(), my_bytes.size());
    store->set(base + "in/r" + std::to_string(rank), my_bytes);

    std::vector<float> sum(N, 0.f);
    if (rank == 0) {
        for (int r = 0; r < W; ++r) {
            auto bytes = store->get(base + "in/r" + std::to_string(r));
            const float* ptr = reinterpret_cast<const float*>(bytes.data());
            for (std::size_t i = 0; i < N; ++i) sum[i] += ptr[i];
        }
        std::vector<uint8_t> sum_bytes(N * sizeof(float));
        std::memcpy(sum_bytes.data(), sum.data(), sum_bytes.size());
        store->set(base + "sum", sum_bytes);
    } else {
        auto bytes = store->get(base + "sum");
        std::memcpy(sum.data(), bytes.data(), bytes.size());
    }
    g.barrier();
    return sum;
}

int main() {
    constexpr int WORLD = 8;
    constexpr int N = 1 << 20;  // 1M bf16 elements per rank

    commkit::CommGroup g(WORLD);
    g.init();

    // Use the pre-registered "input" relay buffer as the kernel input.
    T* in = static_cast<T*>(g.registered_input_ptr());
    T* out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&out, N * sizeof(T)));

    // Fill host input, mirror to device, also keep a float copy for the ref.
    commkit::fill_random<T>(in, N, /*seed=*/42 + g.rank());
    std::vector<float> my_in_f;
    commkit::copy_to_host<T>(my_in_f, in, N);

    auto ref = build_reference(g, my_in_f);

    // ---- Direct launch — no dispatch ----
    constexpr int pack_size = 16 / sizeof(T);
    int size_packed = N / pack_size;
    int grid = std::min(commkit::kMaxBlocks, (size_packed + 511) / 512);

    auto* dp = g.rank_data(in);
    auto launch = [&] {
        commkit::kernels::launch_cross_device_reduce_1stage<T, WORLD>(
            dp, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    // Correctness pass
    launch();
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));

    std::vector<float> got;
    commkit::copy_to_host<T>(got, out, N);

    float max_err = 0.f;
    for (std::size_t i = 0; i < (std::size_t)N; ++i) {
        max_err = std::max(max_err, std::fabs(got[i] - ref[i]));
    }

    g.barrier();

    // Latency
    double lat_us = commkit::bench_us(50, launch, g.stream());

    std::printf("[allreduce_1stage bf16 N=%d world=%d grid=%d rank=%d] %.2f us  max_abs_err=%.4g\n",
                N, WORLD, grid, g.rank(), lat_us, max_err);

    COMMKIT_HIP_CALL(hipFree(out));
    g.barrier();
    return 0;
}
