#include <algorithm>
#include <cstdio>
#include <cstring>
#include <random>
#include <string>
#include <vector>

#include "commkit/bench.hpp"
#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"
#include "kernel.cuh"
#include "opus/opus.hpp"

using T = opus::bf16_t;

// Build the bitwise-identical reference: every rank uploads its host input to
// rank 0 via TCPStore, rank 0 sums elementwise, then broadcasts back. Each
// rank then takes its own shard of the sum.
static std::vector<float> build_reference_shard(commkit::CommGroup& g,
                                                const std::vector<float>& my_in_f,
                                                std::size_t shard_N,
                                                const std::string& tag) {
    int rank = g.rank(), W = g.world_size();
    std::size_t N = my_in_f.size();
    auto* store = g.store();
    std::string base = "ref/" + tag + "/" + std::to_string(N) + "/";

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

    std::vector<float> shard(shard_N);
    std::memcpy(shard.data(), sum.data() + rank * shard_N, shard_N * sizeof(float));
    return shard;
}

// Reduce per-rank latency to the max across all ranks via TCPStore. Only
// rank 0's return value is meaningful; other ranks get their own value back.
static double max_us_across_ranks(commkit::CommGroup& g, double my_us,
                                  const std::string& tag) {
    int rank = g.rank(), W = g.world_size();
    auto* store = g.store();
    std::string base = "bench/" + tag + "/";

    std::vector<uint8_t> bytes(sizeof(double));
    std::memcpy(bytes.data(), &my_us, sizeof(double));
    store->set(base + "r" + std::to_string(rank), bytes);

    double m = my_us;
    if (rank == 0) {
        for (int r = 0; r < W; ++r) {
            auto b = store->get(base + "r" + std::to_string(r));
            double v;
            std::memcpy(&v, b.data(), sizeof(double));
            if (v > m) m = v;
        }
    }
    g.barrier();
    return m;
}

int main() {
    constexpr int WORLD = 8;
    constexpr int K = 7168;
    const int Ms[] = {2, 4, 8, 16, 32, 64, 128, 256, 512};

    commkit::CommGroup g(WORLD);
    g.init();

    constexpr int pack_size = 16 / sizeof(T);

    if (g.rank() == 0) {
        std::printf("\n[reduce_scatter bf16 K=%d world=%d] (latency = max across %d ranks)\n",
                    K, WORLD, WORLD);
        std::printf("%-6s %-14s %-12s %-12s %-6s %-14s %-12s\n",
                    "M", "in_shape", "in_bytes", "out_bytes", "grid", "latency_us", "max_err");
        std::printf("%-6s %-14s %-12s %-12s %-6s %-14s %-12s\n",
                    "----", "------------", "----------", "----------", "----", "----------", "--------");
    }

    for (int M : Ms) {
        const int N = M * K;
        const int OUT_N = N / WORLD;
        const int range_packed = OUT_N / pack_size;
        const int grid = std::min(commkit::kMaxBlocks, (range_packed + 511) / 512);
        const std::string tag = "M" + std::to_string(M);

        // ---- One host-side random input per (rank, M) ----
        std::vector<T> host_in(N);
        {
            std::mt19937_64 rng(42 + g.rank() + uint64_t(M) * 1000);
            std::uniform_real_distribution<float> dist(-1.f, 1.f);
            for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));
        }
        std::vector<float> my_in_f(N);
        for (int i = 0; i < N; ++i) my_in_f[i] = static_cast<float>(host_in[i]);
        auto ref = build_reference_shard(g, my_in_f, OUT_N, tag);

        T* out = nullptr;
        COMMKIT_HIP_CALL(hipMalloc(&out, OUT_N * sizeof(T)));

        // ---- Eager: prev-layer output (D2D) -> IPC relay buffer -> kernel ----
        T* prev_out = nullptr;
        COMMKIT_HIP_CALL(hipMalloc(&prev_out, N * sizeof(T)));
        COMMKIT_HIP_CALL(
            hipMemcpy(prev_out, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));

        T* eager_in = static_cast<T*>(g.registered_input_ptr());
        auto* dp_eager = g.rank_data(eager_in);
        auto launch_eager = [&] {
            COMMKIT_HIP_CALL(hipMemcpyAsync(eager_in, prev_out, N * sizeof(T),
                                            hipMemcpyDeviceToDevice, g.stream()));
            commkit::kernels::launch_reduce_scatter_first_dim<T, WORLD>(
                dp_eager, g.rank_signals(), g.self_signal(), out,
                g.rank(), range_packed, grid, g.stream());
        };

        launch_eager();
        COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));

        std::vector<float> got;
        commkit::copy_to_host<T>(got, out, OUT_N);
        float err = 0.f;
        for (int i = 0; i < OUT_N; ++i) err = std::max(err, std::fabs(got[i] - ref[i]));

        g.barrier();
        double my_us = commkit::bench_us(50, launch_eager, g.stream());
        g.barrier();

        double max_us = max_us_across_ranks(g, my_us, tag);

        if (g.rank() == 0) {
            char in_shape[32];
            std::snprintf(in_shape, sizeof(in_shape), "[%d,%d]", M, K);
            std::printf("%-6d %-14s %-12zu %-12zu %-6d %-14.2f %-12.4g\n",
                        M, in_shape,
                        std::size_t(N) * sizeof(T),
                        std::size_t(OUT_N) * sizeof(T),
                        grid, max_us, err);
        }

        COMMKIT_HIP_CALL(hipFree(prev_out));
        COMMKIT_HIP_CALL(hipFree(out));
        g.barrier();
    }

    return 0;
}
