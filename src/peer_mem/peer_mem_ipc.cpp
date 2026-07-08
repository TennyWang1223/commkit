#include "commkit/peer_mem.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"

#include <array>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <hip/hip_runtime.h>

namespace commkit {

namespace {

// One owned, IPC-exportable device allocation.
struct IpcBuf {
    void* ptr{nullptr};
    size_t size{0};
    bool uncached{false};

    IpcBuf(size_t sz, bool unc) : size(sz), uncached(unc) {
        if (unc) {
            COMMKIT_HIP_CALL(hipExtMallocWithFlags(&ptr, sz, hipDeviceMallocUncached));
            COMMKIT_HIP_CALL(hipMemset(ptr, 0, sz));
        } else {
            COMMKIT_HIP_CALL(hipMalloc(&ptr, sz));
        }
    }
    ~IpcBuf() {
        if (ptr) (void)hipFree(ptr);
    }
    IpcBuf(const IpcBuf&) = delete;
    IpcBuf& operator=(const IpcBuf&) = delete;
};

// Process-wide cache of opened peer handles, keyed by the raw 64-byte blob, so
// repeated registrations of the same allocation share one hipIpcOpenMemHandle.
struct IpcKey {
    std::array<uint8_t, sizeof(hipIpcMemHandle_t)> bytes;
    bool operator<(const IpcKey& o) const { return bytes < o.bytes; }
};

class IpcPeerMemPool : public PeerMemPool {
 public:
    IpcPeerMemPool(int rank, int world_size, TCPStore* store)
        : rank_(rank), world_size_(world_size), store_(store) {}

    ~IpcPeerMemPool() override {
        for (auto& [k, p] : open_handles_) {
            if (p) (void)hipIpcCloseMemHandle(p);
        }
    }

    void* alloc(const std::string& key, size_t size, bool uncached) override {
        if (buffers_.count(key)) {
            std::fprintf(stderr, "[commkit] duplicate buffer key: %s\n", key.c_str());
            std::abort();
        }
        auto buf = std::make_unique<IpcBuf>(size, uncached);
        void* p = buf->ptr;
        buffers_[key] = std::move(buf);
        return p;
    }

    void* at(const std::string& key) const override { return buffers_.at(key)->ptr; }
    size_t size_of(const std::string& key) const override { return buffers_.at(key)->size; }

    std::vector<void*> exchange(void* local_ptr) override {
        // Query the allocation base and emit (handle of base, ptr - base) so
        // peers can locate the same sub-region. For pool-owned buffers the
        // offset is 0; for external tensors it may be non-zero.
        void* base = nullptr;
        COMMKIT_HIP_CALL(hipPointerGetAttribute(
            &base, HIP_POINTER_ATTRIBUTE_RANGE_START_ADDR, (hipDeviceptr_t)local_ptr));
        int64_t offset =
            static_cast<int64_t>(static_cast<char*>(local_ptr) - static_cast<char*>(base));

        hipIpcMemHandle_t h;
        COMMKIT_HIP_CALL(hipIpcGetMemHandle(&h, base));

        int s = seq_++;
        std::string prefix = "ipc/" + std::to_string(s);

        std::vector<uint8_t> shard(sizeof(h) + sizeof(int64_t));
        std::memcpy(shard.data(), &h, sizeof(h));
        std::memcpy(shard.data() + sizeof(h), &offset, sizeof(int64_t));
        store_->set(prefix + "/r" + std::to_string(rank_), shard);

        std::vector<void*> peers(world_size_);
        for (int r = 0; r < world_size_; ++r) {
            if (r == rank_) {
                peers[r] = local_ptr;
                continue;
            }
            auto raw = store_->get(prefix + "/r" + std::to_string(r));
            int64_t peer_off = 0;
            std::memcpy(&peer_off, raw.data() + sizeof(h), sizeof(int64_t));
            char* peer_base = static_cast<char*>(open_handle_(raw.data()));
            peers[r] = peer_base + peer_off;
        }
        return peers;
    }

 private:
    void* open_handle_(const uint8_t* handle_bytes) {
        IpcKey k{};
        std::memcpy(k.bytes.data(), handle_bytes, sizeof(hipIpcMemHandle_t));
        auto it = open_handles_.find(k);
        if (it != open_handles_.end()) return it->second;

        hipIpcMemHandle_t h;
        std::memcpy(&h, handle_bytes, sizeof(h));
        void* p = nullptr;
        COMMKIT_HIP_CALL(hipIpcOpenMemHandle(&p, h, hipIpcMemLazyEnablePeerAccess));
        open_handles_[k] = p;
        return p;
    }

    int rank_;
    int world_size_;
    TCPStore* store_;
    int seq_{0};
    std::unordered_map<std::string, std::unique_ptr<IpcBuf>> buffers_;
    std::map<IpcKey, void*> open_handles_;
};

}  // namespace

std::unique_ptr<PeerMemPool> make_ipc_peer_mem_pool(int rank, int world_size, TCPStore* store) {
    return std::make_unique<IpcPeerMemPool>(rank, world_size, store);
}

}  // namespace commkit
