#include "commkit/ipc_buffer.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"

#include <array>
#include <cstring>
#include <map>
#include <mutex>
#include <stdexcept>

namespace commkit {

namespace {

// Cache opened IPC handles process-wide so repeated registrations share one
// hipIpcOpenMemHandle. Key is the raw 64-byte handle blob.
struct IpcKey {
    std::array<uint8_t, sizeof(hipIpcMemHandle_t)> bytes;
    bool operator<(const IpcKey& o) const { return bytes < o.bytes; }
};

std::mutex g_handle_mu;
std::map<IpcKey, void*> g_open_handles;

}  // namespace

void* open_ipc_handle(const uint8_t* handle_bytes) {
    IpcKey k{};
    std::memcpy(k.bytes.data(), handle_bytes, sizeof(hipIpcMemHandle_t));

    std::lock_guard<std::mutex> lk(g_handle_mu);
    auto it = g_open_handles.find(k);
    if (it != g_open_handles.end()) return it->second;

    hipIpcMemHandle_t h;
    std::memcpy(&h, handle_bytes, sizeof(h));
    void* p = nullptr;
    COMMKIT_HIP_CALL(hipIpcOpenMemHandle(&p, h, hipIpcMemLazyEnablePeerAccess));
    g_open_handles[k] = p;
    return p;
}

void clear_ipc_handle_cache() {
    std::lock_guard<std::mutex> lk(g_handle_mu);
    for (auto& [k, p] : g_open_handles) {
        if (p) hipIpcCloseMemHandle(p);
    }
    g_open_handles.clear();
}

// ---------------- IPCBuffer ----------------

IPCBuffer::IPCBuffer(size_t size, bool uncached) : size_(size), uncached_(uncached) {
    if (uncached) {
        COMMKIT_HIP_CALL(hipExtMallocWithFlags(&ptr_, size, hipDeviceMallocUncached));
        COMMKIT_HIP_CALL(hipMemset(ptr_, 0, size));
    } else {
        COMMKIT_HIP_CALL(hipMalloc(&ptr_, size));
    }
}

IPCBuffer::~IPCBuffer() {
    if (ptr_) {
        // Best-effort free. Errors during shutdown are not fatal.
        (void)hipFree(ptr_);
        ptr_ = nullptr;
    }
}

// ---------------- IPCBufferPool ----------------

IPCBufferPool::IPCBufferPool(int rank, int world_size, TCPStore* store)
    : rank_(rank), world_size_(world_size), store_(store) {}

IPCBuffer& IPCBufferPool::create(const std::string& key, size_t size, bool uncached) {
    if (buffers_.count(key)) {
        std::fprintf(stderr, "[commkit] duplicate IPCBuffer key: %s\n", key.c_str());
        std::abort();
    }
    auto buf = std::make_unique<IPCBuffer>(size, uncached);
    auto& ref = *buf;
    buffers_[key] = std::move(buf);
    return ref;
}

IPCBuffer& IPCBufferPool::at(const std::string& key) { return *buffers_.at(key); }

bool IPCBufferPool::contains(const std::string& key) const { return buffers_.count(key) > 0; }

std::pair<std::vector<std::vector<uint8_t>>, std::vector<int64_t>>
IPCBufferPool::get_ipc_meta(const std::string& key) {
    return broadcast_ipc_(at(key).data());
}

std::pair<std::vector<std::vector<uint8_t>>, std::vector<int64_t>>
IPCBufferPool::get_external_ipc_meta(void* ptr) {
    // External tensor: query the allocation base and emit (handle of base,
    // ptr - base) so peers can locate the same sub-region.
    void* base = nullptr;
    COMMKIT_HIP_CALL(hipPointerGetAttribute(
        &base, HIP_POINTER_ATTRIBUTE_RANGE_START_ADDR, (hipDeviceptr_t)ptr));
    int64_t offset = static_cast<int64_t>(static_cast<char*>(ptr) - static_cast<char*>(base));

    hipIpcMemHandle_t h;
    COMMKIT_HIP_CALL(hipIpcGetMemHandle(&h, base));

    int s = seq_++;
    std::string prefix = "ipc/" + std::to_string(s);

    std::vector<uint8_t> shard(sizeof(h) + sizeof(int64_t));
    std::memcpy(shard.data(), &h, sizeof(h));
    std::memcpy(shard.data() + sizeof(h), &offset, sizeof(int64_t));

    store_->set(prefix + "/r" + std::to_string(rank_), shard);

    std::vector<std::vector<uint8_t>> handles(world_size_);
    std::vector<int64_t> offsets(world_size_);
    for (int r = 0; r < world_size_; ++r) {
        auto raw = store_->get(prefix + "/r" + std::to_string(r));
        handles[r].assign(raw.begin(), raw.begin() + sizeof(h));
        std::memcpy(&offsets[r], raw.data() + sizeof(h), sizeof(int64_t));
    }
    return {std::move(handles), std::move(offsets)};
}

std::pair<std::vector<std::vector<uint8_t>>, std::vector<int64_t>>
IPCBufferPool::broadcast_ipc_(void* ptr) {
    hipIpcMemHandle_t h;
    COMMKIT_HIP_CALL(hipIpcGetMemHandle(&h, ptr));
    int64_t offset = 0;

    int s = seq_++;
    std::string prefix = "ipc/" + std::to_string(s);

    std::vector<uint8_t> shard(sizeof(h) + sizeof(int64_t));
    std::memcpy(shard.data(), &h, sizeof(h));
    std::memcpy(shard.data() + sizeof(h), &offset, sizeof(int64_t));
    store_->set(prefix + "/r" + std::to_string(rank_), shard);

    std::vector<std::vector<uint8_t>> handles(world_size_);
    std::vector<int64_t> offsets(world_size_);
    for (int r = 0; r < world_size_; ++r) {
        auto raw = store_->get(prefix + "/r" + std::to_string(r));
        handles[r].assign(raw.begin(), raw.begin() + sizeof(h));
        std::memcpy(&offsets[r], raw.data() + sizeof(h), sizeof(int64_t));
    }
    return {std::move(handles), std::move(offsets)};
}

}  // namespace commkit
