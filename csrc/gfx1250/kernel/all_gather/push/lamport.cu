#include "commkit/host.hpp"
#include "gfx1250/kernel/all_gather/push/lamport.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

// slot = max_bytes / 16 packs a sender (Python keeps max_bytes a multiple of
// 512, whole waves). inbox: [kLamportBuffers][ngpus][slot] of 16B, cached,
// armed with the sentinel; round: a counter per wave of 32 packs
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int world_size)
{
    const int64_t slot = max_bytes / 16;
    return {
        {"inbox", lamportInboxBytes(world_size, slot), true, false, 0xff},
        {"round", lamportWaves(slot) * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <int NG, int B>
void launchDim(bool dim0, int blocks, hipStream_t stream, const u32x4* input, u32x4* output, uint32_t* round,
               int slot, int rank, int packs, int row_packs, const LamportPeers& peers)
{
#define CK_LAMPORT_AG_ARGS                                                                                  \
    input, output, round, slot, rank, packs, row_packs, peers.ptrs[0], peers.ptrs[1], peers.ptrs[2],       \
        peers.ptrs[3], peers.ptrs[4], peers.ptrs[5], peers.ptrs[6], peers.ptrs[7], nullptr, nullptr, nullptr, \
        nullptr, nullptr, nullptr, nullptr, nullptr
    if(dim0)
        agLamport<LamportAgHalfSentinel, NG, B, true><<<blocks, B, 0, stream>>>(CK_LAMPORT_AG_ARGS);
    else
        agLamport<LamportAgHalfSentinel, NG, B, false><<<blocks, B, 0, stream>>>(CK_LAMPORT_AG_ARGS);
#undef CK_LAMPORT_AG_ARGS
}

// bytes: a rank's input, row_bytes: a gathered row (== bytes along dim 0),
// both whole 16B packs (Python checks). block: threads a block (64 / 256 /
// 512), 0 for aiter's choice by size (lamportBlockThreads)
void launch(int64_t inp,
            int64_t out,
            int64_t bytes,
            int64_t row_bytes,
            const std::vector<int64_t>& inbox_peers,
            int64_t round,
            int64_t max_bytes,
            int block,
            int rank,
            int world_size,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    const int slot           = (int)(max_bytes / 16);
    const int64_t packs      = bytes / 16;
    const int threads        = block ? block : lamportBlockThreads(packs);
    const int blocks         = (int)((packs + threads - 1) / threads);
    const int row_packs      = (int)(row_bytes / 16);
    const bool dim0          = row_packs == packs;
    const auto* in           = toPtr<const u32x4>(inp);
    auto* o                  = toPtr<u32x4>(out);
    uint32_t* rnd            = toPtr<uint32_t>(round);
    hipStream_t s            = toStream(stream);
    CK_DISPATCH_NGPUS(world_size, NG, {
        switch(threads)
        {
        case 64: launchDim<NG, 64>(dim0, blocks, s, in, o, rnd, slot, rank, (int)packs, row_packs, peers); break;
        case 256: launchDim<NG, 256>(dim0, blocks, s, in, o, rnd, slot, rank, (int)packs, row_packs, peers); break;
        case 512: launchDim<NG, 512>(dim0, blocks, s, in, o, rnd, slot, rank, (int)packs, row_packs, peers); break;
        default: throw std::invalid_argument("block must be 64, 256 or 512");
        }
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
}
