// Driver for copy_kernel2 (overlapped loads, vmcnt-gated stores).
// Single block / single grid so ATT trace contains exactly one wavefront set
// running the two-load-then-gated-store sequence.
//
// Run:  ./test_copy_kernel2

#include <cstdio>
#include <cstdlib>
#include <vector>

#include "commkit/hip_check.hpp"
#include "copy_kernel2.cuh"

constexpr int GRID  = 64;
constexpr int BLOCK = 256;
// Each thread copies 2 * int4 = 32 B.
constexpr int N_INT4 = GRID * BLOCK * 2;
constexpr int N_BYTES = N_INT4 * static_cast<int>(sizeof(int4));

int main() {
    std::vector<int4> host_in(N_INT4);
    for (int i = 0; i < N_INT4; ++i) {
        host_in[i] = int4{i * 4 + 0, i * 4 + 1, i * 4 + 2, i * 4 + 3};
    }

    int4* d_in  = nullptr;
    int4* d_out = nullptr;
    COMMKIT_HIP_CALL(hipMalloc(&d_in,  N_BYTES));
    COMMKIT_HIP_CALL(hipMalloc(&d_out, N_BYTES));
    COMMKIT_HIP_CALL(hipMemcpy(d_in, host_in.data(), N_BYTES, hipMemcpyHostToDevice));
    COMMKIT_HIP_CALL(hipMemset(d_out, 0, N_BYTES));

    auto launch = [&] {
        commkit::kernels::copy_kernel2<BLOCK><<<GRID, BLOCK>>>(d_in, d_out);
    };

    // Warmup so the first launch's lazy paging / TLB fills aren't in the trace.
    launch();
    COMMKIT_HIP_CALL(hipDeviceSynchronize());

    // Steady-state launch — the one the profiler should target.
    launch();
    COMMKIT_HIP_CALL(hipDeviceSynchronize());

    std::vector<int4> host_out(N_INT4);
    COMMKIT_HIP_CALL(hipMemcpy(host_out.data(), d_out, N_BYTES, hipMemcpyDeviceToHost));

    int mismatches = 0;
    for (int i = 0; i < N_INT4 && mismatches < 4; ++i) {
        const auto& a = host_in[i];
        const auto& b = host_out[i];
        if (a.x != b.x || a.y != b.y || a.z != b.z || a.w != b.w) {
            std::printf("mismatch @ %d: in=(%d %d %d %d) out=(%d %d %d %d)\n",
                        i, a.x, a.y, a.z, a.w, b.x, b.y, b.z, b.w);
            ++mismatches;
        }
    }

    std::printf("[copy_kernel2] grid=%d block=%d bytes=%d %s\n",
                GRID, BLOCK, N_BYTES, mismatches ? "FAIL" : "OK");

    COMMKIT_HIP_CALL(hipFree(d_in));
    COMMKIT_HIP_CALL(hipFree(d_out));
    return mismatches ? 1 : 0;
}
