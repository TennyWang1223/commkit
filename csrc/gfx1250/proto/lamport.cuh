#pragma once
// gfx1250 lamport protocol (wave32): push-only, barrier-free. Ported from
// aiter custom_all_reduce_gfx1250.cuh.
//
// The data is its own signal: an inbox slot holds the 0xffff half-word
// sentinel (a bf16 / fp16 NaN) until the peer's 16 bytes land; a sender
// rewrites its own 0xffff half-words to 0x7fff (also NaN), so real data never
// looks like the sentinel. Only the exact all-gather (LamportAgEscape) moves
// other dtypes, flagging all-ones words in an escape inbox instead.
//
// Inbox (one IPC buffer per rank, armed with 0xff):
//   inbox[kLamportBuffers][ngpus][slot] of 16B, slot = the most packs a call
//   takes, a multiple of kLamportWave
// A rank only ever writes slot[its rank] of a peer's inbox. Each wave of 32
// packs has its own rank-local round counter c, which picks the buffer.
// Every rank runs the same calls, so the counter of a pack is the same on
// every rank whatever the shape of each call, and a pack that sits out a call
// keeps its counter and its inbox. A peer is at most one round ahead on a pack,
// so buffer (c+2)%3 is re-armed at the end of round c and the kernel boundary
// orders that before this rank's next sends.
//
// Scratch per kernel: the inbox in cached IPC memory (polling it measured
// 0.3-1.5 us faster than uncached on gfx1250), the round counters (zero).
#include "gfx1250/proto/arch.cuh"

namespace commkit::gfx1250 {

constexpr int kLamportBuffers           = 3;
constexpr int kLamportWave              = 32;   // = kWaveSize
constexpr int kLamportRowMaxThreads     = 1024; // a row is one block: hidden <= 8192
constexpr int kLamportClusterMaxThreads = 256;
constexpr int kLamportMaxClusterBlocks  = 16;
// Rows of at most this many packs stay in one block: splitting them measured
// no faster at any row count (hidden 2048, TP2/TP4).
constexpr int kLamportMinClusterRowPacks = 256;
static_assert(kLamportWave == kWaveSize, "a lamport wave is a hardware wave");

// The device side of a workgroup-cluster launch: the gfx1250 cluster barrier
// and cluster memory scope (not in ROCm 7.2). Without them the cluster kernel
// body is a trap; the host only launches it with cluster launch support
// (kLamportClusterLaunch in the launch file).
#if defined(__HIP_DEVICE_COMPILE__) && (defined(__gfx1250__) || defined(__gfx1250_strict__)) && \
    __has_builtin(__builtin_amdgcn_s_cluster_barrier) && defined(__MEMORY_SCOPE_CLUSTR)
#define CK_GFX1250_HAVE_CLUSTER 1
#else
#define CK_GFX1250_HAVE_CLUSTER 0
#endif

// The data inbox: [kLamportBuffers][ngpus][slot] of 16B.
inline constexpr int64_t lamportInboxBytes(int ngpus, int64_t slot)
{
    return (int64_t)kLamportBuffers * ngpus * slot * 16;
}

// The exact all-gather's escape inbox, one uint32 a pack of the data inbox,
// armed with 0 (see LamportAgEscape).
inline constexpr int64_t lamportEscapeBytes(int ngpus, int64_t slot)
{
    return (int64_t)kLamportBuffers * ngpus * slot * 4;
}

// The two-shot all-reduce's all-gather inbox, [ngpus][slot] of 16B, one buffer
// (no rounds), armed with 0xff; it follows the data inbox in the same buffer.
inline constexpr int64_t lamportTwoShotBytes(int ngpus, int64_t slot) { return (int64_t)ngpus * slot * 16; }

// Rank-local per-wave state (round counters, cluster partials): one entry a
// wave of 32 packs of the slot.
inline constexpr int64_t lamportWaves(int64_t slot) { return slot / kLamportWave; }

// The two-shot's slot: a rank's chunk of the largest message,
// ceil(max_bytes / 16 / ngpus) packs, rounded up to whole waves.
inline constexpr int64_t lamportTwoShotSlot(int64_t max_bytes, int ngpus)
{
    const int64_t chunk = (max_bytes / 16 + ngpus - 1) / ngpus;
    return (chunk + kLamportWave - 1) / kLamportWave * kLamportWave;
}

// aiter's block size for a call of `packs` packs (LamportArRms::add_threads):
// small blocks spread a decode-size call over more CUs, large ones cut the
// blocks of a big call (4x gfx1250, TP4, bf16 [M, 5120]: 64 best at M = 1,
// 256 at M = 8-288, 512 at M = 409).
inline constexpr int lamportBlockThreads(int64_t packs)
{
    if(packs <= 2048)
        return 64;
    return packs <= 192 * 1024 ? 256 : 512;
}

struct __align__(16) LamportPeers
{
    void* ptrs[kMaxRanks];
};

// one bit per half-word that is the 0xffff sentinel
DINLINE uint32_t lamportSentinelMask(uint32_t w)
{
    uint32_t x   = ~w;
    uint32_t tmp = ((x & 0x7fff7fff) + 0x7fff7fff) | x;
    return (tmp & 0x80008000) ^ 0x80008000;
}

// 0xffff -> 0x7fff, both NaN, so sent data is never the sentinel
DINLINE uint32_t lamportCanonicalize(uint32_t w) { return w ^ lamportSentinelMask(w); }

DINLINE void lamportStoreB128(void* dst, u32x4 v)
{
#if CK_GFX1250_HAVE_B128
    __builtin_amdgcn_global_store_b128((U32x4GlobalPtr)dst, v, "");
#else
    __builtin_nontemporal_store(v, reinterpret_cast<u32x4*>(dst));
#endif
}

DINLINE u32x4 lamportLoadB128(const void* src)
{
#if CK_GFX1250_HAVE_B128
    return __builtin_amdgcn_global_load_b128((U32x4GlobalPtr)src, "");
#else
    return __builtin_nontemporal_load(reinterpret_cast<const u32x4*>(src));
#endif
}

// Spin until no slot of this rank's inbox (slot[g] at inbox + g * slot, one
// pack each) but its own holds a sentinel half-word; got[g].i is what was
// read. slot[rank] is never written and stays the sentinel: it is loaded
// anyway and masked out, a branch would make every load wait for the previous
// one. Every load goes out before any mask math.
template <int ngpus, typename V, typename P>
DINLINE void lamportPollInbox(V (&got)[ngpus], const P* inbox, int64_t slot, int rank)
{
    bool pending;
    do
    {
        // without the clobber the loads are hoisted out of the loop
        asm volatile("" ::: "memory");
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            got[g].i = lamportLoadB128(inbox + g * slot);
        // issue all loads before any mask math
        __builtin_amdgcn_sched_barrier(0);
        uint32_t m = 0;
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
        {
            uint32_t gm = 0;
#pragma unroll
            for(int j = 0; j < 4; ++j)
                gm |= lamportSentinelMask(got[g].i[j]);
            m |= g == rank ? 0u : gm;
        }
        pending = m != 0;
    } while(pending);
}

} // namespace commkit::gfx1250
