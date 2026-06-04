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
constexpr int WORLD = 8;

// Sweep block-count to study its effect on cross-device communication kernels.
// Default = kMaxBlocks (80, fully populated); limited cases sweep this list.
static const std::vector<int> kGridSweep = {16, 24, 32, 40, 48, 56, 64};

static std::vector<float> build_reference(commkit::CommGroup& g,
                                          const std::vector<float>& my_in_f,
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
    return sum;
}

static void run_shape(commkit::CommGroup& g, int M, int K) {
    const int N = M * K;
    constexpr int pack_size = 16 / sizeof(T);
    const int size_packed = N / pack_size;
    const int grid_full = commkit::kMaxBlocks;  // 80

    std::vector<T> host_in(N);
    {
        std::mt19937_64 rng(42 + g.rank() + M * 131);
        std::uniform_real_distribution<float> dist(-1.f, 1.f);
        for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));
    }
    std::vector<float> my_in_f(N);
    for (int i = 0; i < N; ++i) my_in_f[i] = static_cast<float>(host_in[i]);
    auto ref = build_reference(g, my_in_f, "shape" + std::to_string(M));

    T* out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&out, N * sizeof(T)));

    auto check_err = [&]() {
        std::vector<float> got;
        commkit::copy_to_host<T>(got, out, N);
        float e = 0.f;
        for (int i = 0; i < N; ++i) e = std::max(e, std::fabs(got[i] - ref[i]));
        return e;
    };

    // Eager-mode: prev-layer output (D2D) -> registered IPC relay buffer -> kernel.
    T* prev_out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&prev_out, N * sizeof(T)));
    COMMKIT_HIP_CALL(
        hipMemcpy(prev_out, host_in.data(), N * sizeof(T), hipMemcpyHostToDevice));

    T* eager_in = static_cast<T*>(g.registered_input_ptr());
    auto* dp_eager = g.rank_data(eager_in);

    auto bench_kernel = [&](const char* name, auto kernel_call, int grid) {
        auto launch = [&] {
            COMMKIT_HIP_CALL(hipMemcpyAsync(eager_in, prev_out, N * sizeof(T),
                                            hipMemcpyDeviceToDevice, g.stream()));
            kernel_call(grid);
        };

        launch();
        COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
        float err = check_err();
        g.barrier();

        double lat = commkit::bench_us(50, launch, g.stream());
        g.barrier();

        std::printf("[%-8s bf16 shape=[%d,%d] world=%d grid=%-3d rank=%d] "
                    "eager %.2f us (err=%.4g)\n",
                    name, M, K, WORLD, grid, g.rank(), lat, err);
    };

    auto call_2stage = [&](int grid) {
        commkit::kernels::launch_cross_device_reduce_2stage<T, WORLD>(
            dp_eager, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };
    auto call_car_tp8 = [&](int grid) {
        commkit::kernels::launch_car_tp8<T>(
            dp_eager, g.rank_signals(), g.self_signal(), out,
            g.rank(), size_packed, grid, g.stream());
    };

    auto separator = [&](const char* title) {
        g.barrier();
        if (g.rank() == 0) {
            std::printf("---- %s ----\n", title);
            std::fflush(stdout);
        }
        g.barrier();
    };

    auto sweep = [&](const char* name, auto kernel_call) {
        bench_kernel(name, kernel_call, grid_full);  // default: fully populated
        for (int grid : kGridSweep) {
            separator("");
            bench_kernel(name, kernel_call, grid);
        }
    };

    sweep("2stage",  call_2stage);
    separator("");
    if (g.rank() == 0) std::printf("\n");
    sweep("car_tp8", call_car_tp8);

    COMMKIT_HIP_CALL(hipFree(prev_out));
    COMMKIT_HIP_CALL(hipFree(out));
    g.barrier();
}

static void shape_banner(commkit::CommGroup& g, int M, int K) {
    g.barrier();
    if (g.rank() == 0) {
        std::printf("\n================ shape=[%d,%d] ================\n", M, K);
        std::fflush(stdout);
    }
    g.barrier();
}

int main() {
    commkit::CommGroup g(WORLD);
    g.init();

    shape_banner(g, 256, 8192);
    run_shape(g, 256, 8192);
    shape_banner(g, 512, 8192);
    run_shape(g, 512, 8192);

    return 0;
}
