#include "commkit/tcp_store.hpp"
#include "commkit/hip_check.hpp"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>
#include <cerrno>
#include <chrono>
#include <cstring>
#include <stdexcept>
#include <thread>

namespace commkit {

namespace {

constexpr uint8_t OP_SET = 0;
constexpr uint8_t OP_GET = 1;
constexpr uint8_t OP_BAR = 2;

constexpr uint8_t STATUS_OK = 0;

bool write_all(int fd, const void* buf, size_t n) {
    const auto* p = static_cast<const uint8_t*>(buf);
    while (n > 0) {
        ssize_t w = ::send(fd, p, n, MSG_NOSIGNAL);
        if (w < 0) {
            if (errno == EINTR) continue;
            return false;
        }
        p += w;
        n -= w;
    }
    return true;
}

bool read_all(int fd, void* buf, size_t n) {
    auto* p = static_cast<uint8_t*>(buf);
    while (n > 0) {
        ssize_t r = ::recv(fd, p, n, 0);
        if (r == 0) return false;
        if (r < 0) {
            if (errno == EINTR) continue;
            return false;
        }
        p += r;
        n -= r;
    }
    return true;
}

void disable_nagle(int fd) {
    int flag = 1;
    ::setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
}

}  // namespace

TCPStore::TCPStore(int rank, int world_size, std::string master_addr, int master_port)
    : rank_(rank),
      world_size_(world_size),
      master_addr_(std::move(master_addr)),
      master_port_(master_port) {
    if (rank_ == 0) {
        listen_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
        COMMKIT_CHECK(listen_fd_ >= 0, "socket() failed");
        int yes = 1;
        ::setsockopt(listen_fd_, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_ANY);
        addr.sin_port = htons(master_port_);
        if (::bind(listen_fd_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
            std::fprintf(stderr, "[commkit] bind(%d) failed: %s\n",
                         master_port_, std::strerror(errno));
            std::abort();
        }
        COMMKIT_CHECK(::listen(listen_fd_, 128) == 0, "listen failed");
        server_thread_ = std::thread([this] { run_server_(); });
    }

    connect_client_();
}

TCPStore::~TCPStore() {
    if (client_fd_ >= 0) ::close(client_fd_);
    stop_.store(true);
    if (rank_ == 0) {
        if (listen_fd_ >= 0) {
            ::shutdown(listen_fd_, SHUT_RDWR);
            ::close(listen_fd_);
        }
        if (server_thread_.joinable()) server_thread_.join();
    }
}

void TCPStore::connect_client_() {
    client_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
    COMMKIT_CHECK(client_fd_ >= 0, "client socket() failed");

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(master_port_);
    if (::inet_pton(AF_INET, master_addr_.c_str(), &addr.sin_addr) <= 0) {
        std::fprintf(stderr, "[commkit] inet_pton(%s) failed\n", master_addr_.c_str());
        std::abort();
    }

    // Retry connect up to ~30s — server thread may not have bound yet.
    auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);
    while (true) {
        if (::connect(client_fd_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0) break;
        if (std::chrono::steady_clock::now() > deadline) {
            std::fprintf(stderr, "[commkit] rank %d connect to %s:%d timed out: %s\n",
                         rank_, master_addr_.c_str(), master_port_, std::strerror(errno));
            std::abort();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    disable_nagle(client_fd_);
}

void TCPStore::run_server_() {
    std::vector<std::thread> workers;
    while (!stop_.load()) {
        sockaddr_in cli{};
        socklen_t cli_len = sizeof(cli);
        int fd = ::accept(listen_fd_, reinterpret_cast<sockaddr*>(&cli), &cli_len);
        if (fd < 0) {
            if (stop_.load()) break;
            if (errno == EINTR) continue;
            break;
        }
        disable_nagle(fd);
        workers.emplace_back([this, fd] { handle_client_(fd); });
    }
    for (auto& t : workers) {
        if (t.joinable()) t.join();
    }
}

void TCPStore::handle_client_(int fd) {
    while (true) {
        uint8_t op;
        if (!read_all(fd, &op, 1)) break;

        uint32_t key_len_n;
        if (!read_all(fd, &key_len_n, 4)) break;
        uint32_t key_len = ntohl(key_len_n);
        std::string key(key_len, '\0');
        if (key_len && !read_all(fd, key.data(), key_len)) break;

        uint32_t val_len_n;
        if (!read_all(fd, &val_len_n, 4)) break;
        uint32_t val_len = ntohl(val_len_n);
        std::vector<uint8_t> val(val_len);
        if (val_len && !read_all(fd, val.data(), val_len)) break;

        if (op == OP_SET) {
            {
                std::lock_guard<std::mutex> lk(kv_mu_);
                kv_[key] = std::move(val);
            }
            uint8_t st = STATUS_OK;
            uint32_t zero = 0;
            if (!write_all(fd, &st, 1) || !write_all(fd, &zero, 4)) break;
        } else if (op == OP_GET) {
            std::vector<uint8_t> reply;
            // Block-wait on key — IPC handles arrive at unpredictable order.
            while (true) {
                {
                    std::lock_guard<std::mutex> lk(kv_mu_);
                    auto it = kv_.find(key);
                    if (it != kv_.end()) {
                        reply = it->second;
                        break;
                    }
                }
                if (stop_.load()) return;
                std::this_thread::sleep_for(std::chrono::milliseconds(2));
            }
            uint8_t st = STATUS_OK;
            uint32_t n = htonl(static_cast<uint32_t>(reply.size()));
            if (!write_all(fd, &st, 1) || !write_all(fd, &n, 4)) break;
            if (!reply.empty() && !write_all(fd, reply.data(), reply.size())) break;
        } else if (op == OP_BAR) {
            // key encodes the barrier id, val empty. Wait until all ranks have
            // posted the same id (counter under kv_).
            std::string ck = "_bar_count_" + key;
            int target = world_size_;
            int after;
            {
                std::lock_guard<std::mutex> lk(kv_mu_);
                auto& slot = kv_[ck];
                int cur = 0;
                if (slot.size() >= sizeof(int)) std::memcpy(&cur, slot.data(), sizeof(int));
                cur += 1;
                slot.assign(sizeof(int), 0);
                std::memcpy(slot.data(), &cur, sizeof(int));
                after = cur;
            }
            (void)after;
            while (true) {
                {
                    std::lock_guard<std::mutex> lk(kv_mu_);
                    int cur = 0;
                    auto& slot = kv_[ck];
                    if (slot.size() >= sizeof(int)) std::memcpy(&cur, slot.data(), sizeof(int));
                    if (cur >= target) break;
                }
                if (stop_.load()) return;
                std::this_thread::sleep_for(std::chrono::milliseconds(2));
            }
            uint8_t st = STATUS_OK;
            uint32_t zero = 0;
            if (!write_all(fd, &st, 1) || !write_all(fd, &zero, 4)) break;
        } else {
            break;
        }
    }
    ::close(fd);
}

void TCPStore::send_request_(uint8_t op, const std::string& key,
                             const std::vector<uint8_t>& val) {
    uint32_t kl = htonl(static_cast<uint32_t>(key.size()));
    uint32_t vl = htonl(static_cast<uint32_t>(val.size()));
    if (!write_all(client_fd_, &op, 1) ||
        !write_all(client_fd_, &kl, 4) ||
        (!key.empty() && !write_all(client_fd_, key.data(), key.size())) ||
        !write_all(client_fd_, &vl, 4) ||
        (!val.empty() && !write_all(client_fd_, val.data(), val.size()))) {
        std::fprintf(stderr, "[commkit] rank %d: send_request failed\n", rank_);
        std::abort();
    }
}

std::vector<uint8_t> TCPStore::recv_response_() {
    uint8_t st;
    uint32_t nl;
    if (!read_all(client_fd_, &st, 1) || !read_all(client_fd_, &nl, 4)) {
        std::fprintf(stderr, "[commkit] rank %d: recv_response header failed\n", rank_);
        std::abort();
    }
    COMMKIT_CHECK(st == STATUS_OK, "TCPStore status != OK");
    uint32_t n = ntohl(nl);
    std::vector<uint8_t> out(n);
    if (n && !read_all(client_fd_, out.data(), n)) {
        std::fprintf(stderr, "[commkit] rank %d: recv_response body failed\n", rank_);
        std::abort();
    }
    return out;
}

void TCPStore::set(const std::string& key, const std::vector<uint8_t>& value) {
    std::lock_guard<std::mutex> lk(client_mu_);
    send_request_(OP_SET, key, value);
    (void)recv_response_();
}

std::vector<uint8_t> TCPStore::get(const std::string& key) {
    std::lock_guard<std::mutex> lk(client_mu_);
    send_request_(OP_GET, key, {});
    return recv_response_();
}

void TCPStore::barrier() {
    std::lock_guard<std::mutex> lk(client_mu_);
    int seq = barrier_seq_++;
    send_request_(OP_BAR, std::to_string(seq), {});
    (void)recv_response_();
}

}  // namespace commkit
