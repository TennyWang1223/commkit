#pragma once

#include <hip/hip_runtime.h>

namespace commkit::kernels {

// Copy kernel — serialized load/store pattern.
// Each thread:
//   flat_load_dwordx4
//   s_waitcnt vmcnt(0)
//   ds_write_b128
//   flat_load_dwordx4
//   s_waitcnt vmcnt(0)
//   ds_write_b128
//   __syncthreads()
//   out[i0] = lds[i0]; out[i1] = lds[i1];
template <int BLOCK>
__global__ void __launch_bounds__(BLOCK, 1)
copy_kernel1(const int4* __restrict__ in, int4* __restrict__ out) {
    __shared__ int4 lds[BLOCK * 2];

    const int tid = threadIdx.x;
    const int gid = blockIdx.x * blockDim.x + tid;

    const int4* in_p  = in  + gid * 2;
    int4*       out_p = out + gid * 2;

    int4 v0, v1;

    // Load #1 -> wait -> store #1 to LDS
    asm volatile(
        "flat_load_dwordx4 %0, %1\n\t"
        "s_waitcnt vmcnt(0)\n\t"
        "ds_write_b128 %2, %0\n\t"
        : "=&v"(v0)
        : "v"(in_p + 0),
          "v"(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&lds[tid * 2 + 0])))
        : "memory");

    // Load #2 -> wait -> store #2 to LDS
    asm volatile(
        "flat_load_dwordx4 %0, %1\n\t"
        "s_waitcnt vmcnt(0)\n\t"
        "ds_write_b128 %2, %0\n\t"
        : "=&v"(v1)
        : "v"(in_p + 1),
          "v"(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&lds[tid * 2 + 1])))
        : "memory");

    __syncthreads();

    out_p[0] = lds[tid * 2 + 0];
    out_p[1] = lds[tid * 2 + 1];
}

}  // namespace commkit::kernels
