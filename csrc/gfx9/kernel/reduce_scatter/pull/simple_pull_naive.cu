#include "commkit/host.hpp"
#include "gfx9/kernel/reduce_scatter/pull/simple_pull_naive.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

std::vector<ScratchSpec> scratchSpec(int64_t, int) { return {{"signal", signalBytes(0), true, true, 0}}; }

// (m, n, k): the input seen as prod(shape[:dim]), shape[dim], prod(shape[dim+1:])
void launch(const std::vector<int64_t>& inp_peers,
            const std::vector<int64_t>& sig_peers,
            int64_t out,
            int64_t m,
            int64_t n,
            int64_t k,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData dp    = toPeers<RankData>(inp_peers);
    const RankSignals sg = toPeers<RankSignals>(sig_peers);
    hipStream_t s        = toStream(stream);
    const int size       = (int)(m * n * k / world_size);
    const int blocks     = std::min(kMaxBlocks, (size + 255) / 256);
    CK_DISPATCH_FLOAT(dtype, T, {
        CK_DISPATCH_NGPUS(world_size, NG, {
            if(k == 1 && m > 1)
                rsSimplePullNaiveLastDim<T, NG><<<blocks, 256, 0, s>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, (int)m, (int)n);
            else
                rsSimplePullNaiveMidDim<T, NG><<<blocks, 256, 0, s>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, (int)m, (int)n, (int)k);
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
