#pragma once

#include <cstddef>
#include <memory>
#include <string>
#include <vector>

namespace commkit {

class TCPStore;

// Backend-agnostic pool of peer-visible device memory.
//
// Cross-card sharing is handled by a single VMM backend (hipMemCreate/Map with
// fd handles passed over a unix socket) that works on gfx9 and gfx12 alike, so
// this layer is not an arch seam. Architecture differences live in the kernel
// implementations (see kernels/), not here.
//
// This interface only ever exposes plain device pointers, already mapped into
// the local address space.
class PeerMemPool {
 public:
    virtual ~PeerMemPool() = default;

    // Allocate a local, peer-exportable device buffer under `key`. `uncached`
    // routes to hipDeviceMallocUncached for signal/sync metadata. Returns the
    // local device pointer; also retrievable via at().
    virtual void* alloc(const std::string& key, size_t size, bool uncached) = 0;
    virtual void* at(const std::string& key) const = 0;
    virtual size_t size_of(const std::string& key) const = 0;

    // Broadcast `local_ptr`'s handle across all ranks and return world_size
    // peer-visible pointers (index == rank; self entry is local_ptr itself).
    // Works for any device pointer, pool-owned or external: the backend locates
    // the allocation base and re-applies the sub-offset on each peer.
    virtual std::vector<void*> exchange(void* local_ptr) = 0;
};

// Constructs the single VMM-based backend. Called once by CommGroup after
// hipSetDevice.
std::unique_ptr<PeerMemPool> make_peer_mem_pool(int rank, int world_size, TCPStore* store);

}  // namespace commkit
