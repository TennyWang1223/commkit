#pragma once
// gfx1250 simple protocol: data moves with plain loads / stores between IPC
// buffers, ordering comes from per-block flag barriers (start / end sync).
//
// Scratch: one uncached IPC buffer per kernel, a Signal followed by the
// kernel's tmp region (getTmpBuf). Pull kernels read the peers' input staging
// buffers (RankData) in place.
#include "gfx1250/proto/arch.cuh"

namespace commkit::gfx1250 {

// aiter gfx1250's Signal rows: a 64-entry (256-byte) row of flags per block.
// aiter sized the rows for its 64-rank all-gather; commkit keeps the layout
// and uses the first world-size entries of a row.
constexpr int kSignalRanks = 64;

// No atomics on the flags: peer atomics are not supported on PCIe links.
struct Signal
{
    alignas(128) uint32_t start[kMaxBlocks][kSignalRanks];
    alignas(128) uint32_t end[kMaxBlocks][kSignalRanks];
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
        __scoped_atomic_store_n(
            &sg.ptrs[threadIdx.x]->start[blockIdx.x][rank], flag, __ATOMIC_RELAXED, __MEMORY_SCOPE_SYSTEM);
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

// One-block barrier launches (aiter start_sync_kernel / end_sync_kernel) that
// order the launches of a multi-launch kernel; they use block 0's flags.
template <int ngpus>
__global__ void startSyncKernel(RankSignals sg, Signal* self_sg, int rank)
{
    startSync<ngpus>(sg, self_sg, rank);
}

template <int ngpus>
__global__ void endSyncKernel(RankSignals sg, Signal* self_sg, int rank)
{
    endSync<ngpus>(sg, self_sg, rank);
}

} // namespace commkit::gfx1250
