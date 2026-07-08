#include "commkit/peer_mem.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/tcp_store.hpp"

#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <vector>

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <hip/hip_runtime.h>

namespace commkit {

namespace {

// Metadata sent alongside the fd: the peer needs the full allocation size to
// map, and the sub-offset to re-derive the exact pointer.
struct FdMeta {
    uint64_t alloc_size;
    int64_t offset;
};

// SCM_RIGHTS fd passing over a connected unix socket, carrying an FdMeta payload
// in the ancillary iov.
bool send_fd(int sock, int fd, const FdMeta& meta) {
    msghdr msg{};
    char cbuf[CMSG_SPACE(sizeof(int))]{};
    iovec io{const_cast<FdMeta*>(&meta), sizeof(meta)};
    msg.msg_iov = &io;
    msg.msg_iovlen = 1;
    msg.msg_control = cbuf;
    msg.msg_controllen = sizeof(cbuf);
    cmsghdr* c = CMSG_FIRSTHDR(&msg);
    c->cmsg_level = SOL_SOCKET;
    c->cmsg_type = SCM_RIGHTS;
    c->cmsg_len = CMSG_LEN(sizeof(int));
    std::memcpy(CMSG_DATA(c), &fd, sizeof(int));
    return ::sendmsg(sock, &msg, 0) == static_cast<ssize_t>(sizeof(meta));
}

bool recv_fd(int sock, int& fd, FdMeta& meta) {
    msghdr msg{};
    char cbuf[CMSG_SPACE(sizeof(int))]{};
    iovec io{&meta, sizeof(meta)};
    msg.msg_iov = &io;
    msg.msg_iovlen = 1;
    msg.msg_control = cbuf;
    msg.msg_controllen = sizeof(cbuf);
    if (::recvmsg(sock, &msg, 0) != static_cast<ssize_t>(sizeof(meta))) return false;
    cmsghdr* c = CMSG_FIRSTHDR(&msg);
    if (!c || c->cmsg_type != SCM_RIGHTS) return false;
    std::memcpy(&fd, CMSG_DATA(c), sizeof(int));
    return true;
}

// Fill an abstract-namespace sockaddr_un (leading NUL, no filesystem entry).
socklen_t make_addr(sockaddr_un& sa, int port, int rank) {
    sa.sun_family = AF_UNIX;
    std::memset(sa.sun_path, 0, sizeof(sa.sun_path));
    int n = std::snprintf(sa.sun_path + 1, sizeof(sa.sun_path) - 1,
                          "commkit_vmm_%d_%d", port, rank);
    return static_cast<socklen_t>(offsetof(sockaddr_un, sun_path) + 1 + n);
}

int env_int(const char* name, int fallback) {
    const char* v = std::getenv(name);
    return (v && *v) ? std::atoi(v) : fallback;
}

class VmmPeerMemPool : public PeerMemPool {
 public:
    VmmPeerMemPool(int rank, int world_size, TCPStore* store)
        : rank_(rank), world_size_(world_size), store_(store) {
        port_ = env_int("MASTER_PORT", 29500);

        hipMemAllocationProp prop{};
        prop.type = hipMemAllocationTypeUncached;
        prop.location.type = hipMemLocationTypeDevice;
        COMMKIT_HIP_CALL(hipGetDevice(&prop.location.id));
        prop.requestedHandleType = hipMemHandleTypePosixFileDescriptor;
        prop_ = prop;
        prop_cached_ = prop;
        prop_cached_.type = hipMemAllocationTypePinned;
        COMMKIT_HIP_CALL(hipMemGetAllocationGranularity(
            &granularity_, &prop_, hipMemAllocationGranularityMinimum));

        // Per-rank unix server that hands this rank's current export fd to peers.
        listen_fd_ = ::socket(AF_UNIX, SOCK_STREAM, 0);
        COMMKIT_CHECK(listen_fd_ >= 0, "vmm: unix socket() failed");
        sockaddr_un sa{};
        socklen_t len = make_addr(sa, port_, rank_);
        COMMKIT_CHECK(::bind(listen_fd_, reinterpret_cast<sockaddr*>(&sa), len) == 0,
                      "vmm: unix bind failed");
        COMMKIT_CHECK(::listen(listen_fd_, world_size_) == 0, "vmm: unix listen failed");
        server_ = std::thread([this] { serve_(); });
    }

    ~VmmPeerMemPool() override {
        stop_.store(true);
        if (listen_fd_ >= 0) {
            ::shutdown(listen_fd_, SHUT_RDWR);
            ::close(listen_fd_);
        }
        if (server_.joinable()) server_.join();

        for (auto& m : mappings_) {
            (void)hipMemUnmap((hipDeviceptr_t)m.va, m.size);
            (void)hipMemAddressFree((hipDeviceptr_t)m.va, m.size);
            if (m.owned) (void)hipMemRelease(m.handle);
        }
    }

    void* alloc(const std::string& key, size_t size, bool uncached) override {
        // Signal/sync metadata needs uncached (flag polling); data buffers stay
        // cached for kernel bandwidth. Mirror the original IPC pool semantics.
        COMMKIT_CHECK(!buffers_.count(key), "vmm: duplicate buffer key");
        size_t aligned = round_up_(size);
        hipMemGenericAllocationHandle_t h{};
        COMMKIT_HIP_CALL(hipMemCreate(&h, aligned, uncached ? &prop_ : &prop_cached_, 0));

        void* va = nullptr;
        COMMKIT_HIP_CALL(hipMemAddressReserve((hipDeviceptr_t*)&va, aligned, 0, 0, 0));
        COMMKIT_HIP_CALL(hipMemMap((hipDeviceptr_t)va, aligned, 0, h, 0));
        set_access_(va, aligned);
        COMMKIT_HIP_CALL(hipMemset(va, 0, aligned));

        buffers_[key] = Buf{va, aligned, h};
        mappings_.push_back({va, aligned, h, /*owned=*/true});
        return va;
    }

    void* at(const std::string& key) const override { return buffers_.at(key).va; }
    size_t size_of(const std::string& key) const override { return buffers_.at(key).size; }

    std::vector<void*> exchange(void* local_ptr) override {
        // Determine what to export: a pool-owned VMM handle, or a dmabuf over an
        // external (hipMalloc'd) allocation.
        int fd = -1;
        FdMeta meta{};
        for (auto& [k, b] : buffers_) {
            if (b.va == local_ptr) {
                COMMKIT_HIP_CALL(hipMemExportToShareableHandle(
                    &fd, b.handle, hipMemHandleTypePosixFileDescriptor, 0));
                meta = {b.size, 0};
                break;
            }
        }
        if (fd < 0) {
            void* base = nullptr;
            size_t sz = 0;
            COMMKIT_HIP_CALL(hipMemGetAddressRange((hipDeviceptr_t*)&base, &sz,
                                                   (hipDeviceptr_t)local_ptr));
            COMMKIT_HIP_CALL(hipMemGetHandleForAddressRange(
                &fd, (hipDeviceptr_t)base, sz, hipMemRangeHandleTypeDmaBufFd, 0));
            meta = {sz, static_cast<int64_t>(static_cast<char*>(local_ptr) -
                                             static_cast<char*>(base))};
        }

        // Publish for the server thread, then wait until all ranks have published.
        {
            std::lock_guard<std::mutex> lk(share_mu_);
            share_fd_ = fd;
            share_meta_ = meta;
        }
        store_->barrier();

        std::vector<void*> peers(world_size_);
        peers[rank_] = local_ptr;
        for (int p = 0; p < world_size_; ++p) {
            if (p == rank_) continue;
            peers[p] = pull_from_peer_(p);
        }

        // All ranks have finished pulling; safe to close and let the next
        // exchange overwrite share_fd_.
        store_->barrier();
        ::close(fd);
        return peers;
    }

 private:
    struct Buf {
        void* va;
        size_t size;
        hipMemGenericAllocationHandle_t handle;
    };
    struct Mapping {
        void* va;
        size_t size;
        hipMemGenericAllocationHandle_t handle;
        bool owned;  // true: alloc()'d here (release handle); false: imported peer
    };

    size_t round_up_(size_t n) const {
        return ((n + granularity_ - 1) / granularity_) * granularity_;
    }

    void set_access_(void* va, size_t size) {
        hipMemAccessDesc ad{};
        ad.location = prop_.location;
        ad.flags = hipMemAccessFlagsProtReadWrite;
        COMMKIT_HIP_CALL(hipMemSetAccess((hipDeviceptr_t)va, size, &ad, 1));
    }

    // Map a peer's exported fd into our address space and return base+offset.
    void* map_imported_(int fd, const FdMeta& meta) {
        hipMemGenericAllocationHandle_t h{};
        COMMKIT_HIP_CALL(hipMemImportFromShareableHandle(
            &h, (void*)&fd, hipMemHandleTypePosixFileDescriptor));
        void* va = nullptr;
        COMMKIT_HIP_CALL(
            hipMemAddressReserve((hipDeviceptr_t*)&va, meta.alloc_size, 0, 0, 0));
        COMMKIT_HIP_CALL(hipMemMap((hipDeviceptr_t)va, meta.alloc_size, 0, h, 0));
        set_access_(va, meta.alloc_size);
        mappings_.push_back({va, meta.alloc_size, h, /*owned=*/false});
        ::close(fd);
        return static_cast<char*>(va) + meta.offset;
    }

    void* pull_from_peer_(int peer) {
        int s = ::socket(AF_UNIX, SOCK_STREAM, 0);
        COMMKIT_CHECK(s >= 0, "vmm: client socket failed");
        sockaddr_un sa{};
        socklen_t len = make_addr(sa, port_, peer);
        // Server is up since construction; barrier ensured its fd is published.
        while (::connect(s, reinterpret_cast<sockaddr*>(&sa), len) != 0) {
            if (errno == EINTR || errno == ECONNREFUSED || errno == EAGAIN) {
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
                continue;
            }
            COMMKIT_CHECK(false, "vmm: connect to peer failed");
        }
        int fd = -1;
        FdMeta meta{};
        COMMKIT_CHECK(recv_fd(s, fd, meta), "vmm: recv_fd failed");
        ::close(s);
        return map_imported_(fd, meta);
    }

    void serve_() {
        while (!stop_.load()) {
            int c = ::accept(listen_fd_, nullptr, nullptr);
            if (c < 0) {
                if (stop_.load()) break;
                if (errno == EINTR) continue;
                break;
            }
            int fd;
            FdMeta meta;
            {
                std::lock_guard<std::mutex> lk(share_mu_);
                fd = share_fd_;
                meta = share_meta_;
            }
            (void)send_fd(c, fd, meta);
            ::close(c);
        }
    }

    int rank_;
    int world_size_;
    TCPStore* store_;
    int port_{29500};

    hipMemAllocationProp prop_{};         // uncached (signal/sync)
    hipMemAllocationProp prop_cached_{};  // cached (data buffers)
    size_t granularity_{0};

    std::unordered_map<std::string, Buf> buffers_;
    std::vector<Mapping> mappings_;

    int listen_fd_{-1};
    std::thread server_;
    std::atomic<bool> stop_{false};

    std::mutex share_mu_;
    int share_fd_{-1};
    FdMeta share_meta_{};
};

}  // namespace

std::unique_ptr<PeerMemPool> make_vmm_peer_mem_pool(int rank, int world_size, TCPStore* store) {
    return std::make_unique<VmmPeerMemPool>(rank, world_size, store);
}

}  // namespace commkit
