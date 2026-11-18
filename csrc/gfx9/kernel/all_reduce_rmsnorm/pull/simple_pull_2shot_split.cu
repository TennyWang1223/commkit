#include "commkit/host.hpp"
#include "gfx9/kernel/all_reduce_rmsnorm/pull/simple_pull_2shot_split.cuh"

using namespace commkit;
using namespace commkit::gfx9;

namespace {

// tmp: the whole all-reduce result, pushed in by every rank
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int)
{
    return {{"signal", signalBytes(max_bytes), true, true, 0}};
}

// the norm launch: a block per row (grid capped at the resident blocks),
// tnum threads looping n_loop times over the row's packs
template <typename T>
void launchNorm(Signal* self_sg,
                const T* residual,
                T* residual_out,
                T* out,
                const T* weight,
                float eps,
                int rows,
                int hidden,
                bool gemma_norm,
                hipStream_t stream)
{
    const int n_packs = hidden / (16 / sizeof(T));
    auto launchOne    = [&](auto kernel, int tnum) {
        int occupancy = 0;
        CK_HIP_CHECK(hipOccupancyMaxActiveBlocksPerMultiprocessor(
            &occupancy, reinterpret_cast<const void*>(kernel), tnum, 0));
        const int blocks = std::min(rows, numCus() * std::max(occupancy, 1));
        kernel<<<blocks, tnum, 0, stream>>>(self_sg, residual, residual_out, out, weight, eps, rows, hidden);
    };
#define CK_NORM(KERNEL, TNUM, NLOOP)                                    \
    (gemma_norm ? launchOne(KERNEL<T, TNUM, NLOOP, true>, TNUM)         \
                : launchOne(KERNEL<T, TNUM, NLOOP, false>, TNUM))
    if(n_packs < 256)
    {
        CK_NORM(arRmsTwoShotSimplePullSplitNorm, 256, 1);
        return;
    }
    const int n_loop = (n_packs + 511) / 512;
    const bool exact = n_packs == 512 * n_loop;
    switch(n_loop)
    {
#define CK_NORM_LOOP(NLOOP)                                                         \
    case NLOOP:                                                                     \
        if(exact)                                                                   \
            CK_NORM(arRmsTwoShotSimplePullSplitNormExact, 512, NLOOP);     \
        else                                                                        \
            CK_NORM(arRmsTwoShotSimplePullSplitNorm, 512, NLOOP);          \
        break;
        CK_NORM_LOOP(1)
        CK_NORM_LOOP(2)
        CK_NORM_LOOP(3)
        CK_NORM_LOOP(4)
#undef CK_NORM_LOOP
    default: throw std::invalid_argument("hidden too large: " + std::to_string(hidden));
    }
#undef CK_NORM
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
    hipStream_t s        = toStream(stream);
    const int size       = (int)(rows * hidden);
    const int blocks     = std::min(kMaxBlocks, (size / world_size + kSimpleThreads - 1) / kSimpleThreads);
    CK_DISPATCH_FLOAT(dtype, T, {
        CK_DISPATCH_NGPUS(world_size, NG, {
            arRmsTwoShotSimplePullSplitReduce<T, NG><<<blocks, kSimpleThreads, 0, s>>>(
                dp, sg, sg.ptrs[rank], rank, (int)rows, (int)hidden);
        })
        checkLaunch();
        launchNorm<T>(sg.ptrs[rank],
                      toPtr<const T>(residual),
                      toPtr<T>(residual_out),
                      toPtr<T>(out),
                      toPtr<const T>(weight),
                      (float)eps,
                      (int)rows,
                      (int)hidden,
                      gemma_norm,
                      s);
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
}
