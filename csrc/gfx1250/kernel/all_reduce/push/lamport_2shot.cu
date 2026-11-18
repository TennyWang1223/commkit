#include "commkit/host.hpp"
#include "gfx1250/kernel/all_reduce/push/lamport_2shot.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

// slot = a rank's chunk of a max_bytes message (lamportTwoShotSlot). inbox:
// the data inbox [kLamportBuffers][ngpus][slot] of 16B, then the all-gather
// inbox [ngpus][slot], cached, armed with the sentinel; round: a counter per
// wave of 32 packs of a chunk
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int world_size)
{
    const int64_t slot = lamportTwoShotSlot(max_bytes, world_size);
    return {
        {"inbox", lamportInboxBytes(world_size, slot) + lamportTwoShotBytes(world_size, slot), true, false, 0xff},
        {"round", lamportWaves(slot) * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <typename T, int NG>
void launchBlock(int threads, int blocks, hipStream_t stream, const T* input, T* output, uint32_t* round,
                 int slot, int rank, int packs, int part, const LamportPeers& peers)
{
    switch(threads)
    {
#define CK_LAMPORT_BLOCK(B)                                                                       \
    case B:                                                                                       \
        arTwoShotLamport<T, NG, B><<<blocks, B, 0, stream>>>(input,                      \
                                                                      output,                     \
                                                                      round,                      \
                                                                      slot,                       \
                                                                      rank,                       \
                                                                      packs,                      \
                                                                      part,                       \
                                                                      peers.ptrs[0],              \
                                                                      peers.ptrs[1],              \
                                                                      peers.ptrs[2],              \
                                                                      peers.ptrs[3],              \
                                                                      peers.ptrs[4],              \
                                                                      peers.ptrs[5],              \
                                                                      peers.ptrs[6],              \
                                                                      peers.ptrs[7]);             \
        break;
        CK_LAMPORT_BLOCK(64)
        CK_LAMPORT_BLOCK(256)
        CK_LAMPORT_BLOCK(512)
#undef CK_LAMPORT_BLOCK
    default: throw std::invalid_argument("block must be 64, 256 or 512");
    }
}

// a thread a pack of a chunk; block: threads a block (64 / 256 / 512), 0 for
// aiter's choice by the chunk size (lamportBlockThreads)
void launch(int64_t inp,
            int64_t out,
            int64_t numel,
            const std::vector<int64_t>& inbox_peers,
            int64_t round,
            int64_t max_bytes,
            int block,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    const int slot           = (int)lamportTwoShotSlot(max_bytes, world_size);
    CK_DISPATCH_HALF(dtype, T, {
        const int64_t packs = numel / (16 / sizeof(T));
        const int part      = (int)((packs + world_size - 1) / world_size);
        const int threads   = block ? block : lamportBlockThreads(part);
        const int blocks    = (part + threads - 1) / threads;
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchBlock<T, NG>(threads, blocks, toStream(stream), toPtr<const T>(inp), toPtr<T>(out),
                               toPtr<uint32_t>(round), slot, rank, (int)packs, part, peers);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
}
