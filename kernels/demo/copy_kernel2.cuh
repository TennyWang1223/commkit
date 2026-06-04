#pragma once

#include <hip/hip_runtime.h>

namespace commkit::kernels {

// Copy kernel — overlapped loads, gated stores.
// Each thread:
//   flat_load_dwordx4   ; load #1
//   flat_load_dwordx4   ; load #2
//   s_waitcnt vmcnt(1)
//   ds_write_b128       ; store #1 once load #1 retired
//   s_waitcnt vmcnt(0)
//   ds_write_b128       ; store #2 once load #2 retired
//   __syncthreads()
//   out[i0] = lds[i0]; out[i1] = lds[i1];
template <int BLOCK>
__global__ void __launch_bounds__(BLOCK, 1)
copy_kernel2(const int4* __restrict__ in, int4* __restrict__ out) {
    __shared__ int4 lds[BLOCK * 2];

    const int tid = threadIdx.x;
    const int gid = blockIdx.x * blockDim.x + tid;

    const int4* in_p  = in  + gid * 2;
    int4*       out_p = out + gid * 2;

    int4 v0, v1;

    // Both loads issued back-to-back, then gated stores using vmcnt.
    asm volatile(
        "flat_load_dwordx4 %0, %2\n\t"
        "flat_load_dwordx4 %1, %3\n\t"
        "s_waitcnt vmcnt(1)\n\t"
        "ds_write_b128 %4, %0\n\t"
        "s_waitcnt vmcnt(0)\n\t"
        "ds_write_b128 %5, %1\n\t"
        : "=&v"(v0), "=&v"(v1)
        : "v"(in_p + 0),
          "v"(in_p + 1),
          "v"(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&lds[tid * 2 + 0]))),
          "v"(static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&lds[tid * 2 + 1])))
        : "memory");

    __syncthreads();

    out_p[0] = lds[tid * 2 + 0];
    out_p[1] = lds[tid * 2 + 1];
}

}  // namespace commkit::kernels
