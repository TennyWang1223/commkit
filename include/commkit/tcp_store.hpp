#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>
#include <mutex>
#include <thread>
#include <atomic>

namespace commkit {

// Minimal TCP key-value store for IPC handle exchange.
//
// Wire protocol (length-prefixed):
//   client -> server : op(uint8) | key_len(uint32) | key | val_len(uint32) | val
//                      where op = 0 (SET), 1 (GET), 2 (BARRIER)
//   server -> client : status(uint8) | val_len(uint32) | val
//
// Rank 0 runs the server; other ranks connect as clients. set/get/barrier are
// blocking. get blocks until the key has been set.
class TCPStore {
 public:
    TCPStore(int rank, int world_size, std::string master_addr, int master_port);
    ~TCPStore();

    void set(const std::string& key, const std::vector<uint8_t>& value);
    std::vector<uint8_t> get(const std::string& key);
    void barrier();

 private:
    int rank_;
    int world_size_;
    std::string master_addr_;
    int master_port_;

    // Server-only state (rank 0)
    std::thread server_thread_;
    std::atomic<bool> stop_{false};
    int listen_fd_{-1};
    std::mutex kv_mu_;
    std::unordered_map<std::string, std::vector<uint8_t>> kv_;

    // Client-side state (all ranks): persistent connection to the server.
    int client_fd_{-1};
    std::mutex client_mu_;
    int barrier_seq_{0};

    void run_server_();
    void handle_client_(int fd);
    void connect_client_();
    void send_request_(uint8_t op, const std::string& key, const std::vector<uint8_t>& val);
    std::vector<uint8_t> recv_response_();
};

}  // namespace commkit
