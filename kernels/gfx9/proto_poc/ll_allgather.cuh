#pragma once

#include <hip/hip_runtime.h>

#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "commkit/tmp_buf.cuh"
#include "opus/opus.hpp"

// =============================================================================
// LL-proto allgather (low-latency protocol, RCCL-faithful)
//
// This is the simplest possible collective to exercise the LL protocol: pure
// copy, no reduction. Each rank owns `part` contiguous elements of a `size`-
// element buffer (rank r owns [r*part, (r+1)*part)); after the collective every
// rank holds the full `size` elements in `result`.
//
// Why LL differs from the "simple" protocol used by the other kernels here
// (start_sync -> cross-device read -> end_sync):
//
//   In the simple protocol, data and the synchronization flag are SEPARATE. A
//   producer writes its payload, issues a system fence, then bumps a distinct
//   flag; the consumer barriers on the flag, then reads the payload. That needs
//   an explicit fence between the two writes and a barrier round-trip.
//
//   In LL, data and flag live in the SAME 128-bit line and are published by a
//   single 16-byte store. The consumer spin-loads the line and, once the flag
//   fields match the current epoch, KNOWS the payload in the same line is
//   valid. Correctness rests on 8-byte store atomicity: each (data,flag) u32
//   pair sits in one aligned u64, so a reader can never observe the new flag
//   with stale data. No separate fence, no barrier round-trip -> lower latency
//   for small messages.
//
// Layout of one FIFO line (verbatim from RCCL src/include/device.h):
//
//   union ncclLLFifoLine { struct{u32 data1,flag1,data2,flag2;}; u64 v[2]; };
//
// The flags are placed AFTER their data halves so a torn read can only ever
// yield a stale flag (spin again), never new-flag/old-data.
// =============================================================================

namespace commkit::kernels {

constexpr int kThreadNumLL = 256;

// Double-buffered FIFO: consecutive calls alternate between kLLFifoSlots copies
// of the FIFO so call N+1 never writes the lines call N is still consuming --
// this replaces the per-call start_sync rendezvous. k=2 is provably sufficient
// here: same-stream serialization + the consume-phase spin + single-consumer
// (owner-only) FIFOs together bound the cross-rank skew to one call, so by the
// time a slot is reused (2 epochs later) its previous user has finished reading.
constexpr int kLLFifoSlots = 2;

// 16-byte FIFO line: 8 bytes of payload interleaved with two 4-byte flags.
union LLFifoLine {
    struct {
        uint32_t data1;
        uint32_t flag1;
        uint32_t data2;
        uint32_t flag2;
    };
    uint64_t v[2];
};

// storeLL: publish (val, flag) as one 128-bit line. The four u32 lanes are laid
// out data1/flag1/data2/flag2 so each (data,flag) pair shares an aligned 64-bit
// half; a peer can therefore never observe a new flag next to stale data (the
// atomicity guarantee the LL protocol rests on). System scope (sc0 sc1) writes
// through to the consumer GPU's memory rather than parking in local L2. Mirrors
// RCCL storeLL and the cross-device stores in car_wt_llproto.
__device__ __forceinline__ void store_LL(LLFifoLine* dst, uint64_t val, uint32_t flag) {
    using v4u = uint32_t __attribute__((ext_vector_type(4)));
    v4u v;
    v[0] = static_cast<uint32_t>(val & 0xffffffffu);
    v[1] = flag;
    v[2] = static_cast<uint32_t>(val >> 32);
    v[3] = flag;
    asm volatile("global_store_dwordx4 %0, %1, off sc0 sc1\n\t" ::"v"(dst), "v"(v)
                 : "memory");
}

// readLL: spin-load a line until both flags equal `flag`, then return its 8-byte
// payload. Mirrors RCCL readLL: the producer's line arrives from another GPU, so
// each poll must bypass L2 and re-fetch from memory, otherwise the first cached
// read of a not-yet-written (or stale) line would loop forever / return garbage.
// The GFX11 RCCL path uses `global_load_b128 glc slc dlc`; the gfx942 equivalent
// here is a 128-bit system-scope load (sc1) followed by buffer_inv sc1, the same
// invalidating-read pattern used by end_sync_asm and car_wt_llproto.
__device__ __forceinline__ uint64_t read_LL(LLFifoLine* src, uint32_t flag) {
    // Poll the whole 16-byte line with one L2-bypassing, cache-invalidating
    // 128-bit load (`global_load_dwordx4 sc1 nt` + `buffer_inv sc1`, the gfx942
    // analogue of RCCL's `global_load_b128 glc slc dlc`). The line is 16B-aligned
    // and read_LL never reads past the last written line, so a single x4 covers
    // both flags and both data lanes at once -- no per-lane serialization.
    using v4u = uint32_t __attribute__((ext_vector_type(4)));
    v4u v;
    do {
        asm volatile("global_load_dwordx4 %0, %1, off sc1 nt\n\t"
                     "s_waitcnt vmcnt(0)\n\t"
                     "buffer_inv sc1\n\t"
                     : "=v"(v) : "v"(src) : "memory");
    } while (v[1] != flag || v[3] != flag);
    // Flags matched -> data1 (v[0]) and data2 (v[2]) in the same line are valid.
    return static_cast<uint64_t>(v[0]) | (static_cast<uint64_t>(v[2]) << 32);
}

// FIFO base inside a rank's meta scratch (the region right after Signal, same
// tail reused by the 2-stage kernels). Laid out as ngpus contiguous segments of
// `lines_per_seg` lines: segment s holds the payload produced by rank s.
__device__ __forceinline__ LLFifoLine* ll_fifo(Signal* sg) {
    return get_tmp_buf<LLFifoLine>(sg);
}

// -----------------------------------------------------------------------------
// LL allgather kernel.
//
//   _input_dp->ptrs[r] : rank r's input base (peer-visible), T elements
//   sg.signals[r]      : rank r's Signal (its scratch holds rank r's FIFO)
//   self_sg            : this rank's Signal
//   result             : this rank's output, `size` T elements
//   size               : total element count (multiple of ngpus)
//
// Each rank streams its own `part`-element slice, LL-encodes it, and publishes
// it into segment `rank` of EVERY peer's FIFO (including its own). It then reads
// all ngpus segments out of its own FIFO and scatters them to the right place in
// `result`. Because the flag is carried in-line, there is no separate barrier
// between produce and consume.
// -----------------------------------------------------------------------------
template <typename T, int ngpus>
__global__ void __launch_bounds__(kThreadNumLL, 1)
ll_allgather(RankData* _input_dp, RankSignals sg, Signal* self_sg,
             T* __restrict__ result, int rank, int size) {
    constexpr int EPL = sizeof(uint64_t) / sizeof(T);  // elts per line
    int tid    = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = gridDim.x * blockDim.x;

    int part      = size / ngpus;         // elements this rank owns
    int seg_lines = part / EPL;           // lines per rank segment (part % EPL == 0)

    // Monotonic per-block epoch: this call's flag. Never reset, never cleared ->
    // stale lines from prior calls carry an older flag and are ignored by
    // read_LL. Must increment per block (not just block 0), because with
    // start_sync removed the flag is the ONLY thing distinguishing a fresh line
    // from a stale one for blocks 1..N.
    uint32_t flag = self_sg->ll_epoch[blockIdx.x] + 1;

    // Double-buffer: alternate slots per call so this call cannot overwrite the
    // FIFO lines the previous call may still be consuming. slot_lines is the
    // stride of one full FIFO copy (ngpus segments); slot picks which copy.
    int slot_lines = ngpus * seg_lines;
    int slot_off   = static_cast<int>((flag - 1) % kLLFifoSlots) * slot_lines;

    // My owned slice lives at offset rank*part in my own input buffer.
    const T* my_slice = reinterpret_cast<const T*>(_input_dp->ptrs[rank]) + rank * part;

    // Peers' FIFO bases; segment `rank` in this call's slot is my publish target.
    LLFifoLine* peer_fifo[ngpus];
#pragma unroll
    for (int i = 0; i < ngpus; ++i) {
        peer_fifo[i] = ll_fifo(sg.signals[i]) + slot_off + rank * seg_lines;
    }

    // ---- produce: LL-encode my slice into segment `rank` of every peer ----
    for (int line = tid; line < seg_lines; line += stride) {
        // Gather EPL elements (8 bytes) of my input into one u64 payload.
        uint64_t payload = *reinterpret_cast<const uint64_t*>(my_slice + line * EPL);
#pragma unroll
        for (int i = 0; i < ngpus; ++i) {
            store_LL(peer_fifo[i] + line, payload, flag);
        }
    }

    // Flush my cross-device stores out of L2 to the peers' memory before any
    // consumer polls for the flag. Without this the write-through stores can sit
    // in L2 and the peer's invalidating load spins forever. Same system fence
    // car_wt_llproto issues between its stage-1 stores and the flag signal.
    asm volatile("s_waitcnt vmcnt(0) lgkmcnt(0)\n\t"
                 "buffer_wbl2 sc0 sc1\n\t"
                 "s_waitcnt vmcnt(0)\n\t" ::: "memory");

    // ---- consume: read every segment out of my own FIFO, scatter to result --
    LLFifoLine* my_fifo = ll_fifo(self_sg) + slot_off;
    for (int line = tid; line < seg_lines; line += stride) {
#pragma unroll
        for (int src = 0; src < ngpus; ++src) {
            uint64_t payload = read_LL(my_fifo + src * seg_lines + line, flag);
            int out_elt = src * part + line * EPL;
            *reinterpret_cast<uint64_t*>(result + out_elt) = payload;
        }
    }

    // Advance this block's epoch. Per-block (threadIdx.x==0 in each block), not
    // the global tid==0, so every block's flag tracks its own call count.
    if (threadIdx.x == 0) {
        self_sg->ll_epoch[blockIdx.x] = flag;
    }
}

template <typename T, int ngpus>
inline void launch_ll_allgather(RankData* in_dp, RankSignals sg, Signal* self_sg,
                                T* result, int rank, int size, int grid,
                                hipStream_t stream) {
    ll_allgather<T, ngpus>
        <<<grid, kThreadNumLL, 0, stream>>>(in_dp, sg, self_sg, result, rank, size);
}

}  // namespace commkit::kernels
