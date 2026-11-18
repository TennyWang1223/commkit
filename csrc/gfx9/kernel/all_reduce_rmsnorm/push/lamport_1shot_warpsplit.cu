#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce_rmsnorm/push/lamport_1shot_warpsplit.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// inbox / round: the one-shot all-reduce's layout, this kernel's own. The
// sum-of-squares partials of a row split over blocks are per hidden size,
// allocated by Python (partials_bytes / partial_round_bytes).
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"inbox", lamportInboxBytes(world_size), true, true, 0xff},
        {"round", kLamportMaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

// groups: 64-position groups per block, ngpus * groups <= 16
template <typename T, int NG>
void launchGroups(int groups, int64_t packs, hipStream_t stream,
                  const T* input, const T* residual, T* residual_out, T* output, const T* weight,
                  const LamportPeers& peers, uint32_t* inbox_round, uint32_t* partials,
                  uint32_t* partial_round, int rank, int hidden, float eps, bool gemma_norm)
{
    switch(groups)
    {
#define CK_WS_GROUPS(GR)                                                                            \
    case GR:                                                                                        \
        if constexpr(NG * GR <= 16)                                                                 \
        {                                                                                           \
            arRmsOneShotLamportWarpSplit<T, NG, GR>                                    \
                <<<(int)(packs / (GR * kLamportWaveSize)), NG * GR * kLamportWaveSize, 0, stream>>>( \
                    input, residual, residual_out, output, weight, peers, inbox_round, partials,     \
                    partial_round, rank, hidden, eps, gemma_norm);                                  \
            return;                                                                                 \
        }                                                                                           \
        break;
        CK_WS_GROUPS(1)
        CK_WS_GROUPS(2)
        CK_WS_GROUPS(4)
        CK_WS_GROUPS(8)
#undef CK_WS_GROUPS
    }
    throw std::invalid_argument("groups must be 1, 2, 4 or 8 with world_size * groups <= 16");
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
            int groups,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    CK_DISPATCH_HALF(dtype, T, {
        const int64_t packs = rows * (hidden / (16 / (int64_t)sizeof(T)));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchGroups<T, NG>(groups, packs, toStream(stream), toPtr<const T>(inp),
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
