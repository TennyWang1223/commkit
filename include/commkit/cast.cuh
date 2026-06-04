#pragma once

#include "opus/opus.hpp"

namespace commkit {

#ifndef COMMKIT_DINLINE
#define COMMKIT_DINLINE __device__ __forceinline__
#endif

// ---- scalar cast ----

template <typename T>
COMMKIT_DINLINE opus::fp32_t upcast_s(T val) {
    return opus::cast<opus::fp32_t>(val);
}

template <>
COMMKIT_DINLINE opus::fp32_t upcast_s<opus::fp32_t>(opus::fp32_t val) {
    return val;
}

template <typename T>
COMMKIT_DINLINE T downcast_s(opus::fp32_t val) {
    return opus::cast<T>(val);
}

template <>
COMMKIT_DINLINE opus::fp32_t downcast_s<opus::fp32_t>(opus::fp32_t val) {
    return val;
}

// ---- vector add (no fp8 path) ----

template <typename T, int N>
COMMKIT_DINLINE opus::vector_t<T, N>& packed_assign_add(opus::vector_t<T, N>& a,
                                                        opus::vector_t<T, N> b) {
    if constexpr (std::is_same<T, opus::fp32_t>::value) {
        a += b;
    } else {
#pragma unroll
        for (int i = 0; i < N; ++i) {
            a[i] = downcast_s<T>(upcast_s(a[i]) + upcast_s(b[i]));
        }
    }
    return a;
}

// ---- vector cast ----

template <typename V, std::enable_if_t<opus::is_vector_v<V>, bool> = true>
COMMKIT_DINLINE auto upcast(V val) -> opus::vector_t<float, opus::vector_traits<V>::size()> {
    using T = typename opus::vector_traits<V>::dtype;
    constexpr int N = opus::vector_traits<V>::size();
    if constexpr (std::is_same<T, opus::fp32_t>::value) {
        return val;
    } else {
        opus::vector_t<float, N> out;
#pragma unroll
        for (int i = 0; i < N; ++i) {
            out[i] = upcast_s(val[i]);
        }
        return out;
    }
}

template <typename O, typename V, std::enable_if_t<opus::is_vector_v<V>, bool> = true>
COMMKIT_DINLINE O downcast(V val) {
    using T = typename opus::vector_traits<O>::dtype;
    constexpr int N = opus::vector_traits<O>::size();
    if constexpr (std::is_same<T, float>::value) {
        return val;
    } else {
        O out;
#pragma unroll
        for (int i = 0; i < N; ++i) {
            out[i] = downcast_s<T>(val[i]);
        }
        return out;
    }
}

// Reduce one packed element across all ngpus inputs. Order is fixed for
// bitwise-identical results across ranks.
template <typename P, int ngpus, typename A>
COMMKIT_DINLINE P packed_reduce(const P* ptrs[], int idx) {
    A tmp = upcast(ptrs[0][idx]);
#pragma unroll
    for (int i = 1; i < ngpus; ++i) {
        packed_assign_add<typename opus::vector_traits<A>::dtype,
                          opus::vector_traits<A>::size()>(tmp, upcast(ptrs[i][idx]));
    }
    return downcast<P>(tmp);
}

}  // namespace commkit
