#pragma once
// gfx9 simple protocol: data moves with plain loads / stores between IPC
// buffers, ordering comes from per-block flag barriers (start / end sync).
//
// Scratch: one uncached IPC buffer per kernel, a Signal followed by the
// kernel's tmp region (getTmpBuf). Pull kernels also read the peers' input
// staging buffers (RankData), push kernels write into the peers' tmp.
#include "gfx9/proto/arch.cuh"

namespace commkit::gfx9 {

// block size of the warp-split simple kernels: 512 / ngpus threads per peer
constexpr int kSimpleThreads = 512;

// No atomics on the flags: peer atomics are not supported on PCIe links.
struct Signal
{
    alignas(128) uint32_t start[kMaxBlocks][kMaxRanks];
    alignas(128) uint32_t end[kMaxBlocks][kMaxRanks];
    alignas(128) uint32_t flag[kMaxBlocks]; // per-block barrier generation, rank-local
};

struct __align__(16) RankSignals
{
    Signal* ptrs[kMaxRanks];
};

// bytes of the Signal + tmp scratch buffer
inline constexpr int64_t signalBytes(int64_t tmp_bytes) { return (int64_t)sizeof(Signal) + tmp_bytes; }

// The tmp region follows the Signal in the same buffer.
template <typename P>
DINLINE P* getTmpBuf(Signal* sg)
{
    return reinterpret_cast<P*>(sg + 1);
}

// First barrier of a kernel: every rank's block b has started. Makes no
// visibility guarantee for earlier memory accesses.
template <int ngpus>
DINLINE void startSync(const RankSignals& sg, Signal* self_sg, int rank)
{
    uint32_t flag = self_sg->flag[blockIdx.x] + 1;
    if(threadIdx.x < ngpus)
    {
        // write to every rank at once: latency = 1 p2p write
        __scoped_atomic_store_n(
            &sg.ptrs[threadIdx.x]->start[blockIdx.x][rank], flag, __ATOMIC_RELAXED, __MEMORY_SCOPE_SYSTEM);
        // wait until every rank's flag arrived
        while(__scoped_atomic_load_n(
                  &self_sg->start[blockIdx.x][threadIdx.x], __ATOMIC_RELAXED, __MEMORY_SCOPE_DEVICE) < flag)
            ;
    }
    __syncthreads();
    if(threadIdx.x == 0)
        self_sg->flag[blockIdx.x] = flag;
}

// Second or final barrier. A final one makes no visibility guarantee for
// earlier accesses; a middle one releases this block's stores to the peers
// and acquires theirs.
template <int ngpus, bool final_sync = false>
DINLINE void endSync(const RankSignals& sg, Signal* self_sg, int rank)
{
    __syncthreads();
    uint32_t flag = self_sg->flag[blockIdx.x] + 1;
    if(threadIdx.x < ngpus)
    {
        __scoped_atomic_store_n(&sg.ptrs[threadIdx.x]->end[blockIdx.x][rank],
                                flag,
                                final_sync ? __ATOMIC_RELAXED : __ATOMIC_RELEASE,
                                __MEMORY_SCOPE_SYSTEM);
        while(__scoped_atomic_load_n(&self_sg->end[blockIdx.x][threadIdx.x],
                                     final_sync ? __ATOMIC_RELAXED : __ATOMIC_ACQUIRE,
                                     __MEMORY_SCOPE_DEVICE) < flag)
            ;
    }
    __syncthreads();
    if(threadIdx.x == 0)
        self_sg->flag[blockIdx.x] = flag;
}

} // namespace commkit::gfx9
