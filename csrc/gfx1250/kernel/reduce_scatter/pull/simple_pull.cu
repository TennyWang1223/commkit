#include "commkit/host.hpp"
#include "gfx1250/kernel/reduce_scatter/pull/simple_pull.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

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
    CK_DISPATCH_FLOAT(dtype, T, {
        constexpr int pack_size = 16 / sizeof(T);
        CK_DISPATCH_NGPUS(world_size, NG, {
            if(m == 1)
            {
                const int range  = (int)(n * k / (NG * pack_size));
                const int blocks = std::min(kMaxBlocks, (range + 511) / 512);
                rsSimplePullFirstDim<T, NG><<<blocks, 512, 0, s>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, range);
            }
            else if(k == 1)
            {
                const int size   = (int)(m * n / (NG * pack_size));
                const int blocks = std::min(kMaxBlocks, (size + 255) / 256);
                rsSimplePullLastDim<T, NG><<<blocks, 256, 0, s>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, (int)m, (int)n);
            }
            else
            {
                const int size   = (int)(m * n * k / (NG * pack_size));
                const int blocks = std::min(kMaxBlocks, (size + 255) / 256);
                rsSimplePullMidDim<T, NG><<<blocks, 256, 0, s>>>(
                    dp, sg, sg.ptrs[rank], toPtr<T>(out), rank, (int)m, (int)n, (int)k);
            }
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
