#include "commkit/peer_mem.hpp"
#include "commkit/hip_check.hpp"

#include <cstdio>
#include <cstring>
#include <hip/hip_runtime.h>

namespace commkit {

// Backend constructors (defined in their respective translation units).
std::unique_ptr<PeerMemPool> make_ipc_peer_mem_pool(int rank, int world_size, TCPStore* store);
// std::unique_ptr<PeerMemPool> make_vmm_peer_mem_pool(int rank, int world_size, TCPStore* store);

std::unique_ptr<PeerMemPool> make_peer_mem_pool(int rank, int world_size, TCPStore* store) {
    int dev = 0;
    COMMKIT_HIP_CALL(hipGetDevice(&dev));
    hipDeviceProp_t prop{};
    COMMKIT_HIP_CALL(hipGetDeviceProperties(&prop, dev));

    // gcnArchName looks like "gfx942:sramecc+:xnack-". Match the family prefix.
    const char* arch = prop.gcnArchName;
    if (std::strncmp(arch, "gfx12", 5) == 0) {
        std::fprintf(stderr,
                     "[commkit] arch %s needs the VMM backend, not yet implemented\n", arch);
        std::abort();
        // return make_vmm_peer_mem_pool(rank, world_size, store);
    }

    // gfx9 family (gfx942/gfx950/...) and default: IPC handle exchange.
    return make_ipc_peer_mem_pool(rank, world_size, store);
}

}  // namespace commkit
