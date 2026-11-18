#pragma once
// gfx9 LL128 protocol. A group of 8 lanes moves 240 bytes (15 packs of 16B)
// as two 128-byte lines; lane 7's last 8 bytes of each line carry the flag
// (the epoch), so a line has arrived when its flag matches. Stores and loads
// are 16-byte nontemporal transactions on the uncached FIFO; the protocol
// relies on a 128-byte line landing together.
//
// Scratch: an uncached IPC FIFO [2 banks][ngpus source ranks][slot] of 4-byte
// words, slot sized for kLL128MaxBytes (bank = epoch parity), and a
// rank-local epoch array of kLL128MaxBlocks entries, every entry advanced
// together (graph safe, and safe when the block size changes between calls).
#include "gfx9/proto/arch.cuh"

namespace commkit::gfx9 {

// largest message; sizes the FIFO slots
constexpr size_t kLL128MaxBytes = (size_t)4 * 1024 * 1024;
// per-rank slot stride in 4-byte words: 256 bytes (two lines) per 240-byte group
constexpr int kLL128SlotStride = (int)((kLL128MaxBytes + 239) / 240) * 128 * 2 / 4;
// grid cap; the epoch array has one entry per possible block
constexpr int kLL128MaxBlocks = 192;
// bytes of payload per 8-lane group
constexpr int kLL128GroupBytes = 240;

template <typename T>
DINLINE void ll128StoreB128(opus::vector_t<T, 16 / sizeof(T)> data, uint32_t* dst)
{
    union
    {
        u32x4 v;
        opus::vector_t<T, 16 / sizeof(T)> vec;
    } u;
    u.vec = data;
    __builtin_nontemporal_store(u.v, reinterpret_cast<u32x4*>(dst));
    asm volatile("" ::: "memory");
}

template <typename T>
DINLINE void ll128LoadB128(opus::vector_t<T, 16 / sizeof(T)>& data, uint32_t* src)
{
    asm volatile("" ::: "memory");
    union
    {
        u32x4 v;
        opus::vector_t<T, 16 / sizeof(T)> vec;
    } u;
    u.v  = __builtin_nontemporal_load(reinterpret_cast<u32x4*>(src));
    data = u.vec;
}

// the two flag words of a line, from lane 7's 16 bytes
DINLINE void ll128CheckFlag(uint32_t& flag0, uint32_t& flag1, uint32_t* src)
{
    asm volatile("" ::: "memory");
    union
    {
        u32x4 v;
        uint32_t w[4];
    } u;
    u.v   = __builtin_nontemporal_load(reinterpret_cast<u32x4*>(src));
    flag0 = u.w[2];
    flag1 = u.w[3];
}

// Lane lane_index's two 16-byte slots of group group_index, one per 128-byte
// line: packs lane_index and lane_index + 8 of the group's 15. Lane 7 splits
// pack 7 over the two lines and puts the flag in each line's last 8 bytes.
// Past the end of the message: zeros.
template <typename T>
DINLINE void ll128LoadGroup(int group_index,
                            int lane_index,
                            int total_group,
                            int last_group_pack_num,
                            uint32_t flag,
                            const T* hbm_buffer,
                            opus::vector_t<T, 16 / sizeof(T)> (&dst_reg)[2])
{
    using P                      = opus::vector_t<T, 16 / sizeof(T)>;
    constexpr int pack_per_group = 15;
    if(group_index != total_group - 1)
    {
        dst_reg[0] = *(reinterpret_cast<const P*>(hbm_buffer) + group_index * pack_per_group + lane_index);
        if(lane_index < 7)
        {
            dst_reg[1] = *(reinterpret_cast<const P*>(hbm_buffer) + group_index * pack_per_group + lane_index + 8);
        }
        else
        {
#pragma unroll
            for(int i = 0; i < 4; ++i)
                *(reinterpret_cast<uint32_t*>(&dst_reg[1]) + i) = flag;
        }
    }
    else // last group
    {
        if(lane_index < last_group_pack_num)
        {
            dst_reg[0] = *(reinterpret_cast<const P*>(hbm_buffer) + group_index * pack_per_group + lane_index);
        }
        else
        {
#pragma unroll
            for(int i = 0; i < 4; ++i)
                *(reinterpret_cast<uint32_t*>(&dst_reg[0]) + i) = 0;
        }

        if(lane_index < last_group_pack_num - 8)
        {
            dst_reg[1] = *(reinterpret_cast<const P*>(hbm_buffer) + group_index * pack_per_group + 8 + lane_index);
        }
        else if(lane_index == 7)
        {
#pragma unroll
            for(int i = 0; i < 4; ++i)
                *(reinterpret_cast<uint32_t*>(&dst_reg[1]) + i) = flag;
        }
        else
        {
#pragma unroll
            for(int i = 0; i < 4; ++i)
                *(reinterpret_cast<uint32_t*>(&dst_reg[1]) + i) = 0;
        }
    }

    if(lane_index == 7)
    {
#pragma unroll
        for(int i = 0; i < 4; ++i)
        {
            dst_reg[1][i]     = dst_reg[0][4 + i];
            dst_reg[0][4 + i] = dst_reg[1][4 + i];
        }
    }
}

// The call's epoch: one more than the last, skipping 0 (a cleared FIFO)
// while keeping the bank parity.
DINLINE uint32_t ll128EpochBegin(const uint32_t* __restrict__ epoch_dev, int block_id, uint32_t& s_flag)
{
    if(threadIdx.x == 0)
    {
        uint32_t f = epoch_dev[block_id] + 1u;
        if(f == 0u)
            f = 2u;
        s_flag = f;
    }
    __syncthreads();
    return s_flag;
}

// Every epoch entry gets the call's epoch (block b writes entries b, b +
// grid, ...), so the next call agrees on it whatever its grid size.
DINLINE void ll128EpochEnd(uint32_t* __restrict__ epoch_dev, int block_id, int total, int epoch_len, uint32_t flag)
{
    if(threadIdx.x == 0)
    {
        for(int e = block_id; e < epoch_len; e += total)
            epoch_dev[e] = flag;
    }
}

} // namespace commkit::gfx9
