#include "commkit/peer_mem.hpp"

namespace commkit {

// VMM is the single cross-arch backend: it works on gfx9 and gfx12 alike, and
// unlike IPC it is not affected by the gfx1250 IPC bug. See peer_mem_vmm.cpp.
std::unique_ptr<PeerMemPool> make_vmm_peer_mem_pool(int rank, int world_size, TCPStore* store);

std::unique_ptr<PeerMemPool> make_peer_mem_pool(int rank, int world_size, TCPStore* store) {
    return make_vmm_peer_mem_pool(rank, world_size, store);
}

}  // namespace commkit
