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
    constexpr int M = 64;
    constexpr int K = 7168;
    constexpr int N = M * K;

    commkit::CommGroup g(WORLD);
    g.init();

    // ---- One host-side random input shared by both modes ----
    std::vector<T> host_in(N);
    {
        std::mt19937_64 rng(42 + g.rank());
        std::uniform_real_distribution<float> dist(-1.f, 1.f);
        for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));
    }
    std::vector<float> my_in_f(N);
    for (int i = 0; i < N; ++i) my_in_f[i] = static_cast<float>(host_in[i]);
    auto ref = build_reference(g, my_in_f);

    T* out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&out, N * sizeof(T)));

    constexpr int pack_size = 16 / sizeof(T);
    int size_packed = N / pack_size;
    int per_rank = size_packed / WORLD;
    int grid = std::min(commkit::kMaxBlocks, (per_rank + 511) / 512);

    auto check_err = [&]() {
        std::vector<float> got;
        commkit::copy_to_host<T>(got, out, N);
        float e = 0.f;
        for (int i = 0; i < N; ++i) e = std::max(e, std::fabs(got[i] - ref[i]));
        return e;
    };

    // ---------- Eager: prev-layer output (D2D) -> IPC relay buffer -> kernel ----------
    T* prev_out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&prev_out, N * sizeof(T)));
    COMMKIT_HIP_CALL(
        hipMemcpy(prev_out, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));

    T* eager_in = static_cast<T*>(g.registered_input_ptr());
    auto* dp_eager = g.rank_data(eager_in);
    auto launch_eager = [&] {
        COMMKIT_HIP_CALL(hipMemcpyAsync(eager_in, prev_out, N * sizeof(T),
                                        hipMemcpyDeviceToDevice, g.stream()));
        commkit::kernels::launch_cross_device_reduce_2stage<T, WORLD>(
            dp_eager, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    launch_eager();
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    float err_eager = check_err();

    g.barrier();
    double lat_eager_us = commkit::bench_us(50, launch_eager, g.stream());
    g.barrier();

    // ---------- Graph: separate device buffer, register, capture, replay ----------
    T* graph_in = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&graph_in, N * sizeof(T)));
    COMMKIT_HIP_CALL(
        hipMemcpy(graph_in, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));
    g.register_input_buffer(graph_in);
    auto* dp_graph = g.rank_data(graph_in);
    auto launch_graph_kernel = [&] {
        commkit::kernels::launch_cross_device_reduce_2stage<T, WORLD>(
            dp_graph, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    g.begin_capture();
    hipGraph_t graph = nullptr;
    COMMKIT_HIP_CALL(hipStreamBeginCapture(g.stream(), hipStreamCaptureModeRelaxed));
    launch_graph_kernel();
    COMMKIT_HIP_CALL(hipStreamEndCapture(g.stream(), &graph));
    g.end_capture();

    hipGraphExec_t graph_exec = nullptr;
    COMMKIT_HIP_CALL(hipGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));

    auto replay = [&] { COMMKIT_HIP_CALL(hipGraphLaunch(graph_exec, g.stream())); };
    g.barrier();
    double lat_graph_us = commkit::bench_us(50, replay, g.stream());
    // Precision is taken from the final replay in the bench loop.
    COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
    float err_graph = check_err();
    g.barrier();

    std::printf("[allreduce_2stage bf16 shape=[%d,%d] world=%d grid=%d rank=%d] "
                "eager %.2f us (err=%.4g)  graph %.2f us (err=%.4g)\n",
                M, K, WORLD, grid, g.rank(),
                lat_eager_us, err_eager, lat_graph_us, err_graph);

    COMMKIT_HIP_CALL(hipGraphExecDestroy(graph_exec));
    COMMKIT_HIP_CALL(hipGraphDestroy(graph));
    COMMKIT_HIP_CALL(hipFree(graph_in));
    COMMKIT_HIP_CALL(hipFree(prev_out));
    COMMKIT_HIP_CALL(hipFree(out));
    g.barrier();
    return 0;
}
