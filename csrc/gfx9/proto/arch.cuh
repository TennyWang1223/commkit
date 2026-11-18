#pragma once
// gfx9 (gfx942 / gfx950) constants shared by every proto.
#include "commkit/common.cuh"

namespace commkit::gfx9 {

constexpr int kMaxRanks = 8;
constexpr int kWaveSize = 64;
// grid cap of the kernels with per-block flags / epochs
constexpr int kMaxBlocks = 80;

// one 16-byte transaction (global_load / store_dwordx4)
using u32x4 = __attribute__((__vector_size__(4 * sizeof(uint32_t)))) uint32_t;

// every rank's pointer into one IPC buffer, indexed by rank; passed by value
struct __align__(16) RankData
{
    const void* ptrs[kMaxRanks];
};

} // namespace commkit::gfx9
