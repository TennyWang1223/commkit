#include "commkit/host.hpp"
#include "gfx1250/kernel/all_reduce_rmsnorm/pull/simple_pull_1shot.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

std::vector<ScratchSpec> scratchSpec(int64_t, int) { return {{"signal", signalBytes(0), true, true, 0}}; }

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
    CK_DISPATCH_HALF(dtype, T, {
        constexpr int pack_size = 16 / sizeof(T);
        // a block per row: a thread a pack, rounded up to whole 64-thread groups
        const int threads = ((int)(hidden / pack_size) + 63) / 64 * 64;
        const int blocks  = (int)std::min<int64_t>(rows, kMaxBlocks);
        CK_DISPATCH_NGPUS(world_size, NG, {
            auto kernel = gemma_norm ? arRmsSimplePull<T, NG, true>
                                     : arRmsSimplePull<T, NG, false>;
            kernel<<<blocks, threads, 0, toStream(stream)>>>(dp,
                                                             sg,
                                                             sg.ptrs[rank],
                                                             rank,
                                                             toPtr<const T>(residual),
                                                             toPtr<T>(residual_out),
                                                             toPtr<T>(out),
                                                             toPtr<const T>(weight),
                                                             (int)rows,
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
