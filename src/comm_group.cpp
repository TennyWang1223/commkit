#include "commkit/comm_group.hpp"
#include "commkit/hip_check.hpp"
#include "commkit/ipc_buffer.hpp"
#include "commkit/tcp_store.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <string>

namespace commkit {

namespace {

int env_int(const char* name, int fallback = -1) {
    const char* v = std::getenv(name);
    if (!v || !*v) return fallback;
    return std::atoi(v);
}

std::string env_str(const char* name, const char* fallback) {
    const char* v = std::getenv(name);
    return std::string((v && *v) ? v : fallback);
}

}  // namespace

CommGroup::CommGroup(int world_size, std::size_t max_size)
    : world_size_(world_size), max_size_(max_size) {}

CommGroup::~CommGroup() {
    if (!initialized_) return;
    if (rank_data_buf_) {
        (void)hipFree(rank_data_buf_);
        rank_data_buf_ = nullptr;
    }
    pool_.reset();
    clear_ipc_handle_cache();
    if (stream_) {
        (void)hipStreamDestroy(stream_);
        stream_ = nullptr;
    }
    store_.reset();
}

void CommGroup::init() {
    COMMKIT_CHECK(!initialized_, "CommGroup::init called twice");

    // 1. env -> rank / local_rank
    rank_ = env_int("RANK");
    local_rank_ = env_int("LOCAL_RANK", rank_);
    int env_world = env_int("WORLD_SIZE");
    COMMKIT_CHECK(rank_ >= 0 && env_world > 0,
                  "RANK / WORLD_SIZE env vars not set (use scripts/run.sh)");
    COMMKIT_CHECK(env_world == world_size_,
                  "WORLD_SIZE env mismatch with CommGroup(world_size)");

    // 2. bind device
    COMMKIT_HIP_CALL(hipSetDevice(local_rank_));
    COMMKIT_HIP_CALL(hipStreamCreate(&stream_));

    // 3. TCP store bootstrap
    auto master_addr = env_str("MASTER_ADDR", "127.0.0.1");
    int master_port = env_int("MASTER_PORT", 29500);
    store_ = std::make_unique<TCPStore>(rank_, world_size_, master_addr, master_port);
    store_->barrier();

    // 4. allocate buffers via pool
    pool_ = std::make_unique<IPCBufferPool>(rank_, world_size_, store_.get());
    // meta layout: [Signal | scratch (2 * max_size)]; scratch sized to fit
    // 2-stage reduce-scatter + extra write-mode slot.
    pool_->create("meta", sizeof(Signal) + max_size_ * 2, /*uncached=*/true);
    pool_->create("input", max_size_, /*uncached=*/false);

    self_sg_ = static_cast<Signal*>(pool_->at("meta").data());

    // 5. RankData host-side pool (small device buffer holding ngpus*ptrs entries).
    // Sized for ~131k registrations like aiter.
    rank_data_capacity_ = 8 * 1024 * 1024;
    COMMKIT_HIP_CALL(hipMalloc(&rank_data_buf_, rank_data_capacity_));
    rank_data_base_ = reinterpret_cast<RankData*>(rank_data_buf_);
    rank_data_end_ = rank_data_base_ + rank_data_capacity_ / sizeof(RankData);

    // 6. exchange meta IPC handles, fill RankSignals
    auto [meta_handles, meta_offsets] = pool_->get_ipc_meta("meta");
    for (int i = 0; i < world_size_; ++i) {
        if (i == rank_) {
            sg_.signals[i] = self_sg_;
        } else {
            char* base = static_cast<char*>(open_ipc_handle(meta_handles[i].data()));
            sg_.signals[i] = reinterpret_cast<Signal*>(base + meta_offsets[i]);
        }
    }

    // 7. register the pre-allocated "input" relay buffer
    auto [in_handles, in_offsets] = pool_->get_ipc_meta("input");
    register_input_with_handles_(pool_->at("input").data(), in_handles, in_offsets);

    store_->barrier();
    initialized_ = true;
}

void CommGroup::check_rank_data_capacity_(std::size_t n) {
    if (rank_data_base_ + n > rank_data_end_) {
        std::fprintf(stderr, "[commkit] RankData buffer overflow (need %zu more)\n", n);
        std::abort();
    }
}

void CommGroup::register_input_with_handles_(
    void* self,
    const std::vector<std::vector<uint8_t>>& handles,
    const std::vector<int64_t>& offsets) {
    check_rank_data_capacity_(1);
    RankData host_rd{};
    for (int i = 0; i < world_size_; ++i) {
        if (i == rank_) {
            host_rd.ptrs[i] = self;
        } else {
            char* base = static_cast<char*>(open_ipc_handle(handles[i].data()));
            host_rd.ptrs[i] = base + offsets[i];
        }
    }
    RankData* dev = rank_data_base_++;
    COMMKIT_HIP_CALL(hipMemcpy(dev, &host_rd, sizeof(RankData), hipMemcpyHostToDevice));
    input_buffers_[self] = dev;
}

void CommGroup::register_output_with_handles_(
    void* self,
    const std::vector<std::vector<uint8_t>>& handles,
    const std::vector<int64_t>& offsets) {
    check_rank_data_capacity_(1);
    RankData host_rd{};
    for (int i = 0; i < world_size_; ++i) {
        if (i == rank_) {
            host_rd.ptrs[i] = self;
        } else {
            char* base = static_cast<char*>(open_ipc_handle(handles[i].data()));
            host_rd.ptrs[i] = base + offsets[i];
        }
    }
    RankData* dev = rank_data_base_++;
    COMMKIT_HIP_CALL(hipMemcpy(dev, &host_rd, sizeof(RankData), hipMemcpyHostToDevice));
    output_buffers_[self] = dev;
}

void CommGroup::register_input_buffer(void* ptr) {
    auto [h, o] = pool_->get_external_ipc_meta(ptr);
    register_input_with_handles_(ptr, h, o);
}

void CommGroup::register_output_buffer(void* ptr) {
    auto [h, o] = pool_->get_external_ipc_meta(ptr);
    register_output_with_handles_(ptr, h, o);
}

RankData* CommGroup::rank_data(void* input) {
    auto it = input_buffers_.find(input);
    if (it != input_buffers_.end()) return it->second;

    if (capturing_) {
        // During graph capture we can't broadcast IPC handles synchronously.
        // Reserve a slot now, defer registration until end_capture().
        check_rank_data_capacity_(graph_unreg_inputs_.size() + 1);
        RankData* slot = rank_data_base_ + graph_unreg_inputs_.size();
        graph_unreg_inputs_.push_back(input);
        return slot;
    }
    std::fprintf(stderr,
                 "[commkit] input buffer %p not registered "
                 "(call register_input_buffer or use begin_capture())\n",
                 input);
    std::abort();
}

RankData* CommGroup::output_rank_data(void* output) {
    auto it = output_buffers_.find(output);
    if (it != output_buffers_.end()) return it->second;

    if (capturing_) {
        check_rank_data_capacity_(graph_unreg_inputs_.size() + graph_unreg_outputs_.size() + 1);
        RankData* slot = rank_data_base_ + graph_unreg_inputs_.size() + graph_unreg_outputs_.size();
        graph_unreg_outputs_.push_back(output);
        return slot;
    }
    std::fprintf(stderr, "[commkit] output buffer %p not registered\n", output);
    std::abort();
}

void* CommGroup::registered_input_ptr() const { return pool_->at("input").data(); }
std::size_t CommGroup::registered_input_size() const { return pool_->at("input").size(); }

void CommGroup::begin_capture() { capturing_ = true; }

void CommGroup::end_capture() {
    capturing_ = false;
    flush_graph_buffers_();
}

void CommGroup::flush_graph_buffers_() {
    std::size_t num_in = graph_unreg_inputs_.size();
    std::size_t num_out = graph_unreg_outputs_.size();
    std::size_t total = num_in + num_out;
    if (total == 0) return;
    check_rank_data_capacity_(total);

    // Exchange one IPC meta per buffer through the TCP store. This mirrors
    // aiter's flush_graph_buffers but goes one-by-one rather than packed —
    // graph capture is rare and small batches dominate in practice.
    std::vector<RankData> rds(total);
    for (std::size_t i = 0; i < num_in; ++i) {
        auto [h, o] = pool_->get_external_ipc_meta(graph_unreg_inputs_[i]);
        for (int j = 0; j < world_size_; ++j) {
            if (j == rank_) {
                rds[i].ptrs[j] = graph_unreg_inputs_[i];
            } else {
                char* base = static_cast<char*>(open_ipc_handle(h[j].data()));
                rds[i].ptrs[j] = base + o[j];
            }
        }
    }
    for (std::size_t i = 0; i < num_out; ++i) {
        auto [h, o] = pool_->get_external_ipc_meta(graph_unreg_outputs_[i]);
        for (int j = 0; j < world_size_; ++j) {
            if (j == rank_) {
                rds[num_in + i].ptrs[j] = graph_unreg_outputs_[i];
            } else {
                char* base = static_cast<char*>(open_ipc_handle(h[j].data()));
                rds[num_in + i].ptrs[j] = base + o[j];
            }
        }
        output_buffers_[graph_unreg_outputs_[i]] = rank_data_base_ + num_in + i;
    }

    COMMKIT_HIP_CALL(
        hipMemcpy(rank_data_base_, rds.data(), sizeof(RankData) * total, hipMemcpyHostToDevice));
    rank_data_base_ += total;
    graph_unreg_inputs_.clear();
    graph_unreg_outputs_.clear();
}

void CommGroup::barrier() { store_->barrier(); }

}  // namespace commkit
