#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce_rmsnorm/pull/simple_pull_2shot.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// tmp: the whole all-reduce result, pushed in by every rank
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int)
{
    return {{"signal", signalBytes(max_bytes), true, true, 0}};
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
    CK_DISPATCH_FLOAT(dtype, T, {
        using P           = typename opus::vector_t<T, 16 / sizeof(T)>;
        const int threads = (int)(hidden * sizeof(T) / 16); // a block per row, a thread per pack
        const int blocks  = (int)std::min<int64_t>(rows, kMaxBlocks);
        CK_DISPATCH_NGPUS(world_size, NG, {
            auto kernel = gemma_norm ? arRmsTwoShotSimplePull<T, NG, true>
                                     : arRmsTwoShotSimplePull<T, NG, false>;
            kernel<<<blocks, threads, threads * sizeof(P), toStream(stream)>>>(dp,
                                                                               sg,
                                                                               sg.ptrs[rank],
                                                                               rank,
                                                                               toPtr<const T>(residual),
                                                                               toPtr<T>(residual_out),
                                                                               toPtr<T>(out),
                                                                               toPtr<const T>(weight),
                                                                               (int)(rows * hidden),
                                                                               (int)hidden,
                                                                               (float)eps);
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
