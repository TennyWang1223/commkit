#include "commkit/host.hpp"
#include "gfx1250/kernel/all_reduce_rmsnorm/push/lamport_1shot.cuh"

#include <type_traits>
#include <utility>

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

// The host side of a workgroup-cluster launch: hipLaunchAttributeValue::
// clusterDim comes with hipLaunchAttributeClusterDimension (not in ROCm 7.2).
// Without it the cluster kernel is never instantiated and every call takes
// the block-a-row path.
template <typename V, typename = void>
struct LamportHasClusterDim : std::false_type
{
};
template <typename V>
struct LamportHasClusterDim<V, std::void_t<decltype(std::declval<V&>().clusterDim)>> : std::true_type
{
};
constexpr bool kLamportClusterLaunch = LamportHasClusterDim<hipLaunchAttributeValue>::value;

// Make attr a cluster of x blocks. A template so that the cluster names are
// dependent and only looked up where the HIP headers have them.
template <typename Attr>
void lamportSetClusterDim(Attr& attr, unsigned x)
{
    if constexpr(LamportHasClusterDim<decltype(Attr::val)>::value)
    {
        attr.id               = decltype(Attr::id)::hipLaunchAttributeClusterDimension;
        attr.val.clusterDim.x = x;
        attr.val.clusterDim.y = 1;
        attr.val.clusterDim.z = 1;
    }
}

// A stream capture drops the cluster dimension of hipLaunchKernelEx (the node
// then runs without a cluster and the cluster barrier orders nothing), so set
// it again on the node the launch just added.
template <typename Attr>
void lamportSetCapturedClusterDim(hipStream_t stream, const Attr& attr)
{
    hipStreamCaptureStatus status;
    const hipGraphNode_t* deps = nullptr;
    size_t num_deps            = 0;
    CK_HIP_CHECK(hipStreamGetCaptureInfo_v2(stream, &status, nullptr, nullptr, &deps, &num_deps));
    if(status != hipStreamCaptureStatusActive)
        return;
    if(num_deps != 1)
        throw std::runtime_error("lamport allreduce rmsnorm: cannot find the captured node");
    CK_HIP_CHECK(hipGraphKernelNodeSetAttribute(deps[0], attr.id, &attr.val));
}

int cachedCus()
{
    static const int cus = numCus();
    return cus;
}

// Threads a block of a row split over a cluster, or 0 for a block a row
// (aiter LamportArRms::cluster_threads). Split only while the rows leave CUs
// idle: from rows >= CUs a block a row was faster (gfx1250, 256 CUs, rows 256+
// at hidden 4096-8192).
int clusterThreads(int64_t rows, int row_packs)
{
    if(!kLamportClusterLaunch || rows >= cachedCus() || row_packs <= kLamportMinClusterRowPacks)
        return 0;
    for(int bs = kLamportClusterMaxThreads; bs >= kLamportWave; bs /= 2)
    {
        if(row_packs % bs != 0)
            continue;
        const int blocks = row_packs / bs;
        return blocks <= kLamportMaxClusterBlocks ? bs : 0;
    }
    return 0;
}

// slot = max_bytes / 16 packs a sender (Python keeps max_bytes a multiple of
// 512, whole waves). inbox: [kLamportBuffers][ngpus][slot] of 16B, cached,
// armed with the sentinel; round: a counter per wave of 32 packs;
// cluster_partials: a sum-of-squares partial per wave (cluster launch only)
std::vector<ScratchSpec> scratchSpec(int64_t max_bytes, int world_size)
{
    const int64_t slot = max_bytes / 16;
    return {
        {"inbox", lamportInboxBytes(world_size, slot), true, false, 0xff},
        {"round", lamportWaves(slot) * (int64_t)sizeof(uint32_t), false, false, 0},
        {"cluster_partials", lamportWaves(slot) * (int64_t)sizeof(float), false, false, -1},
    };
}

template <typename T, int NG>
void launchRows(bool cluster,
                int64_t rows,
                int row_packs,
                hipStream_t stream,
                const T* input,
                const T* residual_inp,
                T* residual_out,
                T* output,
                const T* weight,
                const LamportPeers& peers,
                float* cluster_partials,
                uint32_t* round,
                int slot,
                int rank,
                int hidden,
                float eps,
                bool gemma_norm)
{
    const int64_t packs = rows * row_packs;
    const int threads   = cluster ? clusterThreads(rows, row_packs) : 0;
#define CK_LAMPORT_RMS_ARGS                                                                                  \
    input, residual_inp, residual_out, output, weight, peers, cluster_partials, round, slot, rank, hidden, eps, \
        gemma_norm
    if(threads == 0)
    {
        arRmsOneShotLamport<T, NG, kLamportRowMaxThreads, false>
            <<<(int)rows, row_packs, 0, stream>>>(CK_LAMPORT_RMS_ARGS);
    }
    else if constexpr(kLamportClusterLaunch)
    {
        hipLaunchAttribute attr{};
        lamportSetClusterDim(attr, (unsigned)(row_packs / threads));
        hipLaunchConfig_t config{};
        config.gridDim  = dim3((unsigned)(packs / threads));
        config.blockDim = dim3(threads);
        config.stream   = stream;
        config.attrs    = &attr;
        config.numAttrs = 1;
        CK_HIP_CHECK(hipLaunchKernelEx(
            &config, arRmsOneShotLamport<T, NG, kLamportClusterMaxThreads, true>, CK_LAMPORT_RMS_ARGS));
        lamportSetCapturedClusterDim(stream, attr);
    }
#undef CK_LAMPORT_RMS_ARGS
}

// cluster: false, a block a row always; true, aiter's choice per call (a
// cluster launch where clusterThreads finds one)
void launch(int64_t inp,
            int64_t residual,
            int64_t weight,
            int64_t out,
            int64_t residual_out,
            int64_t rows,
            int64_t hidden,
            double eps,
            bool gemma_norm,
            const std::vector<int64_t>& inbox_peers,
            int64_t round,
            int64_t cluster_partials,
            int64_t max_bytes,
            bool cluster,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const LamportPeers peers = toPeers<LamportPeers>(inbox_peers);
    const int slot           = (int)(max_bytes / 16);
    CK_DISPATCH_HALF(dtype, T, {
        const int row_packs = (int)(hidden / (16 / sizeof(T)));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchRows<T, NG>(cluster,
                              rows,
                              row_packs,
                              toStream(stream),
                              toPtr<const T>(inp),
                              toPtr<const T>(residual),
                              toPtr<T>(residual_out),
                              toPtr<T>(out),
                              toPtr<const T>(weight),
                              peers,
                              toPtr<float>(cluster_partials),
                              toPtr<uint32_t>(round),
                              slot,
                              rank,
                              (int)hidden,
                              (float)eps,
                              gemma_norm);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    // whether this build can launch workgroup clusters (else cluster=True
    // takes the block-a-row path on every call)
    m.attr("cluster_launch") = kLamportClusterLaunch;
}
