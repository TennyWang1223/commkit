#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce/push/ll128_1shot.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// fifo: [2 banks][ngpus][kLL128SlotStride words], sized for kLL128MaxBytes
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"fifo", 2 * world_size * (int64_t)kLL128SlotStride * 4, true, true, 0},
        {"epoch", kLL128MaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <typename T, int NG>
void launchBlock(int block, int blocks, hipStream_t stream, int64_t inp, int64_t out, const RankData& fifo,
                 int64_t epoch, int rank, int numel)
{
    switch(block)
    {
#define CK_LL128_BLOCK(BS)                                                                  \
    case BS:                                                                                \
        arOneShotLL128<T, NG, BS><<<blocks, BS, 0, stream>>>(                      \
            toPtr<const T>(inp), toPtr<T>(out), fifo, toPtr<uint32_t>(epoch), rank, numel); \
        break;
        CK_LL128_BLOCK(256)
        CK_LL128_BLOCK(512)
        CK_LL128_BLOCK(1024)
#undef CK_LL128_BLOCK
    default: throw std::invalid_argument("block must be 256, 512 or 1024");
    }
}

void launch(int64_t inp,
            int64_t out,
            int64_t numel,
            const std::vector<int64_t>& fifo_peers,
            int64_t epoch,
            int block,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData fifo = toPeers<RankData>(fifo_peers);
    CK_DISPATCH_HALF(dtype, T, {
        const int64_t bytes       = numel * (int64_t)sizeof(T);
        const int total_group     = (int)((bytes + kLL128GroupBytes - 1) / kLL128GroupBytes);
        const int groups_per_bk   = block / 8;
        const int blocks          = std::max(1, std::min(kLL128MaxBlocks, (total_group + groups_per_bk - 1) / groups_per_bk));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchBlock<T, NG>(block, blocks, toStream(stream), inp, out, fifo, epoch, rank, (int)numel);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    m.attr("max_bytes") = (int64_t)kLL128MaxBytes;
}
