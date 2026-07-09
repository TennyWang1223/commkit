#pragma once

#include <hip/hip_runtime.h>

#include "commkit/cast.cuh"
#include "commkit/signal.hpp"
#include "commkit/sync.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {

template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1)
cross_device_reduce_1stage(RankData* _input_dp,
                           RankSignals sg,
                           Signal* self_sg,
                           T* __restrict__ result,
                           int rank,
                           int size) {
    constexpr int pack_size = 16 / sizeof(T);
    using P = typename opus::vector_t<T, pack_size>;
    using A = typename opus::vector_t<opus::fp32_t, pack_size>;

    auto dp = *_input_dp;
    start_sync<ngpus>(sg, self_sg, rank);
    for (int idx = blockIdx.x * blockDim.x + threadIdx.x;
         idx < size;
         idx += gridDim.x * blockDim.x) {
        reinterpret_cast<P*>(result)[idx] =
            packed_reduce<P, ngpus, A>(reinterpret_cast<const P**>(&dp.ptrs[0]), idx);
    }
    end_sync<ngpus, /*final_sync=*/true>(sg, self_sg, rank);
}

// index is pack index
template <typename T, int ngpus>
__device__ __forceinline__ void ar_op(RankData* input, T* output, int index) {
  constexpr int pack_size = 16 / sizeof(T);
  opus::vector_t<opus::fp32_t, pack_size> rslt_fp32_v;
  opus::vector_t<T, pack_size> inp_tmp = *(reinterpret_cast<opus::vector_t<T, pack_size>*>(*input) + index);
  // init
#pragma unroll
  for (int i = 0; i < pack_size; ++i) {
    rslt_fp32_v[i] = upcast_s(inp_tmp[i]);
  }
  // calculate reduce
#pragma unroll
  for (int i = 1; i < ngpus; ++i) {
    inp_tmp = *(reinterpret_cast<opus::vector_t<T, pack_size>*>(*input + i) + index);
#pragma unroll
    for (int j = 0; j < pack_size; ++j) {
      rslt_fp32_v[i] += upcast_s(inp_tmp);
    }
  }
  opus::vector_t<T, pack_size> rslt;
#pragma unroll
  for (int i = 0; i < pack_size; ++i) {
    rslt[i] = downcast_s<T>(rslt_fp32_v[i]);
  }
  *(reinterpret_cast<opus::vector_t<T, pack_size>*>(output) + index) = rslt;
}

template <typename T, int ngpus>
__global__ void __launch_bounds__(512, 1) tt()
{}

}
