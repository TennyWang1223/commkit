#pragma once
// all_gather, lamport proto, push (aiter lamport_ag_gfx1250), with the fp16 /
// bf16 half-word sentinel codec (LamportAgHalfSentinel). The exact codec for
// any dtype is lamport_escape.cuh.
#include "gfx1250/proto/lamport.cuh"

namespace commkit::gfx1250 {

/*
 * Thread tid owns pack tid of this rank's input: it pushes the pack into
 * slot[rank] of every peer's inbox, then polls slot[g] of its own inbox for the
 * peers and writes each pack to its place in the output. Rounds and re-arm as
 * the one-shot lamport all-reduce. Against the LL all-gather: a 16B line
 * carries 16B of payload instead of 12B (no epoch word in the data), and there
 * is no epoch fan-out over kMaxBlocks at the end.
 *
 * Rank g's pack p of row y = p / row_packs lands at output pack
 * (y * ngpus + g) * row_packs + p % row_packs. DIM0 (row_packs == packs)
 * gathers along dim 0 without the division.
 *
 * How a receiver tells an arrived word from the all-ones sentinel of an armed
 * inbox is the Codec; the kernel moves raw words whatever the dtype:
 *
 *   encode(v)                   make pack v sendable in place; returns its
 *                               escape mask, sent along with it
 *   publishEscape(peer, at, m)  send a nonzero escape mask m to peer's inbox
 *   loadEscape(own, at)         this round's escape mask of a pack, polled
 *                               with the pack
 *   pending(v, esc)             nonzero while a word of v has not arrived
 *   releaseEscape(own, at, esc) re-arm an escape mask this rank consumed
 *
 * peer / own are the escape inboxes (a uint32 a pack, lamportEscapeBytes), at
 * the pack's index in them, the same as in the data inbox. A codec without an
 * escape inbox leaves those empty and is launched with null e0..e7.
 *
 * The inputs are 16B aligned and read in place: the input must lie clear of
 * the output, or be this rank's own slice of a dim-0 gather.
 *
 * Scalar and pointer kernel arguments only, the inboxes one by one (see the
 * lamport all-reduce): p0..p7 the data inboxes, e0..e7 the escape inboxes.
 */

// fp16 / bf16: the 0xffff half-word sentinel of the other lamport kernels. A
// 0xffff half-word is sent as 0x7fff (both NaN), so the gather is bit for bit
// except for it; every rank writes the canonical bits, its own slice too.
struct LamportAgHalfSentinel
{
    static DINLINE uint32_t encode(u32x4& v)
    {
#pragma unroll
        for(int j = 0; j < 4; ++j)
            v[j] = lamportCanonicalize(v[j]);
        return 0;
    }
    static DINLINE void publishEscape(uint32_t*, int64_t, uint32_t) {}
    static DINLINE uint32_t loadEscape(const uint32_t*, int64_t) { return 0; }
    static DINLINE uint32_t pending(const u32x4& v, uint32_t)
    {
        uint32_t m = 0;
#pragma unroll
        for(int j = 0; j < 4; ++j)
            m |= lamportSentinelMask(v[j]);
        return m;
    }
    static DINLINE void releaseEscape(uint32_t*, int64_t, uint32_t) {}
};

template <class Codec, int ngpus, int BLOCK, bool DIM0>
__global__ void __launch_bounds__(BLOCK, 1)
    agLamport(const u32x4* __restrict__ input,
                         u32x4* __restrict__ output,
                         uint32_t* __restrict__ round_counter, // [slot / 32], rank-local
                         int slot,                             // inbox packs per sender
                         int rank,
                         int packs,     // 16B packs a rank sends
                         int row_packs, // 16B packs of a gathered row (== packs for DIM0)
                         void* p0,
                         void* p1,
                         void* p2,
                         void* p3,
                         void* p4,
                         void* p5,
                         void* p6,
                         void* p7,
                         void* e0,
                         void* e1,
                         void* e2,
                         void* e3,
                         void* e4,
                         void* e5,
                         void* e6,
                         void* e7)
{
    static_assert(BLOCK % kLamportWave == 0, "blocks are whole waves");

    const int tid  = blockIdx.x * BLOCK + threadIdx.x;
    const int wave = __builtin_amdgcn_readfirstlane(tid / kLamportWave);
    // waves past the input sit the call out, see the one-shot all-reduce
    if(wave * kLamportWave >= packs)
        return;
    const uint32_t round = round_counter[wave];
    const uint32_t rearm = (round + 2) % kLamportBuffers;
    void* const all[8]   = {p0, p1, p2, p3, p4, p5, p6, p7};
    char* own            = static_cast<char*>(all[0]);
#pragma unroll
    for(int g = 1; g < ngpus; ++g)
        own = g == rank ? static_cast<char*>(all[g]) : own;
    // the escape inboxes (unused by LamportAgHalfSentinel)
    void* const escape[8] = {e0, e1, e2, e3, e4, e5, e6, e7};
    uint32_t* own_escape  = static_cast<uint32_t*>(escape[0]);
#pragma unroll
    for(int g = 1; g < ngpus; ++g)
        own_escape = g == rank ? static_cast<uint32_t*>(escape[g]) : own_escape;

    if(tid < packs)
    {
        u32x4 local             = input[tid];
        const uint32_t esc_mask = Codec::encode(local);

        const int64_t sent = (int64_t)(round * ngpus + rank) * slot + tid;
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            if(g != rank)
            {
                lamportStoreB128(static_cast<u32x4*>(all[g]) + sent, local);
                Codec::publishEscape(static_cast<uint32_t*>(escape[g]), sent, esc_mask);
            }

        // output pack of rank g is out[g * step]
        int64_t base, step;
        if constexpr(DIM0)
        {
            base = tid;
            step = packs;
        }
        else
        {
            const int y = tid / row_packs;
            base        = (int64_t)y * ngpus * row_packs + (tid - y * row_packs);
            step        = row_packs;
        }
        u32x4* out = output + base;
        // own slice while the peers' packs are in flight
        out[rank * step] = local;

        // slot[rank] stays the sentinel; loaded and masked out, see lamportPollInbox
        const int64_t mine  = (int64_t)round * ngpus * slot + tid;
        const u32x4* inbox  = reinterpret_cast<const u32x4*>(own) + mine;
        u32x4 scratch[ngpus];
        uint32_t esc[ngpus];
        bool pending;
        do
        {
            asm volatile("" ::: "memory");
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
            {
                scratch[g] = lamportLoadB128(inbox + (int64_t)g * slot);
                esc[g]     = Codec::loadEscape(own_escape, mine + (int64_t)g * slot);
            }
            __builtin_amdgcn_sched_barrier(0);
            uint32_t m = 0;
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
            {
                // computed for every g, then selected: `g == rank ? 0 :
                // pending(...)` turns into a branch that serializes the loads
                const uint32_t gm = Codec::pending(scratch[g], esc[g]);
                m |= g == rank ? 0u : gm;
            }
            pending = m != 0;
        } while(pending);

#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            if(g != rank)
            {
                out[g * step] = scratch[g];
                Codec::releaseEscape(own_escape, mine + (int64_t)g * slot, esc[g]);
            }
    }

    const u32x4 sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
#pragma unroll
    for(int g = 0; g < ngpus; ++g)
        if(g != rank)
            lamportStoreB128(reinterpret_cast<u32x4*>(own) + (int64_t)(rearm * ngpus + g) * slot + tid, sentinel);

    if(threadIdx.x % kLamportWave == 0)
        round_counter[wave] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx1250
