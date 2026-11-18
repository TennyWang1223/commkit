#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce_rmsnorm/push/lamport_1shot_flat.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// inbox / round: the one-shot all-reduce's layout, this kernel's own. The
// sum-of-squares partials of a split row (block != 0) are per hidden size,
// allocated by Python (partials_bytes / partial_round_bytes).
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"inbox", lamportInboxBytes(world_size), true, true, 0xff},
        {"round", kLamportMaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

// block: 0 a row per block, else 64 / 128 / 256 packs per block
template <typename T, int NG>
void launchBlock(int block, int64_t rows, int row_packs, hipStream_t stream,
                 const T* input, const T* residual, T* residual_out, T* output, const T* weight,
                 const LamportPeers& peers, uint32_t* inbox_round, uint32_t* partials,
                 uint32_t* partial_round, int rank, int hidden, float eps, bool gemma_norm)
{
    const int64_t packs = rows * row_packs;
#define CK_FLAT_ARGS input, residual, residual_out, output, weight, peers, inbox_round, partials, \
                     partial_round, rank, hidden, eps, gemma_norm
    switch(block)
    {
    case 0:
        arRmsOneShotLamportFlat<T, NG, kLamportRmsMaxRowPacks, true>
            <<<(int)rows, row_packs, 0, stream>>>(CK_FLAT_ARGS);
        break;
#define CK_FLAT_BLOCK(BS)                                                                \
    case BS:                                                                             \
        arRmsOneShotLamportFlat<T, NG, BS, false>                           \
            <<<(int)(packs / BS), BS, 0, stream>>>(CK_FLAT_ARGS);                        \
        break;
        CK_FLAT_BLOCK(64)
        CK_FLAT_BLOCK(128)
        CK_FLAT_BLOCK(256)
#undef CK_FLAT_BLOCK
#undef CK_FLAT_ARGS
    default: throw std::invalid_argument("block must be 0 (a row), 64, 128 or 256");
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
            int64_t inbox_round,
            int64_t partials,
            int64_t partial_round,
            int block,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    CK_DISPATCH_HALF(dtype, T, {
        const int row_packs = (int)(hidden / (16 / sizeof(T)));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchBlock<T, NG>(block, rows, row_packs, toStream(stream), toPtr<const T>(inp),
                               toPtr<const T>(residual), toPtr<T>(residual_out), toPtr<T>(out),
                               toPtr<const T>(weight), peers, toPtr<uint32_t>(inbox_round),
                               toPtr<uint32_t>(partials), toPtr<uint32_t>(partial_round), rank,
                               (int)hidden, (float)eps, gemma_norm);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    m.attr("max_bytes")           = (int64_t)kLamportMaxPacks * 16;
    m.attr("partials_bytes")      = (int64_t)kLamportBuffers * kLamportRmsMaxPartials * 4;
    m.attr("partial_round_bytes") = (int64_t)kLamportMaxBlocks * 4;
}
