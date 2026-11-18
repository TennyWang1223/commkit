#include "commkit/host.hpp"
#include "gfx1250/kernel/all_gather/push/ll.cuh"

using namespace commkit;
using namespace commkit::gfx1250;

namespace {

// fifo: [2 banks][ngpus][kLLPackCapacity lines of 16B], zeroed (flag 0 is a
// cleared line); epoch: per block, every launch writes all kMaxBlocks
std::vector<ScratchSpec> scratchSpec(int64_t, int world_size)
{
    return {
        {"fifo", (int64_t)llScratchBytes(world_size), true, true, 0},
        {"epoch", kMaxBlocks * (int64_t)sizeof(uint32_t), false, false, 0},
    };
}

template <int NG, int U>
void launchAligned(bool aligned, int blocks, int threads, hipStream_t stream, const RankData& fifo, int64_t inp,
                   int64_t out, uint32_t n32, uint32_t row32, int rank, int64_t epoch)
{
    if(aligned)
        agLL<NG, U, true><<<blocks, threads, 0, stream>>>(
            toPtr<uint8_t>(out), toPtr<const uint8_t>(inp), n32, row32, rank, toPtr<uint32_t>(epoch), fifo);
    else
        agLL<NG, U, false><<<blocks, threads, 0, stream>>>(
            toPtr<uint8_t>(out), toPtr<const uint8_t>(inp), n32, row32, rank, toPtr<uint32_t>(epoch), fifo);
}

// bytes: a rank's input, row_bytes: a gathered row (== bytes along dim 0),
// both whole 8-byte packets (Python checks). A message is at most
// kLLScratchCapBytes: 349526 units, under kLLPackCapacity lines a slot and
// under kMaxBlocks x 512 threads x 2 units.
// block: threads a block (256 / 512), 0 for aiter's choice: 256 while
// kMaxBlocks of them cover the message, then 512. unroll: units a thread takes
// a round (1 / 2), 0 for aiter's choice: two past kMaxBlocks x block.
void launch(int64_t inp,
            int64_t out,
            int64_t bytes,
            int64_t row_bytes,
            const std::vector<int64_t>& fifo_peers,
            int64_t epoch,
            int block,
            int unroll,
            int rank,
            int world_size,
            int64_t stream)
{
    const RankData fifo = toPeers<RankData>(fifo_peers);
    const uint32_t n32  = (uint32_t)(bytes >> 2);
    const size_t units  = ((size_t)n32 + 2) / 3;
    const int threads   = block ? block : (units <= (size_t)kMaxBlocks * 256 ? 256 : 512);
    const int u         = unroll ? unroll : (units <= (size_t)kMaxBlocks * threads ? 1 : 2);
    const int blocks    = std::max(
        1, std::min<int>(kMaxBlocks, (int)((units + (size_t)threads * u - 1) / ((size_t)threads * u))));
    const uint32_t row32 = (uint32_t)(row_bytes >> 2);
    // a rank-local choice of kernel, not of protocol: both move the same lines
    const bool aligned = (inp & 3) == 0 && (out & 3) == 0;
    hipStream_t s      = toStream(stream);
    CK_DISPATCH_NGPUS(world_size, NG, {
        if(u == 1)
            launchAligned<NG, 1>(aligned, blocks, threads, s, fifo, inp, out, n32, row32, rank, epoch);
        else if(u == 2)
            launchAligned<NG, 2>(aligned, blocks, threads, s, fifo, inp, out, n32, row32, rank, epoch);
        else
            throw std::invalid_argument("unroll must be 1 or 2");
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
