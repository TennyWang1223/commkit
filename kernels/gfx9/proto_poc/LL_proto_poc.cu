#include <algorithm>
#include <array>
#include <cstdio>
#include <cstring>
#include <random>
#include <vector>

#include "commkit/bench.hpp"
#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"
#include "copy_allgather.cuh"
#include "ll_allgather.cuh"
#include "opus/opus.hpp"

using T = opus::bf16_t;

// Build the allgather reference on the host: gather every rank's owned slice
// [r*part, (r+1)*part) into one full `size`-element vector, identical on all
// ranks. Uses the TCP store to exchange slices.
static std::vector<float> build_reference(commkit::CommGroup& g,
                                          const std::vector<float>& my_full,
                                          int part) {
    int rank = g.rank(), W = g.world_size();
    auto* store = g.store();
    std::string base = "llag/" + std::to_string(my_full.size()) + "/";

    // Publish only my owned slice.
    std::vector<uint8_t> mine(part * sizeof(float));
    std::memcpy(mine.data(), my_full.data() + rank * part, mine.size());
    store->set(base + "slice/r" + std::to_string(rank), mine);

    std::vector<float> full(my_full.size(), 0.f);
    for (int r = 0; r < W; ++r) {
        auto bytes = store->get(base + "slice/r" + std::to_string(r));
        std::memcpy(full.data() + r * part, bytes.data(), bytes.size());
    }
    g.barrier();
    return full;
}

int main() {
    constexpr int WORLD = 8;
    constexpr int K = 7168;
    constexpr int EPL = 8 / sizeof(T);           // elts per LL line
    const int M_list[] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024};

    commkit::CommGroup g(WORLD);
    g.init();

    if (g.rank() == 0) {
        std::printf("# allgather bf16, world=%d, n=%d, 50-iter mean (us)\n", WORLD, K);
        std::printf("# %6s | %10s %10s | %10s %10s | %8s %8s\n",
                    "m", "LL-eager", "LL-graph", "cp-eager", "cp-graph",
                    "err_LL", "err_cp");
    }

    // Allocate the graph-path input and the output once at the largest shape and
    // reuse across all M. A per-shape hipMalloc of a tiny external buffer (e.g.
    // M=1 -> 14KB) fails VMM dmabuf import (hipMemAddressReserve invalid arg):
    // the allocation is smaller than the VMM page granularity. Registering one
    // max-size buffer once also avoids re-exchanging IPC handles every shape.
    int M_max = 0;
    for (int m : M_list) M_max = std::max(M_max, m);
    const int N_max = M_max * K;
    T* graph_in = nullptr;
    T* out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&graph_in, N_max * sizeof(T)));
    COMMKIT_HIP_CALL(hipMalloc(&out, N_max * sizeof(T)));
    g.register_input_buffer(graph_in);
    auto* dp_graph = g.rank_data(graph_in);

    for (int M : M_list) {
        const int N = M * K;
        const int part = N / WORLD;
        // LL needs whole 16B lines; copy needs whole 16B packs per slice.
        constexpr int pack = 16 / sizeof(T);
        if ((N % (WORLD * EPL)) != 0 || (part % pack) != 0) {
            if (g.rank() == 0)
                std::printf("# skip m=%d (not divisible)\n", M);
            continue;
        }

        // Per-rank input: fill whole buffer, only own slice is authoritative.
        std::vector<T> host_in(N);
        {
            std::mt19937_64 rng(1000 + g.rank() + static_cast<uint64_t>(M) * 7919);
            std::uniform_real_distribution<float> dist(-1.f, 1.f);
            for (int i = 0; i < N; ++i) host_in[i] = static_cast<T>(dist(rng));
        }
        std::vector<float> my_full_f(N);
        for (int i = 0; i < N; ++i) my_full_f[i] = static_cast<float>(host_in[i]);
        auto ref = build_reference(g, my_full_f, part);

        auto check_err = [&]() {
            std::vector<float> got;
            commkit::copy_to_host<T>(got, out, N);
            float e = 0.f;
            for (int i = 0; i < N; ++i) e = std::max(e, std::fabs(got[i] - ref[i]));
            return e;
        };
        auto clear_out = [&]() { COMMKIT_HIP_CALL(hipMemset(out, 0, N * sizeof(T))); };

        // LL grid sized on FIFO lines; copy grid sized on packed elems/slice.
        int seg_lines = part / EPL;
        int ll_grid = std::max(1, std::min(commkit::kMaxBlocks,
                     (seg_lines + commkit::kernels::kThreadNumLL - 1) /
                         commkit::kernels::kThreadNumLL));
        constexpr int cp_tng = commkit::kernels::kThreadNumCopy / WORLD;
        int cp_grid = std::max(1, std::min(commkit::kMaxBlocks,
                     (part / pack + cp_tng - 1) / cp_tng));

        // LL cold-start: zero Signal header + all FIFO slots (garbage flag==1
        // would be accepted as a valid line; garbage ll_epoch desyncs flags).
        {
            void* head = static_cast<void*>(g.self_signal());
            size_t fifo_bytes = static_cast<size_t>(WORLD) * seg_lines *
                                sizeof(commkit::kernels::LLFifoLine) *
                                commkit::kernels::kLLFifoSlots;
            COMMKIT_HIP_CALL(hipMemset(head, 0, sizeof(commkit::Signal) + fifo_bytes));
            COMMKIT_HIP_CALL(hipDeviceSynchronize());
        }
        g.barrier();

        // Shared eager relay buffer (registered at init), reused by both kernels.
        T* eager_in = static_cast<T*>(g.registered_input_ptr());
        COMMKIT_HIP_CALL(hipMemcpy(eager_in, host_in.data(), N * sizeof(T),
                                   hipMemcpyHostToDevice));
        auto* dp_eager = g.rank_data(eager_in);

        // Graph path reuses the pre-registered max-size buffer (dp_graph); refill
        // its first N elements for this shape.
        COMMKIT_HIP_CALL(hipMemcpy(graph_in, host_in.data(), N * sizeof(T),
                                   hipMemcpyHostToDevice));

        // ---- generic eager+graph bench for one launcher ----
        auto bench_kernel = [&](auto launch_fn) {
            // launch_fn(RankData* dp): enqueues one kernel on g.stream().
            auto eager = [&] { launch_fn(dp_eager); };
            clear_out();
            eager();
            COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
            float e_err = check_err();
            g.barrier();
            double e_us = commkit::bench_us(50, eager, g.stream());
            g.barrier();

            auto gk = [&] { launch_fn(dp_graph); };
            g.begin_capture();
            hipGraph_t graph = nullptr;
            COMMKIT_HIP_CALL(
                hipStreamBeginCapture(g.stream(), hipStreamCaptureModeRelaxed));
            gk();
            COMMKIT_HIP_CALL(hipStreamEndCapture(g.stream(), &graph));
            g.end_capture();
            hipGraphExec_t exec = nullptr;
            COMMKIT_HIP_CALL(hipGraphInstantiate(&exec, graph, nullptr, nullptr, 0));
            auto replay = [&] { COMMKIT_HIP_CALL(hipGraphLaunch(exec, g.stream())); };
            clear_out();
            g.barrier();
            double g_us = commkit::bench_us(50, replay, g.stream());
            COMMKIT_HIP_CALL(hipStreamSynchronize(g.stream()));
            float g_err = check_err();
            g.barrier();
            COMMKIT_HIP_CALL(hipGraphExecDestroy(exec));
            COMMKIT_HIP_CALL(hipGraphDestroy(graph));
            return std::array<double, 4>{e_us, g_us, (double)e_err, (double)g_err};
        };

        auto ll = bench_kernel([&](commkit::RankData* dp) {
            commkit::kernels::launch_ll_allgather<T, WORLD>(
                dp, g.rank_signals(), g.self_signal(), out, g.rank(), N, ll_grid,
                g.stream());
        });
        // Re-zero FIFO between the two kernels is unnecessary (copy ignores it),
        // but the copy kernel needs a fresh barrier epoch which start_sync owns.
        auto cp = bench_kernel([&](commkit::RankData* dp) {
            commkit::kernels::launch_copy_allgather<T, WORLD>(
                dp, g.rank_signals(), g.self_signal(), out, g.rank(), N, cp_grid,
                g.stream());
        });

        if (g.rank() == 0) {
            std::printf("  %6d | %10.2f %10.2f | %10.2f %10.2f | %8.3g %8.3g\n",
                        M, ll[0], ll[1], cp[0], cp[1],
                        std::max(ll[2], ll[3]), std::max(cp[2], cp[3]));
        }

        g.barrier();
    }

    COMMKIT_HIP_CALL(hipFree(graph_in));
    COMMKIT_HIP_CALL(hipFree(out));
    g.barrier();
    return 0;
}
