// Standalone TU for inspecting local_vs_remote_rw_demo's device assembly.
#include "local_vs_remote.cuh"
#include "opus/opus.hpp"

namespace commkit::kernels {
template __global__ void local_vs_remote_rw_demo<opus::bf16_t>(
    RankData*, RankSignals, opus::bf16_t*, opus::bf16_t*, int, int);
}
