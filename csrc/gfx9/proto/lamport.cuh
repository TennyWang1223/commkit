#pragma once
// gfx9 lamport protocol (wave64, 2-byte dtypes): push-only, barrier-free.
// The data is its own signal: an inbox slot holds the 0xffff sentinel until
// the peer's 16 bytes land, real data never carries it (lamportCanonicalize).
//
// Scratch per kernel: uncached IPC inboxes filled with 0xff (the sentinel),
// and rank-local round counters (zero). Ported from aiter
// custom_all_reduce.cuh; the inbox geometry constants below size each
// kernel's scratch (see the launch files' scratch_spec).
#include "gfx9/proto/arch.cuh"

namespace commkit::gfx9 {

// ===========================================================================
// Lamport all-reduce: one-shot and two-shot wave split (2-byte dtypes, wave64)
// ===========================================================================
// Push-only, barrier-free all-reduce. Every rank writes its data straight into
// its peers' inboxes (a separate uncached IPC buffer, the kernel's scratch) and only
// polls its own. The data is its own signal: an inbox starts as the 0xffff
// sentinel (NaN in bf16 and fp16), real data never carries it
// (lamportCanonicalize turns 0xffff into 0x7fff, also NaN), so a 16B slot has
// arrived once none of its half-words is 0xffff. Half-words are checked one by
// one, so a slot that lands in pieces is fine.
//
// Inbox: [kLamportBuffers][ngpus source ranks][positions] of 16B, with
// kLamportMaxPacks positions for the one-shot and lamportTwoShotMaxPart(ngpus)
// for each two-shot inbox. A rank only ever writes slot[its rank] of a peer's
// inbox, so every position has one writer and one reader. The own slot is
// never written.
//
// Rounds: every block has a rank-local round counter c in {0, 1, 2}; round c
// uses buffer c and, at its end, re-arms buffer (c+2)%3 to the sentinel. No
// rank finishes round c without every peer's round c data, so ranks are at
// most one round apart, every peer's round c-1 data has been read when buffer
// (c+2)%3 is re-armed, nobody writes it again before round c+2, and the kernel
// boundary orders the re-arm before this rank's next sends. Every lane of a
// launched block re-arms, even past the message: a position used last round
// but not in this one would otherwise keep stale data. A block always covers
// the same kLamportWaveSize positions, so a block id's counter is the same on
// every rank whatever the message size, and a launch is one round (no
// grid-stride loop), which caps the message (see the run functions). A launch
// may have more blocks than the GPU holds at once (up to 1024 at TP2 for a 2MB
// two-shot); that is fine, as a block only waits for the blocks of the same id
// on the other ranks, never for another block of its own launch.
//
// Sums run in fp32 in rank order 0..ngpus-1 and round once, so every rank gets
// the same bits.
//
// Wave split: a block is ngpus waves over the same kLamportWaveSize positions;
// wave w talks to rank (rank + w) % ngpus only, so wave 0 is this rank, each
// lane waits for one cross-GPU store instead of ngpus - 1, and a wave whose
// data has arrived stops polling.
// ===========================================================================
constexpr int kLamportBuffers   = 3;
constexpr int kLamportMaxPacks  = 512 * 80; // positions per inbox slot (640KB of 2-byte data)
constexpr int kLamportWaveSize  = 64;       // positions per block, one per lane of a wave64
constexpr int kLamportMaxBlocks = kLamportMaxPacks / kLamportWaveSize;

// Largest two-shot message; sizes the two-shot inboxes. The one-shot keeps
// kLamportMaxPacks positions (640KB).
constexpr int64_t kLamportTwoShotMaxBytes = 2ll << 20;

// two-shot positions per chunk, i.e. per rank, of the largest message
inline constexpr int64_t lamportTwoShotMaxPart(int ngpus)
{
    return kLamportTwoShotMaxBytes / 16 / ngpus;
}

// two-shot round counters, one per block of the largest message
inline constexpr int64_t lamportTwoShotMaxBlocks(int ngpus)
{
    return lamportTwoShotMaxPart(ngpus) / kLamportWaveSize;
}

// The one-shot inbox: [kLamportBuffers][ngpus][kLamportMaxPacks] of 16B.
inline constexpr int64_t lamportInboxBytes(int ngpus)
{
    return (int64_t)kLamportBuffers * ngpus * kLamportMaxPacks * 16;
}

// One two-shot inbox: [kLamportBuffers][ngpus][lamportTwoShotMaxPart(ngpus)]
// of 16B, 3 * kLamportTwoShotMaxBytes = 6MB for any ngpus.
inline constexpr int64_t lamportTwoShotInboxBytes(int ngpus)
{
    return (int64_t)kLamportBuffers * ngpus * lamportTwoShotMaxPart(ngpus) * 16;
}

// Two-shot fused all-reduce + RMSNorm POC (arRmsTwoShotLamport): rows per
// launch, and 16B positions per row slot (hidden <= 8192).
constexpr int kLamportArRms2MaxRows      = 128;
constexpr int kLamportArRms2SlotPacks    = 1024;
constexpr int64_t kLamportArRms2BufPacks = (int64_t)kLamportArRms2MaxRows * kLamportArRms2SlotPacks;

// One inbox of arRmsTwoShotLamport: [kLamportBuffers][kLamportArRms2MaxRows]
// row slots of kLamportArRms2SlotPacks 16B, 6MB. A reduce row slot holds
// ngpus source slots of kLamportArRms2SlotPacks / ngpus, a broadcast row slot
// the row.
inline constexpr int64_t lamportArRms2InboxBytes()
{
    return (int64_t)kLamportBuffers * kLamportArRms2BufPacks * 16;
}

struct __align__(16) LamportPeers
{
    void* ptrs[8];
};

// bit 15 of every half-word of w that is the 0xffff sentinel
DINLINE uint32_t lamportSentinelMask(uint32_t w)
{
    uint32_t x   = ~w;                                    // w_h == 0xffff <=> x_h == 0
    uint32_t tmp = ((x & 0x7fff7fff) + 0x7fff7fff) | x;   // bit 15 = (x_h != 0), no carry out
    return (tmp & 0x80008000) ^ 0x80008000;
}

// 0xffff -> 0x7fff, both NaN, so real data never looks like the sentinel
DINLINE uint32_t lamportCanonicalize(uint32_t w) { return w ^ lamportSentinelMask(w); }

// Spin on one 16B inbox slot until none of its half-words is the sentinel.
template <typename V>
DINLINE V lamportPollSlot(const V* slot_ptr)
{
    V slot_val;
    uint32_t wait_mask;
    do
    {
        // without the memory clobber the load is hoisted out of the loop
        asm volatile("" ::: "memory");
        slot_val  = __builtin_nontemporal_load(slot_ptr);
        wait_mask = 0;
#pragma unroll
        for(int j = 0; j < 4; ++j)
            wait_mask |= lamportSentinelMask(slot_val[j]);
    } while(wait_mask != 0);
    return slot_val;
}

// Fused all-reduce + RMSNorm: packs per sum-of-squares partial (the
// WARP_SIZE of the 1-stage reduction), partial slots, longest row.
constexpr int kLamportRmsLanes       = 32;
constexpr int kLamportRmsMaxPartials = kLamportMaxPacks / kLamportRmsLanes;
constexpr int kLamportRmsMaxRowPacks = 1024; // a row fits one block: hidden <= 8192
static_assert(kLamportArRms2SlotPacks == kLamportRmsMaxRowPacks, "a row slot holds the longest row");

// Publish a 32-pack partial in this round's slot and re-arm last round's. The
// blocks that read last round's slot finished with the previous launch.
DINLINE void lamportRmsPublish(
    uint32_t* partials, uint32_t round, uint32_t rearm, int partial_id, float part)
{
    uint32_t bits = __builtin_bit_cast(uint32_t, part);
    bits          = bits == 0xffffffffu ? 0x7fffffffu : bits;
    __builtin_nontemporal_store(bits, partials + round * kLamportRmsMaxPartials + partial_id);
    __builtin_nontemporal_store(0xffffffffu, partials + rearm * kLamportRmsMaxPartials + partial_id);
}

// s_sleep before the split mode polls the row's partials (units of 64
// clocks, ~0.5us). The blocks of a row publish at about the same time and a
// poll sent right away mostly reaches memory before the others' partials, so
// it takes a second ~1.4us round; waiting first saves that. gfx942 sweep:
// 16 beat 0 by ~0.4us on TP8, 32 was no better.
constexpr int kLamportRmsPollSleep = 16;

DINLINE float lamportRmsPollPartial(const uint32_t* slot_ptr)
{
    uint32_t bits;
    do
    {
        // without the memory clobber the load is hoisted out of the loop
        asm volatile("" ::: "memory");
        bits = __builtin_nontemporal_load(slot_ptr);
    } while(bits == 0xffffffffu);
    return __builtin_bit_cast(float, bits);
}

// peers.ptrs[g] for a per-lane g, picked from the scalar pointers: indexing
// the kernel argument with a VGPR loads it from memory first, a dependent
// load in front of the push. The empty asm keeps the compiler from turning
// the selects back into that load; the global address space keeps the push a
// global (not flat) store.
template <typename V>
using LamportGlobalPtr = __attribute__((address_space(1))) V*;

template <int ngpus, typename V>
DINLINE LamportGlobalPtr<V> lamportPeerPtr(const LamportPeers& peers, int g)
{
    uint64_t ptrs[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; ++i)
    {
        ptrs[i] = reinterpret_cast<uint64_t>(peers.ptrs[i]);
        asm volatile("" : "+s"(ptrs[i]));
    }
    uint64_t ptr = ptrs[0];
#pragma unroll
    for(int i = 1; i < ngpus; ++i)
        ptr = g == i ? ptrs[i] : ptr;
    return (LamportGlobalPtr<V>)ptr;
}

} // namespace commkit::gfx9
