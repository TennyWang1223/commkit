#include "commkit/host.hpp"
#include "gfx1250/kernel/all_gather/pull/simple_pull_vec.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

std::vector<ScratchSpec> scratchSpec(int64_t, int) { return {{"signal", signalBytes(0), true, true, 0}}; }

void launch(const std::vector<int64_t>& inp_peers,
            const std::vector<int64_t>& sig_peers,
            int64_t out,
            int64_t numel,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData dp    = toPeers<RankData>(inp_peers);
    const RankSignals sg = toPeers<RankSignals>(sig_peers);
    CK_DISPATCH_FLOAT(dtype, T, {
        const int size        = (int)(numel / (16 / sizeof(T))); // packs
        constexpr int threads = 256;
        const int blocks      = std::min(kMaxBlocks, (size + threads - 1) / threads);
        CK_DISPATCH_NGPUS(world_size, NG, {
            agSimplePullVec<T, NG><<<blocks, threads, 0, toStream(stream)>>>(
                dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, size);
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
