#pragma once
// Host-side helpers for the per-kernel launch files (csrc/<arch>/kernel/**.cu).
//
// A launch file is one JIT module. It exports two functions to Python:
//   scratch_spec(max_bytes, world_size) -> [(name, bytes, ipc, uncached, fill)]
//       the device buffers the kernel needs; Python allocates them once per
//       op (ipc=True buffers are mapped on every rank of the group).
//   launch(...)
//       stateless: every pointer, size and the stream come from Python, which
//       has already checked the arguments.
#include <hip/hip_runtime.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include <cstdint>
#include <stdexcept>
#include <string>
#include <tuple>
#include <vector>

#include "opus/opus.hpp"

namespace py = pybind11;

#define CK_HIP_CHECK(cmd)                                                                      \
    do                                                                                         \
    {                                                                                          \
        hipError_t ck_err_ = (cmd);                                                            \
        if(ck_err_ != hipSuccess)                                                              \
            throw std::runtime_error(std::string("HIP error '") + hipGetErrorString(ck_err_) + \
                                     "' at " + __FILE__ + ":" + std::to_string(__LINE__));     \
    } while(0)

namespace commkit {

// dtype codes, mirrored by commkit/ops/base.py
enum DtypeCode : int
{
    kFp32 = 0,
    kFp16 = 1,
    kBf16 = 2,
};

// (name, bytes, ipc, uncached, fill); fill < 0 leaves the buffer as allocated
using ScratchSpec = std::tuple<std::string, int64_t, bool, bool, int>;

inline hipStream_t toStream(int64_t stream) { return reinterpret_cast<hipStream_t>(stream); }

template <typename T>
inline T* toPtr(int64_t ptr)
{
    return reinterpret_cast<T*>(ptr);
}

// Fills a struct whose only member is an array `ptrs` of pointers (RankData,
// RankSignals, LamportPeers, ...) from the per-rank pointers Python passes.
template <typename S>
inline S toPeers(const std::vector<int64_t>& peers)
{
    S s{};
    constexpr size_t capacity = sizeof(s.ptrs) / sizeof(s.ptrs[0]);
    if(peers.size() > capacity)
        throw std::invalid_argument("got " + std::to_string(peers.size()) +
                                    " peer pointers, the struct holds " +
                                    std::to_string(capacity));
    for(size_t i = 0; i < peers.size(); ++i)
        s.ptrs[i] = reinterpret_cast<std::remove_reference_t<decltype(s.ptrs[0])>>(peers[i]);
    return s;
}

// surfaces a bad launch configuration at the call that made it
inline void checkLaunch() { CK_HIP_CHECK(hipGetLastError()); }

inline int numCus()
{
    int device = 0;
    CK_HIP_CHECK(hipGetDevice(&device));
    int cus = 0;
    CK_HIP_CHECK(hipDeviceGetAttribute(&cus, hipDeviceAttributeMultiprocessorCount, device));
    return cus;
}

} // namespace commkit

// ---------------------------------------------------------------------------
// compile-time dispatch of the world size and the dtype
// ---------------------------------------------------------------------------
#define CK_NGPUS_CASE(NG_VALUE, NG, ...) \
    case NG_VALUE: {                     \
        constexpr int NG = NG_VALUE;     \
        __VA_ARGS__;                     \
        break;                           \
    }

#define CK_DISPATCH_NGPUS(ngpus, NG, ...)                                                 \
    switch(ngpus)                                                                         \
    {                                                                                     \
        CK_NGPUS_CASE(2, NG, __VA_ARGS__)                                                 \
        CK_NGPUS_CASE(4, NG, __VA_ARGS__)                                                 \
        CK_NGPUS_CASE(8, NG, __VA_ARGS__)                                                 \
    default:                                                                              \
        throw std::invalid_argument("unsupported world size " + std::to_string(ngpus)); \
    }

#define CK_DTYPE_CASE(CODE, TYPE, T, ...) \
    case CODE: {                          \
        using T = TYPE;                   \
        __VA_ARGS__;                      \
        break;                            \
    }

// fp32 / fp16 / bf16
#define CK_DISPATCH_FLOAT(code, T, ...)                                                   \
    switch(code)                                                                          \
    {                                                                                     \
        CK_DTYPE_CASE(commkit::kFp32, opus::fp32_t, T, __VA_ARGS__)                       \
        CK_DTYPE_CASE(commkit::kFp16, opus::fp16_t, T, __VA_ARGS__)                       \
        CK_DTYPE_CASE(commkit::kBf16, opus::bf16_t, T, __VA_ARGS__)                       \
    default: throw std::invalid_argument("unsupported dtype code " + std::to_string(code)); \
    }

// fp16 / bf16
#define CK_DISPATCH_HALF(code, T, ...)                                                    \
    switch(code)                                                                          \
    {                                                                                     \
        CK_DTYPE_CASE(commkit::kFp16, opus::fp16_t, T, __VA_ARGS__)                       \
        CK_DTYPE_CASE(commkit::kBf16, opus::bf16_t, T, __VA_ARGS__)                       \
    default: throw std::invalid_argument("unsupported dtype code " + std::to_string(code)); \
    }

// the module name is set by the JIT (commkit/jit.py)
#define CK_MODULE(m) PYBIND11_MODULE(COMMKIT_MODULE_NAME, m)
