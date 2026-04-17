#pragma once

#include "commkit/signal.hpp"

namespace commkit {

// 2-stage kernels reuse the meta buffer's tail (right after Signal) as the
// reduce-scatter scratch. This pointer math matches the meta buffer layout
// chosen by CommGroup: [Signal | scratch...].
template <typename P>
__device__ __forceinline__ P* get_tmp_buf(Signal* sg) {
    return reinterpret_cast<P*>(reinterpret_cast<Signal*>(sg) + 1);
}

}  // namespace commkit
