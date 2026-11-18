#include "commkit/host.hpp"
#include "gfx9/kernel/all_gather/pull/simple_pull.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

std::vector<ScratchSpec> scratchSpec(int64_t, int) { return {{"signal", signalBytes(0), true, true, 0}}; }

// last_dim: elements of the input's last dim when gathering along it, else 0
void launch(const std::vector<int64_t>& inp_peers,
            const std::vector<int64_t>& sig_peers,
            int64_t out,
            int64_t numel,
            int64_t last_dim,
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
            constexpr int tnum_gpu = kSimpleThreads / NG;
            const int blocks       = std::min(kMaxBlocks, (size + tnum_gpu - 1) / tnum_gpu);
            if(last_dim == 0)
                agSimplePull<T, NG><<<blocks, kSimpleThreads, 0, toStream(stream)>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, size);
            else
                agSimplePullLastDim<T, NG><<<blocks, kSimpleThreads, 0, toStream(stream)>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, size, (int)last_dim);
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
