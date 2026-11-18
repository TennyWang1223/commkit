#pragma once
// gfx1250 (MI450) constants shared by every proto. Ported from aiter
// custom_all_reduce_gfx1250.cuh; the module is also built for other archs and
// older toolchains (a gfx942 smoke build), where every gfx1250-only builtin
// below is compiled out behind its guard and aiter's fallback takes its place.
#include "commkit/common.cuh"

namespace commkit::gfx1250 {

constexpr int kMaxRanks = 8;
constexpr int kWaveSize = 32;
// grid cap of the simple and LL kernels, and the length of their per-block
// flag / epoch arrays (the lamport grids follow the message instead)
constexpr int kMaxBlocks = 512;

// one 16-byte transaction
using u32x4 = __attribute__((__vector_size__(4 * sizeof(uint32_t)))) uint32_t;

// every rank's pointer into one IPC buffer, indexed by rank; passed by value
struct __align__(16) RankData
{
    const void* ptrs[kMaxRanks];
};

// gfx1250 128-bit global load / store at system scope ("" == system): a single
// 16-byte transaction, so a peer reader sees a line's words land together (LL)
// or a whole pack at once (lamport). Elsewhere the LL and lamport protos fall
// back to nontemporal accesses.
#if defined(__HIP_DEVICE_COMPILE__) && (defined(__gfx1250__) || defined(__gfx1250_strict__)) && \
    __has_builtin(__builtin_amdgcn_global_store_b128) && __has_builtin(__builtin_amdgcn_global_load_b128)
#define CK_GFX1250_HAVE_B128 1
using U32x4GlobalPtr = __attribute__((address_space(1))) u32x4*;
#else
#define CK_GFX1250_HAVE_B128 0
#endif

} // namespace commkit::gfx1250
