#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce/pull/simple_pull_1shot_naive.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int)
{
    return {{"signal", signalBytes(0), true, true, 0}};
}

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
        const int size = (int)(numel / (16 / sizeof(T))); // packs
        CK_DISPATCH_NGPUS(world_size, NG, {
            // the vLLM launch: one pack per thread, at most 16 blocks
            const int blocks = std::min(16, (size + kSimpleThreads - 1) / kSimpleThreads);
            arOneShotSimplePullNaive<T, NG><<<blocks, kSimpleThreads, 0, toStream(stream)>>>(
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
