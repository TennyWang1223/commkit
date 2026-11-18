#pragma once
// all_reduce, lamport proto, push, two-shot (aiter lamport_ar_2shot_gfx1250).
#include "gfx1250/proto/lamport.cuh"

namespace commkit::gfx1250 {

/*
 * A reduce-scatter, then an all-gather, both pushed. The message is ngpus
 * chunks of part packs (the last ones may be short or empty), and thread tid
 * owns pack tid of every chunk: it sends pack tid of chunk g to rank g, sums
 * pack tid of its own chunk over the ranks (fp32 in rank order, rounded once:
 * the bits of the one-shot), sends that sum to every peer and collects theirs.
 * A rank sends 2 (ngpus - 1) / ngpus of the message instead of ngpus - 1, in
 * two hops instead of one.
 *
 * The reduce-scatter takes one round of the data inbox on the thread's wave,
 * as the one-shot does. The all-gather has an inbox of its own, [ngpus][slot]
 * right after the data inbox, and no rounds: it is re-armed as soon as it is
 * read, and a peer writes that pack again only once it holds this rank's
 * reduce-scatter data of a later call, which this rank sends after the kernel
 * boundary.
 */
template <typename T, int ngpus, int BLOCK>
__global__ void __launch_bounds__(BLOCK, 1)
    arTwoShotLamport(const T* __restrict__ input,
                              T* __restrict__ output,
                              uint32_t* __restrict__ round_counter, // [slot / 32], rank-local
                              int slot,                             // inbox packs per sender, >= part
                              int rank,
                              int packs, // packs of the message
                              int part,  // packs a chunk, ceil(packs / ngpus)
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
    // waves past the chunk sit the call out (no block-wide sync below)
    if(wave * kLamportWave >= part)
        return;
    const uint32_t round = round_counter[wave];
    const uint32_t rearm = (round + 2) % kLamportBuffers;
    void* const all[8]   = {p0, p1, p2, p3, p4, p5, p6, p7};
    char* own            = static_cast<char*>(all[0]);
#pragma unroll
    for(int g = 1; g < ngpus; ++g)
        own = g == rank ? static_cast<char*>(all[g]) : own;
    // a rank's all-gather inbox, [ngpus][ag_slot], follows its data inbox
    const int64_t ag_slot   = slot;
    const int64_t ag_offset = lamportInboxBytes(ngpus, slot);
    const auto agInbox      = [ag_offset](void* base) {
        return reinterpret_cast<P*>(static_cast<char*>(base) + ag_offset);
    };
    const u32x4 sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};

    if(tid < part)
    {
        // reduce-scatter: pack tid of chunk g into slot[rank] of rank g's inbox
        pack mine;
        mine.i             = sentinel;
        const int64_t sent = (int64_t)(round * ngpus + rank) * slot + tid;
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
        {
            const int64_t p = (int64_t)g * part + tid;
            if(p >= packs)
                continue;
            pack v;
            v.data = reinterpret_cast<const P*>(input)[p];
#pragma unroll
            for(int j = 0; j < 4; ++j)
                v.i[j] = lamportCanonicalize(v.i[j]);
            if(g == rank)
                mine = v;
            else
                lamportStoreB128(static_cast<P*>(all[g]) + sent, v.i);
        }

        // this rank's chunk: the sum of pack tid over the ranks, to every peer
        const int64_t own_p = (int64_t)rank * part + tid;
        if(own_p < packs)
        {
            const P* inbox = reinterpret_cast<const P*>(own) + (int64_t)round * ngpus * slot + tid;
            pack scratch[ngpus];
            lamportPollInbox<ngpus>(scratch, inbox, slot, rank);

            float x[pack_size] = {};
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
            {
                const P v = g == rank ? mine.data : scratch[g].data;
#pragma unroll
                for(int j = 0; j < pack_size; ++j)
                    x[j] += upcastS(v[j]);
            }
            pack sum;
#pragma unroll
            for(int j = 0; j < pack_size; ++j)
                sum.data[j] = downcastS<T>(x[j]);
            // a peer would take a 0xffff half-word for "not arrived", and every
            // rank writes the same bits
#pragma unroll
            for(int j = 0; j < 4; ++j)
                sum.i[j] = lamportCanonicalize(sum.i[j]);
            const int64_t ag_sent = (int64_t)rank * ag_slot + tid;
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
                if(g != rank)
                    lamportStoreB128(agInbox(all[g]) + ag_sent, sum.i);
            reinterpret_cast<P*>(output)[own_p] = sum.data;
        }

        // all-gather: the peers' sums of pack tid of their chunks
        P* ag_own = agInbox(own) + tid;
        pack got[ngpus];
        bool pending;
        do
        {
            asm volatile("" ::: "memory");
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
                got[g].i = lamportLoadB128(ag_own + (int64_t)g * ag_slot);
            __builtin_amdgcn_sched_barrier(0);
            uint32_t m = 0;
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
            {
                uint32_t gm = 0;
#pragma unroll
                for(int j = 0; j < 4; ++j)
                    gm |= lamportSentinelMask(got[g].i[j]);
                const bool live = g != rank && (int64_t)g * part + tid < packs;
                m |= live ? gm : 0u;
            }
            pending = m != 0;
        } while(pending);
#pragma unroll
        for(int g = 0; g < ngpus; ++g)
            if(g != rank && (int64_t)g * part + tid < packs)
            {
                reinterpret_cast<P*>(output)[(int64_t)g * part + tid] = got[g].data;
                lamportStoreB128(ag_own + (int64_t)g * ag_slot, sentinel);
            }
    }

    // the data inbox: re-arm last round's buffer, on every lane of the wave
#pragma unroll
    for(int g = 0; g < ngpus; ++g)
        if(g != rank)
            lamportStoreB128(reinterpret_cast<P*>(own) + (int64_t)(rearm * ngpus + g) * slot + tid, sentinel);

    if(threadIdx.x % kLamportWave == 0)
        round_counter[wave] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx1250
