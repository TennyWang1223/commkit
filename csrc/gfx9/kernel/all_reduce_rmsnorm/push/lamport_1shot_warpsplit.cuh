#pragma once
// all_reduce + residual + RMSNorm, lamport proto, push, one-shot, wave
// split (aiter lamportArRmsWaveSplit).
#include "gfx9/epilogue/rmsnorm.cuh"
#include "gfx9/proto/lamport.cuh"

namespace commkit::gfx9 {

/*
 * Wave split: GROUPS groups of kLamportWaveSize positions per block, ngpus
 * waves per group. Wave w of a group pushes the group's packs to rank peer =
 * (rank + w) % ngpus and polls slot[peer] of its own inbox; wave 0 keeps this
 * rank's packs and loads the weight. After one __syncthreads all ngpus waves
 * of the group run the residual step, pack_size / ngpus elements a lane
 * (rank-order sum, rounding, + residual, residual_out), into s_acc; after a
 * second one wave 0 takes a pack a lane for the sum of squares and the norm,
 * the other waves re-arm their slot. Spreading the residual step matters: a
 * lone wave issues a dependent VALU op every ~6ns on gfx942, and the 8-element
 * step on wave 0 alone took ~1us (s_memrealtime stamps). The row is the block
 * when hidden / 8 == GROUPS * kLamportWaveSize (partials in LDS, one more
 * __syncthreads), else split.
 */
template <typename T, int ngpus, int GROUPS>
__global__ void __launch_bounds__(GROUPS* ngpus* kLamportWaveSize, 1) arRmsOneShotLamportWarpSplit(
    const T* __restrict__ input,
    const T* __restrict__ residual_inp,
    T* __restrict__ residual_out,
    T* __restrict__ output,
    const T* __restrict__ weight,
    LamportPeers peers,
    uint32_t* __restrict__ inbox_round,   // [kLamportMaxBlocks], of this kernel's inbox
    uint32_t* __restrict__ partials,      // [kLamportBuffers][kLamportRmsMaxPartials], split only
    uint32_t* __restrict__ partial_round, // [kLamportMaxBlocks], split only
    int rank,
    int hidden,
    float eps,
    bool gemma_norm)
{
    static_assert(sizeof(T) == 2, "sentinel 0xffff is only defined for 2-byte dtypes");
    static_assert(GROUPS * ngpus <= 16, "at most 1024 threads");
    constexpr int pack_size        = 16 / sizeof(T);
    constexpr int64_t buffer_packs = (int64_t)ngpus * kLamportMaxPacks;
    constexpr int wave_partials    = kLamportWaveSize / kLamportRmsLanes;
    using P        = typename opus::vector_t<T, pack_size>;
    using A        = typename opus::vector_t<opus::fp32_t, pack_size>;
    using ui32x4_t = __attribute__((__vector_size__(4 * sizeof(uint32_t)))) uint32_t;
    union pack
    {
        P data;
        ui32x4_t i;
    };

    // per lane of a group's ngpus waves: elems_per_lane elements of a pack,
    // the pack's ngpus lanes adjacent
    constexpr int elems_per_lane = pack_size / ngpus;
    __shared__ P s_data[GROUPS][ngpus][kLamportWaveSize]; // by source rank
    __shared__ float s_part[GROUPS * wave_partials];      // row only
    __shared__ A s_acc[GROUPS][kLamportWaveSize];         // fp32 residual_out of each pack

    // wave-uniform, so the branches below are scalar and the pointers SGPRs
    const int wave_id   = __builtin_amdgcn_readfirstlane(threadIdx.x / kLamportWaveSize);
    const int group_id  = wave_id / ngpus; // in the block
    const int wave_peer = wave_id % ngpus;
    const int lane_id   = threadIdx.x % kLamportWaveSize;
    const int peer      = (rank + wave_peer) % ngpus;
    const int group     = blockIdx.x * GROUPS + group_id;
    const int pack_id   = group * kLamportWaveSize + lane_id;
    const int row_packs = hidden / pack_size;
    const bool is_row   = row_packs == GROUPS * kLamportWaveSize; // block-uniform
    const uint32_t round = inbox_round[group];
    const uint32_t rearm = (round + 2) % kLamportBuffers;
    // split mode's partial round, read up front (wave-uniform, a scalar load)
    const uint32_t p_round = partial_round[group];

    ui32x4_t* self_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[rank]);
    ui32x4_t* peer_inbox = reinterpret_cast<ui32x4_t*>(peers.ptrs[peer]);

    // this lane's elements of the epilogue: pack elem_pack of the group,
    // elements [elem_first, elem_first + elems_per_lane)
    const int elem_lane  = wave_peer * kLamportWaveSize + lane_id;
    const int elem_pack  = elem_lane / ngpus;
    const int elem_first = elem_lane % ngpus * elems_per_lane;
    const int64_t elem_off =
        ((int64_t)group * kLamportWaveSize + elem_pack) * pack_size + elem_first;
    T res_elems[elems_per_lane];
#pragma unroll
    for(int e = 0; e < elems_per_lane; ++e)
        res_elems[e] = residual_inp[elem_off + e];

    // every wave loads the same packs, the repeats mostly hit the cache
    pack pack_val;
    pack_val.data = *(reinterpret_cast<const P*>(input) + pack_id);
#pragma unroll
    for(int j = 0; j < 4; ++j)
        pack_val.i[j] = lamportCanonicalize(pack_val.i[j]);

    P w{};
    if(wave_peer != 0)
    {
        __builtin_nontemporal_store(
            pack_val.i, peer_inbox + round * buffer_packs + rank * kLamportMaxPacks + pack_id);
        pack_val.i =
            lamportPollSlot(self_inbox + round * buffer_packs + peer * kLamportMaxPacks + pack_id);
    }
    else
    {
        w = *(reinterpret_cast<const P*>(weight) + pack_id % row_packs);
    }
    s_data[group_id][peer][lane_id] = pack_val.data;
    __syncthreads();

    // The residual step on all ngpus waves, elems_per_lane elements a lane
    // (a lone wave runs a dependent VALU op every ~6ns on gfx942, so the
    // 8-element version on wave 0 alone took ~1us): rank-order sum, rounded
    // to T and back, + residual; residual_out is its rounding, the fp32 value
    // goes to s_acc for the sum of squares.
    {
        const T* rank_elems = reinterpret_cast<const T*>(&s_data[group_id][0][elem_pack]) + elem_first;
        T res_out_elems[elems_per_lane];
#pragma unroll
        for(int e = 0; e < elems_per_lane; ++e)
        {
            float sum = 0.f;
#pragma unroll
            for(int g = 0; g < ngpus; ++g)
            {
                const float x = upcastS(rank_elems[g * kLamportWaveSize * pack_size + e]);
                sum           = g == 0 ? x : sum + x;
            }
            const float r    = upcastS(downcastS<T>(sum)) + upcastS(res_elems[e]);
            res_out_elems[e] = downcastS<T>(r);
            reinterpret_cast<float*>(&s_acc[group_id][elem_pack])[elem_first + e] = r;
        }
#pragma unroll
        for(int e = 0; e < elems_per_lane; ++e)
            residual_out[elem_off + e] = res_out_elems[e];
    }
    __syncthreads();

    A acc;
    float part = 0.f;
    if(wave_peer != 0)
    {
        // re-arm slot[peer] of last round's buffer
        const ui32x4_t sentinel{0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu};
        __builtin_nontemporal_store(
            sentinel, self_inbox + rearm * buffer_packs + peer * kLamportMaxPacks + pack_id);
    }
    else
    {
        acc = s_acc[group_id][lane_id];
        // the 1-stage kernel's fma order, see lamportRmsResidual
        float square_sum = acc[1] * acc[1];
        square_sum       = __builtin_fmaf(acc[0], acc[0], square_sum);
#pragma unroll
        for(int j = 2; j < pack_size; ++j)
            square_sum = __builtin_fmaf(acc[j], acc[j], square_sum);
        part = warpReduce<AddFunctor, float, kLamportRmsLanes>(square_sum);
        if(is_row && lane_id % kLamportRmsLanes == 0)
            s_part[group_id * wave_partials + lane_id / kLamportRmsLanes] = part;
    }
    if(is_row)
        __syncthreads();
    if(wave_peer != 0)
        return;

    const int row_partials = row_packs / kLamportRmsLanes;
    const int width        = lamportRmsWidth(row_partials);
    const int part_lane    = lane_id & (width - 1);
    float v                = 0.f;
    if(is_row)
    {
        if(part_lane < row_partials)
            v = s_part[part_lane];
    }
    else
    {
        const uint32_t p_rearm = (p_round + 2) % kLamportBuffers;
        if(lane_id % kLamportRmsLanes == 0)
            lamportRmsPublish(partials, p_round, p_rearm, pack_id / kLamportRmsLanes, part);
        const int row = pack_id / row_packs;
        __builtin_amdgcn_s_sleep(kLamportRmsPollSleep);
        if(part_lane < row_partials)
            v = lamportRmsPollPartial(partials + p_round * kLamportRmsMaxPartials +
                                      row * row_partials + part_lane);
        if(lane_id == 0)
            partial_round[group] = (p_round + 1) % kLamportBuffers;
    }
    v = lamportRmsFold(v, width);
    const float rms = rsqrtf(v / hidden + eps);
    *(reinterpret_cast<P*>(output) + pack_id) = lamportRmsNorm<T>(acc, w, rms, gemma_norm);

    if(lane_id == 0)
        inbox_round[group] = (round + 1) % kLamportBuffers;
}

} // namespace commkit::gfx9
