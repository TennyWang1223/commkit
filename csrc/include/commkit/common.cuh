#pragma once
// Arch-agnostic device helpers shared by every proto, epilogue and kernel:
// scalar / packed casts, packed adds, reduction functors and warp reductions.
// Anything that depends on the wave size, the signal layout or cache-control
// bits lives under csrc/<arch>/ instead.
#include <hip/hip_runtime.h>

#include <cstdint>
#include <type_traits>

#include "opus/opus.hpp"

#define DINLINE __device__ __forceinline__

namespace commkit {

// ---------------------------------------------------------------------------
// casts: every reduction accumulates in fp32 and rounds once
// ---------------------------------------------------------------------------
template <typename T>
DINLINE opus::fp32_t upcastS(T val)
{
    return opus::cast<opus::fp32_t>(val);
}

template <>
DINLINE opus::fp32_t upcastS<opus::fp32_t>(opus::fp32_t val)
{
    return val;
}

template <typename T>
DINLINE T downcastS(opus::fp32_t val)
{
    return opus::cast<T>(val);
}

template <>
DINLINE opus::fp32_t downcastS<opus::fp32_t>(opus::fp32_t val)
{
    return val;
}

// Pins v as an fp32 value. Without it the compiler may fuse the multiply that
// produced v with a following fp32 -> fp16 conversion into v_fma_mix*_f16,
// which rounds once, straight to fp16: on near-ties that differs by 1 ulp
// from a kernel that rounds to fp32 first, so fused kernels that must match
// each other bit for bit round their outputs through this.
DINLINE float pinFloat(float v)
{
    asm volatile("" : "+v"(v));
    return v;
}

// a += b element-wise; 16-bit types round after the add
template <typename T, int N>
DINLINE opus::vector_t<T, N>& packedAssignAdd(opus::vector_t<T, N>& a, opus::vector_t<T, N> b)
{
    if constexpr(std::is_same<T, opus::fp32_t>::value)
    {
        a += b;
    }
    else
    {
#pragma unroll
        for(int i = 0; i < N; i++)
            a[i] = downcastS<T>(upcastS(a[i]) + upcastS(b[i]));
    }
    return a;
}

template <typename V, std::enable_if_t<opus::is_vector_v<V>, bool> = true>
DINLINE auto upcast(V val) -> opus::vector_t<float, opus::vector_traits<V>::size()>
{
    using T         = typename opus::vector_traits<V>::dtype;
    constexpr int N = opus::vector_traits<V>::size();
    if constexpr(std::is_same<T, opus::fp32_t>::value)
    {
        return val;
    }
    else
    {
        opus::vector_t<float, N> out;
#pragma unroll
        for(int i = 0; i < N; i++)
            out[i] = upcastS(val[i]);
        return out;
    }
}

template <typename O, typename V, std::enable_if_t<opus::is_vector_v<V>, bool> = true>
DINLINE O downcast(V val)
{
    using T         = typename opus::vector_traits<O>::dtype;
    constexpr int N = opus::vector_traits<O>::size();
    if constexpr(std::is_same<T, float>::value)
    {
        return val;
    }
    else
    {
        O out;
#pragma unroll
        for(int i = 0; i < N; i++)
            out[i] = downcastS<T>(val[i]);
        return out;
    }
}

// Sum of pack idx over ptrs[0..ngpus) in fp32, in rank order, rounded once.
// Every rank sums in the same order, so every rank gets the same bits.
// All loads are issued before the first add: with global (kernarg) pointers
// the scheduler otherwise puts a vmcnt(0) after each peer load, serializing
// ngpus remote round trips (TP8 reduce_scatter 2M: 24 vs 14 us).
template <typename P, int ngpus, typename A>
DINLINE P packedReduce(const P* ptrs[], int idx)
{
    P v[ngpus];
#pragma unroll
    for(int i = 0; i < ngpus; i++)
        v[i] = ptrs[i][idx];
    A tmp = upcast(v[0]);
#pragma unroll
    for(int i = 1; i < ngpus; i++)
        packedAssignAdd<typename opus::vector_traits<A>::dtype, opus::vector_traits<A>::size()>(
            tmp, upcast(v[i]));
    return downcast<P>(tmp);
}

// ---------------------------------------------------------------------------
// reduction functors
// ---------------------------------------------------------------------------
template <typename T>
struct AddFunctor
{
    DINLINE T operator()(T a, T b) { return downcastS<T>(upcastS(a) + upcastS(b)); }
};

template <>
struct AddFunctor<opus::fp32_t>
{
    DINLINE opus::fp32_t operator()(opus::fp32_t a, opus::fp32_t b) { return a + b; }
};

template <typename T>
struct MaxFunctor
{
    DINLINE T operator()(T a, T b) { return max(a, b); }
};

template <template <typename> class Functor, typename T, int size>
DINLINE T packReduce(opus::vector_t<T, size> pack)
{
    auto op   = Functor<T>();
    T ret_val = pack[0];
#pragma unroll
    for(int i = 1; i < size; ++i)
        ret_val = op(ret_val, pack[i]);
    return ret_val;
}

// ---------------------------------------------------------------------------
// warp reductions (width defaults to the wave size of the target)
// ---------------------------------------------------------------------------
// cross-lane butterfly shuffle (XOR) via ds_bpermute, 4-byte types only
template <typename T>
DINLINE T shflXor(T var, int mask, int width = opus::get_warp_size())
{
    static_assert(sizeof(T) == 4);
    int self  = opus::lane_id();
    int index = (self & ~(width - 1)) + ((self ^ mask) & (width - 1));
    return __builtin_bit_cast(
        T, __builtin_amdgcn_ds_bpermute(index << 2, __builtin_bit_cast(int, var)));
}

template <template <typename> class Functor, typename T, int reduce_range, int stop_stride = 0>
DINLINE T warpReduce(T val)
{
    if constexpr(sizeof(T) == 4)
    {
        auto op = Functor<T>();
#pragma unroll
        for(int stride = reduce_range / 2; stride > stop_stride; stride >>= 1)
            val = op(val, shflXor(val, stride, reduce_range));
    }
    else
    {
        auto op        = Functor<float>();
        float val_fp32 = upcastS(val);
#pragma unroll
        for(int stride = reduce_range / 2; stride > stop_stride; stride >>= 1)
            val_fp32 = op(val_fp32, shflXor(val_fp32, stride, reduce_range));
        val = downcastS<T>(val_fp32);
    }
    return val;
}

// reduce_range known only at run time (a power of two)
template <template <typename> class Functor, typename T>
DINLINE T warpReduceRuntime(T val, int reduce_range)
{
    auto op = Functor<T>();
    for(int stride = reduce_range / 2; stride > 0; stride >>= 1)
        val = op(val, shflXor(val, stride, reduce_range));
    return val;
}

} // namespace commkit
