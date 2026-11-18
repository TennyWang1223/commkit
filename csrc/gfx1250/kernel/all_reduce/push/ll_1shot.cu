#include "commkit/host.hpp"
#include "gfx1250/kernel/all_reduce/push/ll_1shot.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

int cachedCus()
{
    static const int cus = numCus();
    return cus;
}

// fifo: [2 banks][ngpus][kLLPackCapacity lines of 16B], zeroed (flag 0 is a
// cleared line); epoch: per block, every launch writes all kMaxBlocks
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"fifo", (int64_t)llScratchBytes(world_size), true, true, 0},
        {"epoch", kMaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <typename T, int NG>
void launchUnroll(int unroll, int blocks, int threads, hipStream_t stream, const RankData& fifo,
                  int64_t inp, int64_t out, size_t n_pk, int rank, int64_t epoch)
{
    switch(unroll)
    {
#define CK_LL_UNROLL(UU)                                                                         \
    case UU:                                                                                     \
        arOneShotLL<T, NG, UU><<<blocks, threads, 0, stream>>>(                         \
            toPtr<T>(out), toPtr<const T>(inp), n_pk, rank, toPtr<uint32_t>(epoch), fifo);       \
        break;
        CK_LL_UNROLL(1)
        CK_LL_UNROLL(2)
        CK_LL_UNROLL(4)
#undef CK_LL_UNROLL
    default: throw std::invalid_argument("unroll must be 1, 2 or 4");
    }
}

// block: threads a block, half senders and half pollers (512 / 1024), 0 for
// aiter's choice: width = 256 senders while one block a CU covers the
// packets, else 512. unroll: packets a sender takes a round (1 / 2 / 4), 0 for
// aiter's choice: the fewest that keep the grid within one block a CU.
void launch(int64_t inp,
            int64_t out,
            int64_t numel,
            const std::vector<int64_t>& fifo_peers,
            int64_t epoch,
            int block,
            int unroll,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData fifo = toPeers<RankData>(fifo_peers);
    CK_DISPATCH_FLOAT(dtype, T, {
        const size_t n_pk  = (size_t)numel * sizeof(T) >> 3; // 8 payload bytes a packet
        const size_t cap   = std::min<size_t>(cachedCus(), kMaxBlocks);
        const size_t width = block ? (size_t)block / 2 : (n_pk <= (size_t)cachedCus() * 256 ? 256 : 512);
        int u              = unroll;
        if(u == 0)
        {
            u = 1;
            while(u < 4 && (n_pk + width * u - 1) / (width * u) > cap)
                u *= 2;
        }
        const int blocks =
            std::max(1, std::min<int>(kMaxBlocks, (int)((n_pk + width * u - 1) / (width * u))));
        CK_DISPATCH_NGPUS(world_size, NG, {
            launchUnroll<T, NG>(u, blocks, (int)(2 * width), toStream(stream), fifo, inp, out, n_pk, rank, epoch);
        })
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    m.attr("max_bytes") = (int64_t)kLLScratchCapBytes;
}
