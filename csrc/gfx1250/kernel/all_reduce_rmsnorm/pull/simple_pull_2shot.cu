#include "commkit/host.hpp"
#include "gfx1250/kernel/all_reduce_rmsnorm/pull/simple_pull_2shot.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

// tmp: this rank's reduced shard of every row, max_bytes / world_size
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int world_size)
{
    const int64_t shard = (max_bytes + world_size - 1) / world_size;
    return {{"signal", signalBytes((shard + 15) / 16 * 16), true, true, 0}};
}

void launch(const std::vector<int64_t>& inp_peers,
            const std::vector<int64_t>& sig_peers,
            int64_t residual,
            int64_t weight,
            int64_t out,
            int64_t residual_out,
            int64_t rows,
            int64_t hidden,
            double eps,
            bool gemma_norm,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData dp    = toPeers<RankData>(inp_peers);
    const RankSignals sg = toPeers<RankSignals>(sig_peers);
    Signal* self_sg      = sg.ptrs[rank];
    hipStream_t s        = toStream(stream);
    CK_DISPATCH_HALF(dtype, T, {
        constexpr int pack_size = 16 / sizeof(T);
        const int packs         = (int)(hidden / pack_size);
        // the norm launch: a block per row, a thread a pack, rounded up to
        // whole 64-thread groups
        const int threads = (packs + 63) / 64 * 64;
        const int blocks  = (int)std::min<int64_t>(rows, kMaxBlocks);
        CK_DISPATCH_NGPUS(world_size, NG, {
            startSyncKernel<NG><<<1, 64, 0, s>>>(sg, self_sg, rank);
            arRmsTwoShotSimplePullReduce<T, NG><<<blocks, 512, 0, s>>>(dp, self_sg, rank, (int)rows, packs);
            endSyncKernel<NG><<<1, 64, 0, s>>>(sg, self_sg, rank);
            auto norm = gemma_norm ? arRmsSimplePull<T, NG, true, true>
                                   : arRmsSimplePull<T, NG, false, true>;
            norm<<<blocks, threads, 0, s>>>(RankData{},
                                            sg,
                                            self_sg,
                                            rank,
                                            toPtr<const T>(residual),
                                            toPtr<T>(residual_out),
                                            toPtr<T>(out),
                                            toPtr<const T>(weight),
                                            (int)rows,
                                            (int)hidden,
                                            (float)eps);
            endSyncKernel<NG><<<1, 64, 0, s>>>(sg, self_sg, rank);
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
