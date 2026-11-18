#pragma once
// all_reduce, lamport proto, push, one-shot (aiter lamport_ar_1shot_gfx1250,
// without its input + other form).
#include "gfx1250/proto/lamport.cuh"

namespace commkit::gfx1250 {

/*
 * output = the sum over ranks of each rank's input. Thread tid owns pack tid
 * of the call: it pushes the pack into slot[rank] of every peer's inbox, polls
 * slot[g] of its own for the peers' and sums them in rank order (fp32, rounded
 * once). Waves past the input sit the call out; the lanes of the last wave past
 * the input only re-arm, so that every pack of a wave that runs a round has its
 * previous buffer re-armed, whatever the size of the next call on that wave.
 *
 * Scalar and pointer kernel arguments only, the inboxes one by one: the module
 * preloads the kernel arguments into SGPRs up to the first aggregate, and a
 * LamportPeers argument would leave the rest to s_loads in series before the
 * first remote store (about 1 us of the call at decode sizes).
 */
template <typename T, int ngpus, int BLOCK>
__global__ void __launch_bounds__(BLOCK, 1)
    arOneShotLamport(const T* __restrict__ input,
                              T* __restrict__ output,
                              uint32_t* __restrict__ round_counter, // [slot / 32], rank-local
                              int slot,                             // inbox packs per sender
                              int rank,
                              int packs, // packs of the call
                              void* p0,
                              void* p1,
                              void* p2,
                              void* p3,
                              void* p4,
                              void* p5,
                              void* p6,
                              void* p7)
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
    static_assert(BLOCK % kLamportWave == 0, "blocks are whole waves");
    constexpr int pack_size = 16 / sizeof(T);
    using P                 = typename opus::vector_t<T, pack_size>;
    union pack
    {
        P data;
        u32x4 i;
    };

    const int tid  = blockIdx.x * BLOCK + threadIdx.x;
    const int wave = __builtin_amdgcn_readfirstlane(tid / kLamportWave);
    // waves past the input sit the call out (no block-wide sync below)
    if(wave * kLamportWave >= packs)
        return;
    const uint32_t round = round_counter[wave];
    const uint32_t rearm = (round + 2) % kLamportBuffers;
    // static indices only: a runtime index into the inboxes is a scalar load
    // in series before each remote store
    void* const all[8] = {p0, p1, p2, p3, p4, p5, p6, p7};
    char* own          = static_cast<char*>(all[0]);
#pragma unroll
    for(int g = 1; g < ngpus; ++g)
        own = g == rank ? static_cast<char*>(all[g]) : own;

    if(tid < packs)
    {
        pack local;
        local.data = reinterpret_cast<const P*>(input)[tid];
#pragma unroll
        for(int j = 0; j < 4; ++j)
            local.i[j] = lamportCanonicalize(local.i[j]);

        const int64_t sent = (int64_t)(round * ngpus + rank) * slot + tid;
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            if(g != rank)
                lamportStoreB128(static_cast<P*>(all[g]) + sent, local.i);

        const P* inbox = reinterpret_cast<const P*>(own) + (int64_t)round * ngpus * slot + tid;
        pack scratch[ngpus];
        lamportPollInbox<ngpus>(scratch, inbox, slot, rank);

        float x[pack_size] = {};
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
        {
            const P v = g == rank ? local.data : scratch[g].data;
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                x[j] += upcastS(v[j]);
        }
        P o;
#pragma unroll
        for(int j = 0; j < pack_size; ++j)
            o[j] = downcastS<T>(x[j]);
        reinterpret_cast<P*>(output)[tid] = o;
    }

    const u32x4 sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
#pragma unroll
    for(int g = 0; g < ngpus; ++g)
        if(g != rank)
            lamportStoreB128(reinterpret_cast<P*>(own) + (int64_t)(rearm * ngpus + g) * slot + tid, sentinel);

    if(threadIdx.x % kLamportWave == 0)
        round_counter[wave] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx1250
