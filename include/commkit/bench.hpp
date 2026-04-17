#pragma once

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <random>
#include <vector>
#include <hip/hip_runtime.h>

#include "commkit/hip_check.hpp"
#include "opus/opus.hpp"

namespace commkit {

// Stream-timed benchmark. Runs warmup iters, then `iters` measured launches
// fenced by hipEvents. Returns mean per-launch latency in microseconds.
template <typename F>
double bench_us(int iters, F&& fn, hipStream_t stream, int warmup = 5) {
    for (int i = 0; i < warmup; ++i) fn();
    COMMKIT_HIP_CALL(hipStreamSynchronize(stream));

    hipEvent_t e0, e1;
    COMMKIT_HIP_CALL(hipEventCreate(&e0));
    COMMKIT_HIP_CALL(hipEventCreate(&e1));
    COMMKIT_HIP_CALL(hipEventRecord(e0, stream));
    for (int i = 0; i < iters; ++i) fn();
    COMMKIT_HIP_CALL(hipEventRecord(e1, stream));
    COMMKIT_HIP_CALL(hipEventSynchronize(e1));

    float ms = 0.f;
    COMMKIT_HIP_CALL(hipEventElapsedTime(&ms, e0, e1));
    COMMKIT_HIP_CALL(hipEventDestroy(e0));
    COMMKIT_HIP_CALL(hipEventDestroy(e1));
    return double(ms) * 1000.0 / iters;
}

// Generate float values in [-1, 1] on host then cast+upload to device.
template <typename T>
void fill_random(T* d_ptr, size_t n, uint64_t seed) {
    std::mt19937_64 rng(seed);
    std::uniform_real_distribution<float> dist(-1.f, 1.f);
    std::vector<T> host(n);
    for (size_t i = 0; i < n; ++i) {
        host[i] = static_cast<T>(dist(rng));
    }
    COMMKIT_HIP_CALL(hipMemcpy(d_ptr, host.data(), n * sizeof(T), hipMemcpyHostToDevice));
}

template <typename T>
void copy_to_host(std::vector<float>& dst, const T* d_ptr, size_t n) {
    std::vector<T> tmp(n);
    COMMKIT_HIP_CALL(hipMemcpy(tmp.data(), d_ptr, n * sizeof(T), hipMemcpyDeviceToHost));
    dst.resize(n);
    for (size_t i = 0; i < n; ++i) dst[i] = static_cast<float>(tmp[i]);
}

}  // namespace commkit
