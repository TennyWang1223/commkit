#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce/push/simple_push_2shot.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// tmp: the peers' chunks of this rank's slot, then (from max_bytes on) the
// gathered sums
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int)
{
    return {{"signal", signalBytes(2 * max_bytes), true, true, 0}};
}

void launch(int64_t inp,
            const std::vector<int64_t>& sig_peers,
            int64_t max_bytes,
            int64_t out,
            int64_t numel,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankSignals sg = toPeers<RankSignals>(sig_peers);
    CK_DISPATCH_FLOAT(dtype, T, {
        const int size = (int)(numel / (16 / sizeof(T))); // packs
        CK_DISPATCH_NGPUS(world_size, NG, {
            constexpr int tnum_gpu = kSimpleThreads / NG;
            const int blocks       = std::min(kMaxBlocks, (size / NG + tnum_gpu - 1) / tnum_gpu);
            arTwoShotSimplePush<T, NG><<<blocks, kSimpleThreads, 0, toStream(stream)>>>(
                toPtr<const T>(inp), sg, sg.ptrs[rank], toPtr<T>(out), rank, size, (int)(max_bytes / 16));
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
