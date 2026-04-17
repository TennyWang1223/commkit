#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <unordered_map>
#include <vector>
#include <hip/hip_runtime.h>

#include "commkit/signal.hpp"

namespace commkit {

class TCPStore;
class IPCBufferPool;

// Lightweight communication group for a single tensor-parallel slice.
//
// Lifecycle:
//   CommGroup g(world_size);   // ctor stores params only
//   g.init();                  // env parse, hipSetDevice, IPC handle exchange,
//                              // meta+input buffer alloc & registration
//   g.rank() / g.stream() / g.self_signal() / g.rank_signals() / g.rank_data(p)
//                              // hand to kernel launches directly
//   ~CommGroup();              // releases buffers and IPC handles
//
// Bootstrap reads RANK / LOCAL_RANK / WORLD_SIZE / MASTER_ADDR / MASTER_PORT
// from the environment. The launcher (scripts/run.sh) is expected to set them.
class CommGroup {
 public:
    explicit CommGroup(int world_size, std::size_t max_size = 1ULL << 30);
    ~CommGroup();

    CommGroup(const CommGroup&) = delete;
    CommGroup& operator=(const CommGroup&) = delete;

    void init();

    // ----- Accessors used by kernel launches -----
    int rank() const { return rank_; }
    int local_rank() const { return local_rank_; }
    int world_size() const { return world_size_; }
    hipStream_t stream() const { return stream_; }
    Signal* self_signal() const { return self_sg_; }
    RankSignals rank_signals() const { return sg_; }

    // Returns the device-side RankData* for an already-registered input buffer.
    // Aborts if the pointer was never registered (and not in capture mode).
    RankData* rank_data(void* input);
    RankData* output_rank_data(void* output);

    // Pre-allocated D2D relay buffer (used when kernel input isn't separately
    // registered — copy input into here first then launch with this as the
    // registered buffer).
    void* registered_input_ptr() const;
    std::size_t registered_input_size() const;

    // ----- External buffer registration -----
    void register_input_buffer(void* ptr);
    void register_output_buffer(void* ptr);

    // ----- Graph capture -----
    void begin_capture();
    void end_capture();

    // Cross-rank synchronization (delegated to the underlying TCPStore).
    void barrier();
    TCPStore* store() { return store_.get(); }

 private:
    int rank_{-1};
    int local_rank_{-1};
    int world_size_{-1};
    std::size_t max_size_{0};
    bool initialized_{false};

    hipStream_t stream_{nullptr};

    // Pointer to the head of the local meta buffer; layout = [Signal | scratch].
    Signal* self_sg_{nullptr};
    RankSignals sg_{};

    // Device-side RankData pool. self_rank_data_base_ is the host bookkeeping
    // pointer; the underlying memory comes from rank_data_buf_ (device-side).
    void* rank_data_buf_{nullptr};
    std::size_t rank_data_capacity_{0};
    RankData* rank_data_base_{nullptr};
    RankData* rank_data_end_{nullptr};

    std::unordered_map<void*, RankData*> input_buffers_;
    std::unordered_map<void*, RankData*> output_buffers_;

    bool capturing_{false};
    std::vector<void*> graph_unreg_inputs_;
    std::vector<void*> graph_unreg_outputs_;

    std::unique_ptr<TCPStore> store_;
    std::unique_ptr<IPCBufferPool> pool_;

    void register_input_with_handles_(
        void* self,
        const std::vector<std::vector<uint8_t>>& handles,
        const std::vector<int64_t>& offsets);
    void register_output_with_handles_(
        void* self,
        const std::vector<std::vector<uint8_t>>& handles,
        const std::vector<int64_t>& offsets);
    void check_rank_data_capacity_(std::size_t n);
    void flush_graph_buffers_();
};

}  // namespace commkit
