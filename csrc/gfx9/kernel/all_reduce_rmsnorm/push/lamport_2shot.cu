#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce_rmsnorm/push/lamport_2shot.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// inbox: the reduce inbox, then the broadcast inbox, each
// [kLamportBuffers][kLamportArRms2MaxRows][kLamportArRms2SlotPacks] of 16B,
// armed with the sentinel; per row a round counter and, per buffer, the row
// length it got (what the re-arm clears)
std::vector<ScratchSpec> scratchSpec(int64_t, int)
{
    return {
        {"inbox", 2 * lamportArRms2InboxBytes(), true, true, 0xff},
        {"row_round", kLamportArRms2MaxRows * (int64_t)sizeof(uint32_t), false, false, 0},
        {"row_written", kLamportArRms2MaxRows * kLamportBuffers * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

// split: blocks per row (1 / 2 / 4)
template <typename T, int NG>
void launchSplit(int split, int64_t rows, int row_packs, hipStream_t stream,
                 const T* input, const T* residual, T* residual_out, T* output, const T* weight,
                 const LamportPeers& peers, uint32_t* row_round, uint32_t* row_written, int rank,
                 int hidden, float eps, bool gemma_norm)
{
    switch(split)
    {
#define CK_TS_SPLIT(SP)                                                                         \
    case SP:                                                                                    \
        arRmsTwoShotLamport<T, NG, SP><<<(int)rows * SP, row_packs / SP, 0, stream>>>( \
            input, residual, residual_out, output, weight, peers, row_round, row_written, rank,  \
            hidden, eps, gemma_norm);                                                           \
        break;
        CK_TS_SPLIT(1)
        CK_TS_SPLIT(2)
        CK_TS_SPLIT(4)
#undef CK_TS_SPLIT
    default: throw std::invalid_argument("split must be 1, 2 or 4");
    }
}

void launch(int64_t inp,
            int64_t residual,
            int64_t weight,
            int64_t out,
            int64_t residual_out,
            int64_t rows,
            int64_t hidden,
            double eps,
            bool gemma_norm,
            const std::vector<int64_t>& inbox_peers,
            int64_t row_round,
            int64_t row_written,
            int split,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    CK_DISPATCH_HALF(dtype, T, {
        const int row_packs = (int)(hidden / (16 / sizeof(T)));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchSplit<T, NG>(split, rows, row_packs, toStream(stream), toPtr<const T>(inp),
                               toPtr<const T>(residual), toPtr<T>(residual_out), toPtr<T>(out),
                               toPtr<const T>(weight), peers, toPtr<uint32_t>(row_round),
                               toPtr<uint32_t>(row_written), rank, (int)hidden, (float)eps, gemma_norm);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    m.attr("max_rows")  = kLamportArRms2MaxRows;
    m.attr("max_bytes") = (int64_t)kLamportArRms2MaxRows * kLamportRmsMaxRowPacks * 16;
}
