#pragma once
// all_gather, lamport proto, push, exact codec (aiter lamport_ag_gfx1250 with
// LamportAgEscape): the lamport all-gather of lamport.cuh, bit for bit
// for any dtype.
#include "gfx1250/kernel/all_gather/push/lamport.cuh"

namespace commkit::gfx1250 {

// Words are sent as is, and an all-ones word is also flagged in the escape
// inbox (bit j: word j is 0xffffffff), armed with 0. A word has arrived once it
// is not all ones or its escape bit is set, so only 4-byte stores need to be
// single-copy atomic. The mask is written only for a pack that holds an
// all-ones word, and the receiver then must have seen it to resolve the pack,
// so it re-arms it right away, in the current round, not with the delayed
// re-arm of the data inbox (in aiter other lamport kernels, which never touch
// the escape inbox, advanced the same round counters). The kernel boundary
// orders that re-arm before this rank's next sends, and the sender's next
// write to that mask is three rounds later.
struct LamportAgEscape
{
    static constexpr uint32_t kOnes = 0xffffffffu;

    static DINLINE uint32_t encode(u32x4& v)
    {
        uint32_t esc = 0;
#pragma unroll
        for(int j = 0; j < 4; ++j)
            esc |= v[j] == kOnes ? 1u << j : 0u;
        return esc;
    }
    static DINLINE void publishEscape(uint32_t* peer, int64_t at, uint32_t esc)
    {
        if(esc != 0)
            __scoped_atomic_store_n(peer + at, esc, __ATOMIC_RELAXED, __MEMORY_SCOPE_SYSTEM);
    }
    static DINLINE uint32_t loadEscape(const uint32_t* own, int64_t at)
    {
        return __scoped_atomic_load_n(own + at, __ATOMIC_RELAXED, __MEMORY_SCOPE_SYSTEM);
    }
    static DINLINE uint32_t pending(const u32x4& v, uint32_t esc)
    {
        uint32_t m = 0;
#pragma unroll
        for(int j = 0; j < 4; ++j)
            m |= v[j] == kOnes && !((esc >> j) & 1u) ? 1u << j : 0u;
        return m;
    }
    static DINLINE void releaseEscape(uint32_t* own, int64_t at, uint32_t esc)
    {
        if(esc != 0)
            __scoped_atomic_store_n(own + at, 0u, __ATOMIC_RELAXED, __MEMORY_SCOPE_SYSTEM);
    }
};

} // namespace commkit::gfx1250
