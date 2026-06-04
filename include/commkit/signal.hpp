#pragma once

#include <cstdint>

namespace commkit {

// Max blocks any allreduce kernel may launch. Sized to match the per-block
// flag arrays in Signal.
constexpr int kMaxBlocks = 80;

// Per-rank synchronization metadata, shared across ranks via IPC.
// Lives at the head of every "meta" buffer; the actual scratch space for
// 2-stage reductions follows immediately after (see get_tmp_buf).
//
// Atomics-via-flag scheme: peer atomics are not supported on PCIe links, so
// each rank polls its local copy of the start/end flag array updated by all
// other ranks via plain device-side stores.
struct Signal {
    alignas(128) uint32_t start[kMaxBlocks][8];
    alignas(128) uint32_t end[kMaxBlocks][8];
    alignas(128) uint32_t _flag[kMaxBlocks];   // monotonically incrementing flag per block
                                               //
    alignas(128) uint32_t ss;
    alignas(128) uint32_t arrival_cnt;
    alignas(128) uint32_t barrier_gen;
    alignas(128) uint32_t start_g[8];
};

// Per-rank input/output base pointer table. Indexed by peer rank.
struct __align__(16) RankData {
    const void* ptrs[8];
};

// Pointers to every rank's Signal (including self).
struct __align__(16) RankSignals {
    Signal* signals[8];
};

}  // namespace commkit
