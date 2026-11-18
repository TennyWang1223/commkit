#pragma once
// gfx9 LL protocol. A 16-byte line carries 8 bytes of data as two (4B data,
// 4B flag) pairs; the flag is the call's epoch, so a line has arrived when
// both of its flags match and no barrier is needed. Stores and loads are one
// 16-byte nontemporal transaction (global_store / load_dwordx4 nt) on the
// uncached FIFO.
//
// Scratch: an uncached IPC FIFO [2 banks][ngpus source ranks][slot lines],
// bank = epoch parity, so consecutive calls never share a bank; and a
// rank-local per-block epoch array (graph safe: the kernel bumps it).
#include "gfx9/proto/arch.cuh"

namespace commkit::gfx9 {

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
    union
    {
        u32x4 v;
        uint32_t w[4];
    } u;
    u.w[0] = a0;
    u.w[1] = a1;
    u.w[2] = a2;
    u.w[3] = a3;
    __builtin_nontemporal_store(u.v, reinterpret_cast<u32x4*>(dst));
    asm volatile("" ::: "memory");
}

DINLINE void llLoadB128(const uint32_t* src, uint32_t& o0, uint32_t& o1, uint32_t& o2, uint32_t& o3)
{
    asm volatile("" ::: "memory");
    union
    {
        u32x4 v;
        uint32_t w[4];
    } u;
    u.v = __builtin_nontemporal_load(reinterpret_cast<u32x4*>(const_cast<uint32_t*>(src)));
    o0  = u.w[0];
    o1  = u.w[1];
    o2  = u.w[2];
    o3  = u.w[3];
}

// Next epoch of a block. Never 0 (a cleared FIFO), and the wrap goes to 2 so
// the bank (epoch parity) still alternates.
DINLINE uint32_t llNextEpoch(uint32_t epoch)
{
    const uint32_t next = epoch + 1u;
    return next == 0u ? 2u : next;
}

} // namespace commkit::gfx9
