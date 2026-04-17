#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>
#include <hip/hip_runtime.h>

namespace commkit {

class TCPStore;

// A single IPC-accessible device buffer. Owns the allocation; cached uses
// hipMalloc, uncached uses hipExtMallocWithFlags(hipDeviceMallocUncached) for
// signal/sync metadata.
class IPCBuffer {
 public:
    IPCBuffer(size_t size, bool uncached);
    ~IPCBuffer();

    IPCBuffer(const IPCBuffer&) = delete;
    IPCBuffer& operator=(const IPCBuffer&) = delete;

    void* data() const { return ptr_; }
    size_t size() const { return size_; }
    bool uncached() const { return uncached_; }

 private:
    void* ptr_{nullptr};
    size_t size_{0};
    bool uncached_{false};
};

// Manages named IPCBuffers and broadcasts hipIpcMemHandle_t through TCPStore.
class IPCBufferPool {
 public:
    IPCBufferPool(int rank, int world_size, TCPStore* store);

    IPCBuffer& create(const std::string& key, size_t size, bool uncached = false);
    IPCBuffer& at(const std::string& key);
    bool contains(const std::string& key) const;

    // Broadcast IPC handle for a named buffer. Returns (handles, offsets) lists
    // of length world_size. handles[r] is a 64-byte hipIpcMemHandle_t blob.
    // offsets[r] is the byte offset within that handle's mapping (always 0 for
    // pool-owned buffers; non-zero for register_external on a sub-tensor).
    std::pair<std::vector<std::vector<uint8_t>>, std::vector<int64_t>>
    get_ipc_meta(const std::string& key);

    // Broadcast IPC handle for an arbitrary device pointer (eager-mode external
    // input/output buffer registration).
    std::pair<std::vector<std::vector<uint8_t>>, std::vector<int64_t>>
    get_external_ipc_meta(void* ptr);

 private:
    int rank_;
    int world_size_;
    TCPStore* store_;
    int seq_{0};
    std::unordered_map<std::string, std::unique_ptr<IPCBuffer>> buffers_;

    std::pair<std::vector<std::vector<uint8_t>>, std::vector<int64_t>>
    broadcast_ipc_(void* ptr);
};

// Open (and cache) a peer's IPC handle. Returns a host-side device pointer
// usable in subsequent kernel launches. Same handle bytes return the same
// pointer (single hipIpcOpenMemHandle call).
void* open_ipc_handle(const uint8_t* handle_bytes);

// Reset the per-process IPC handle cache (called from CommGroup dtor).
void clear_ipc_handle_cache();

}  // namespace commkit
