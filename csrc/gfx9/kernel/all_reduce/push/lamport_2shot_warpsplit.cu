#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce/push/lamport_2shot_warpsplit.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// inbox: the reduce-scatter inbox, then the all-gather inbox, each
// [kLamportBuffers][ngpus][lamportTwoShotMaxPart(ngpus)] of 16B, armed with
// the sentinel; round: a counter per 64-position block of a chunk
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"inbox", 2 * lamportTwoShotInboxBytes(world_size), true, true, 0xff},
        {"round", lamportTwoShotMaxBlocks(world_size) * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

void launch(int64_t inp,
            int64_t out,
            int64_t numel,
            const std::vector<int64_t>& inbox_peers,
            int64_t round,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    CK_DISPATCH_HALF(dtype, T, {
        const int part       = (int)(numel * (int64_t)sizeof(T) / 16 / world_size); // packs per chunk
        const int num_blocks = (part + kLamportWaveSize - 1) / kLamportWaveSize;
        CK_DISPATCH_NGPUS(world_size, NG, {
            arTwoShotLamportWarpSplit<T, NG><<<num_blocks, NG * kLamportWaveSize, 0, toStream(stream)>>>(
                toPtr<const T>(inp), toPtr<T>(out), peers, toPtr<uint32_t>(round), rank, part);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    m.attr("max_bytes") = (int64_t)kLamportTwoShotMaxBytes;
}
