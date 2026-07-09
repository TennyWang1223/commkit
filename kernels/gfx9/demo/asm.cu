// Standalone TU for inspecting end_sync_ori vs end_sync_ assembly.
// Only one explicit instantiation lives here so the resulting .s stays tiny.
#include "sync_demo.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {
template __global__ void cross_device_reduce_1stage<opus::bf16_t, 8>(
    RankData*, RankSignals, Signal*, opus::bf16_t* __restrict__, int, int);
}
