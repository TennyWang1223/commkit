#pragma once
// gfx1250 LL protocol (aiter custom_all_reduce_gfx1250.cuh, the LL kernels).
//
// A 16-byte line carries 8 bytes of payload in words 0 and 2 and the call's
// epoch in words 1 and 3 (LLLine); the all-gather packs 12 bytes of payload
// into words 0-2 and the epoch into word 3. It is written with one
// llStoreB128 and read with one llLoadB128, and a reader takes it only once
// its flags carry the epoch, so a line has to land atomically only per flagged
// part; no barrier is needed.
//
// On gfx1250 a load issued after a remote store in the same wave returns only
// once that store has completed, about a fabric round trip, while a peer's line
// lands about half a round trip after it was sent. So the waves that send never
// poll, and a wave that does both polls before it sends: a poll sees a line as
// soon as it lands. The bank bases are read once, before any store, and indexed
// at compile time, so no table read sits between two remote stores. A poller
// polls every line it still needs in one batch.
//
// Every element is summed in fp32 in rank order 0..ngpus-1 with the local value
// at its own rank and rounded to T once, so the result does not depend on which
// kernel reduced it or on which rank.
//
// Epochs (graph safe): a rank-local per-block array that the kernel itself
// bumps. The grid and block sizes follow the message size, so the block that
// owns a line changes between calls of different sizes: every launch therefore
// writes its epoch to all kMaxBlocks entries (llPublishEpoch), including those
// of blocks it did not launch, so all blocks start the next call on one epoch.
// The FIFO is double-banked (bank = epoch & 1) with a fixed per-rank slot
// stride; the epoch tells this call's lines from older ones, so it is never
// cleared after the zero fill.
//
// Scratch per kernel: an uncached IPC FIFO, zero-filled (flag 0 == a cleared
// line), and the epoch array (zero).
#include "gfx1250/proto/arch.cuh"

namespace commkit::gfx1250 {

union LLLine
{
    struct
    {
        uint32_t data0;
        uint32_t flag0;
        uint32_t data1;
        uint32_t flag1;
    };
    uint4 raw;
};
static_assert(sizeof(LLLine) == 16, "an LL line is 16 bytes");

DINLINE void llStoreB128(uint32_t* dst, uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3)
{
#if CK_GFX1250_HAVE_B128
    union
    {
        u32x4 v;
        uint32_t w[4];
    } u;
    u.w[0] = a0;
    u.w[1] = a1;
    u.w[2] = a2;
    u.w[3] = a3;
    __builtin_amdgcn_global_store_b128((U32x4GlobalPtr)dst, u.v, "");
#else
    __builtin_nontemporal_store(a0, dst + 0);
    __builtin_nontemporal_store(a1, dst + 1);
    __builtin_nontemporal_store(a2, dst + 2);
    __builtin_nontemporal_store(a3, dst + 3);
#endif
    asm volatile("" ::: "memory");
}

DINLINE void llLoadB128(const uint32_t* src, uint32_t& o0, uint32_t& o1, uint32_t& o2, uint32_t& o3)
{
    asm volatile("" ::: "memory");
#if CK_GFX1250_HAVE_B128
    union
    {
        u32x4 v;
        uint32_t w[4];
    } u;
    u.v = __builtin_amdgcn_global_load_b128((U32x4GlobalPtr)src, "");
    o0  = u.w[0];
    o1  = u.w[1];
    o2  = u.w[2];
    o3  = u.w[3];
#else
    o0 = __builtin_nontemporal_load(src + 0);
    o1 = __builtin_nontemporal_load(src + 1);
    o2 = __builtin_nontemporal_load(src + 2);
    o3 = __builtin_nontemporal_load(src + 3);
#endif
}

// Next epoch of a block. Never 0 (a cleared FIFO), and the wrap goes to 2 so
// the bank (epoch parity) still alternates.
DINLINE uint32_t llNextEpoch(uint32_t epoch)
{
    uint32_t next = epoch + 1u;
    if(next == 0u)
        next = 2u;
    return next;
}

// The launch's epoch into every entry of the per-block array, launched blocks
// or not (see above); the last thing a launch does.
DINLINE void llPublishEpoch(uint32_t* __restrict__ block_epochs, uint32_t flag)
{
    for(int e = blockIdx.x + threadIdx.x * gridDim.x; e < kMaxBlocks; e += gridDim.x * blockDim.x)
        block_epochs[e] = flag;
}

// ---------------------------------------------------------------------------
// one-shot FIFO (arOneShotLL, agLL)
// ---------------------------------------------------------------------------
// Largest message (one slot of payload): 4 MiB.
constexpr size_t kLLScratchCapBytes = 4194304;
// Lines a source's slot takes: one 8-byte packet a line.
constexpr size_t kLLPackCapacity = kLLScratchCapBytes / 8; // 524288

// A rank's FIFO: [2 banks][ngpus slots][kLLPackCapacity lines] of 16B, 16 MiB
// x ngpus. Sized by the world size: the kernels index it with their template
// ngpus, the bank offset peaks at (2 * ngpus - 1) slots.
constexpr size_t llScratchBytes(int ngpus) { return (size_t)2 * ngpus * kLLPackCapacity * sizeof(LLLine); }

// ---------------------------------------------------------------------------
// two-shot FIFO (arTwoShotLL)
// ---------------------------------------------------------------------------
// The largest message the LL two-shot all-reduce takes at each world size,
// from MI455X measurements, bf16 in a CUDA graph:
// - TP8, two trays: ahead of RCCL at 8.39 MB (39.2 vs 43.7 us).
// - TP4, one tray: ahead of the one-shot pull up to 8.39 MB (32 vs 89 us).
// 0 means the world size does not take the two-shot (TP2). This cap also sizes
// the two-shot's FIFO.
constexpr size_t ar2sMaxBytes(int ngpus) { return ngpus == 4 || ngpus == 8 ? (size_t)8 * 1024 * 1024 : 0; }

// Two banks, each a reduce-scatter region and an all-gather region of
// ar2sMaxBytes / 8 lines: 8 x ar2sMaxBytes a rank, 64 MiB at TP4 and TP8.
constexpr size_t ar2sRegionPk(int ngpus) { return ar2sMaxBytes(ngpus) / 8; }
constexpr size_t ar2sScratchBytes(int ngpus) { return (size_t)2 * 2 * ar2sRegionPk(ngpus) * sizeof(LLLine); }

// Lines a source's slot takes in a region: a chunk of ar2sMaxBytes / ngpus in
// 8-byte packets, rounded to 4 KiB. A slot that does not start on a cache-line
// boundary costs ~3 us a call (MI455X, measured).
constexpr size_t ar2sSrcLines(int ngpus)
{
    return ngpus == 0 ? 0 : (ar2sMaxBytes(ngpus) / 8 / ngpus + 255) / 256 * 256;
}
static_assert(8 * ar2sSrcLines(8) <= ar2sRegionPk(8) && 4 * ar2sSrcLines(4) <= ar2sRegionPk(4),
              "every source's slot must fit the two-shot's regions");

} // namespace commkit::gfx1250
