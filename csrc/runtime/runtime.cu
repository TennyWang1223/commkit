// Device memory and IPC primitives behind commkit/buffer.py. Host code only;
// the same module serves every arch.
#include <cstring>

#include "commkit/host.hpp"

namespace {

// uncached: hipDeviceMallocUncached, for flags and inboxes that are polled
// across GPUs; otherwise plain hipMalloc
int64_t alloc(int64_t bytes, bool uncached)
{
    void* ptr = nullptr;
    if(uncached)
        CK_HIP_CHECK(hipExtMallocWithFlags(&ptr, bytes, hipDeviceMallocUncached));
    else
        CK_HIP_CHECK(hipMalloc(&ptr, bytes));
    return reinterpret_cast<int64_t>(ptr);
}

void freeDevice(int64_t ptr) { CK_HIP_CHECK(hipFree(reinterpret_cast<void*>(ptr))); }

// blocking: the fill has landed when this returns
void memsetSync(int64_t ptr, int value, int64_t bytes)
{
    CK_HIP_CHECK(hipMemset(reinterpret_cast<void*>(ptr), value, bytes));
    CK_HIP_CHECK(hipDeviceSynchronize());
}

// stream-ordered D2D copy (the pull ops' input staging; graph-capturable)
void memcpyAsync(int64_t dst, int64_t src, int64_t bytes, int64_t stream)
{
    CK_HIP_CHECK(hipMemcpyAsync(reinterpret_cast<void*>(dst),
                                reinterpret_cast<const void*>(src),
                                bytes,
                                hipMemcpyDeviceToDevice,
                                reinterpret_cast<hipStream_t>(stream)));
}

py::bytes ipcHandle(int64_t ptr)
{
    hipIpcMemHandle_t handle;
    CK_HIP_CHECK(hipIpcGetMemHandle(&handle, reinterpret_cast<void*>(ptr)));
    return py::bytes(reinterpret_cast<const char*>(&handle), sizeof(handle));
}

int64_t ipcOpen(const py::bytes& raw)
{
    std::string bytes = raw;
    hipIpcMemHandle_t handle;
    if(bytes.size() != sizeof(handle))
        throw std::invalid_argument("ipc handle must be " + std::to_string(sizeof(handle)) +
                                    " bytes, got " + std::to_string(bytes.size()));
    std::memcpy(&handle, bytes.data(), sizeof(handle));
    void* ptr = nullptr;
    CK_HIP_CHECK(hipIpcOpenMemHandle(&ptr, handle, hipIpcMemLazyEnablePeerAccess));
    return reinterpret_cast<int64_t>(ptr);
}

void ipcClose(int64_t ptr) { CK_HIP_CHECK(hipIpcCloseMemHandle(reinterpret_cast<void*>(ptr))); }

} // namespace

CK_MODULE(m)
{
    m.def("alloc", &alloc, py::arg("bytes"), py::arg("uncached"));
    m.def("free", &freeDevice, py::arg("ptr"));
    m.def("memset", &memsetSync, py::arg("ptr"), py::arg("value"), py::arg("bytes"));
    m.def("memcpy_async", &memcpyAsync, py::arg("dst"), py::arg("src"), py::arg("bytes"), py::arg("stream"));
    m.def("ipc_handle", &ipcHandle, py::arg("ptr"));
    m.def("ipc_open", &ipcOpen, py::arg("handle"));
    m.def("ipc_close", &ipcClose, py::arg("ptr"));
}
