#include "commkit/host.hpp"
#include "gfx1250/kernel/all_reduce/push/ll_2shot.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

int cachedCus()
{
    static const int cus = numCus();
    return cus;
}

// fifo: 2 banks of a reduce-scatter and an all-gather region of
// ar2sRegionPk(ngpus) 16B lines (64 MiB at TP4 and TP8), zeroed (flag 0 is a
// cleared line); epoch: per block, every launch writes all kMaxBlocks
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"fifo", (int64_t)ar2sScratchBytes(world_size), true, true, 0},
        {"epoch", kMaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <typename T, int NG>
void launchRoles(int roles, int blocks, int width, hipStream_t stream, const RankData& fifo, int64_t inp,
                 int64_t out, size_t chunk_pk, int rank, int64_t epoch)
{
    switch(roles)
    {
#define CK_LL2S_ROLES(RR)                                                                         \
    case RR:                                                                                      \
        arTwoShotLL<T, NG, RR><<<blocks, RR * width, 0, stream>>>(                       \
            toPtr<T>(out), toPtr<const T>(inp), chunk_pk, rank, toPtr<uint32_t>(epoch), fifo);    \
        break;
        CK_LL2S_ROLES(2)
        CK_LL2S_ROLES(3)
#undef CK_LL2S_ROLES
    default: throw std::invalid_argument("roles must be 2 or 3");
    }
}

// roles: wave groups a block (2 / 3), 0 for aiter's choice: three while one
// block of 3 x 128 threads a CU covers a chunk, else two (MI455X TP8: three
// groups ahead by ~1 us up to 2.1 MB, two from 3.3 MB, by up to 5 us at
// 8.4 MB). width: threads a group (a multiple of 64, roles * width <= 1024), 0
// for aiter's choice: the fewest packets on the busiest CU, ceil(blocks / CUs)
// x width, for at most kMaxBlocks blocks; the smaller width on a tie.
void launch(int64_t inp,
            int64_t out,
            int64_t numel,
            const std::vector<int64_t>& fifo_peers,
            int64_t epoch,
            int roles,
            int width,
            int rank,
            int world_size,
            int dtype,
            int64_t stream)
{
    const RankData fifo = toPeers<RankData>(fifo_peers);
    CK_DISPATCH_FLOAT(dtype, T, {
        const size_t bytes    = (size_t)numel * sizeof(T);
        const size_t chunk_pk = bytes / (8 * (size_t)world_size);
        const size_t cus      = (size_t)cachedCus();
        const int r           = roles ? roles : (chunk_pk <= cus * 128 ? 3 : 2);
        int w                 = width;
        if(w == 0)
        {
            w           = 64;
            size_t best = (size_t)-1;
            for(int c = 64; c * r <= 1024; c += 64)
            {
                const size_t b = (chunk_pk + c - 1) / c;
                if(b > (size_t)kMaxBlocks)
                    continue;
                const size_t load = (b + cus - 1) / cus * c;
                if(load < best)
                {
                    best = load;
                    w    = c;
                }
            }
        }
        const int blocks = std::max(1, std::min<int>(kMaxBlocks, (int)((chunk_pk + w - 1) / w)));
        hipStream_t s    = toStream(stream);
        // the two-shot runs at 4 and 8 ranks only (ar2sMaxBytes)
        switch(world_size)
        {
        case 4: launchRoles<T, 4>(r, blocks, w, s, fifo, inp, out, chunk_pk, rank, epoch); break;
        case 8: launchRoles<T, 8>(r, blocks, w, s, fifo, inp, out, chunk_pk, rank, epoch); break;
        default: throw std::invalid_argument("ll_2shot runs at 4 or 8 ranks, not " + std::to_string(world_size));
        }
    })
    checkLaunch();
}

} // namespace

CK_MODULE(m)
{
    m.def("scratch_spec", &scratchSpec);
    m.def("launch", &launch);
    m.attr("max_bytes") = (int64_t)ar2sMaxBytes(8);
    static_assert(ar2sMaxBytes(4) == ar2sMaxBytes(8), "one capacity for every world size");
}
