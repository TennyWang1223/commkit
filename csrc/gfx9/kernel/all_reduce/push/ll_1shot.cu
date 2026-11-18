#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce/push/ll_1shot.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// fifo: [2 banks][ngpus][max_bytes / 8 lines of 16B]; epochs: per block
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int world_size)
{
    const int64_t slot_lines = max_bytes / 8;
    return {
        {"fifo", 2 * world_size * slot_lines * (int64_t)sizeof(LLLine), true, true, 0},
        {"epoch", kMaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <typename T, int NG>
void launchBlock(int block, int blocks, hipStream_t stream, const RankData& fifo, int64_t inp, int64_t out,
                 size_t n_pk, int rank, int64_t epoch, size_t slot)
{
    switch(block)
    {
#define CK_LL_BLOCK(BS)                                                                     \
    case BS:                                                                                \
        arOneShotLL<T, NG, BS><<<blocks, BS, 0, stream>>>(                         \
            fifo, toPtr<T>(out), toPtr<const T>(inp), n_pk, rank, toPtr<uint32_t>(epoch), slot); \
        break;
        CK_LL_BLOCK(256)
        CK_LL_BLOCK(512)
        CK_LL_BLOCK(1024)
#undef CK_LL_BLOCK
    default: throw std::invalid_argument("block must be 256, 512 or 1024");
    }
}

void launch(int64_t inp,
            int64_t out,
            int64_t numel,
            const std::vector<int64_t>& fifo_peers,
            int64_t epoch,
            int64_t max_bytes,
            int block,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData fifo = toPeers<RankData>(fifo_peers);
    CK_DISPATCH_FLOAT(dtype, T, {
        const size_t n_pk = (size_t)numel * sizeof(T) / 8;
        const int blocks  = std::max(1, std::min<int>(kMaxBlocks, (int)((n_pk + block - 1) / block)));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchBlock<T, NG>(block, blocks, toStream(stream), fifo, inp, out, n_pk, rank, epoch, (size_t)max_bytes / 8);
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
