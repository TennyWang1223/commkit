"""Device buffers owned by one kernel instance.

IpcBuffer: every rank allocates one and maps everybody else's through
hipIpcGetMemHandle / hipIpcOpenMemHandle (signals, inboxes, FIFOs, the pull
kernels' input staging). LocalBuffer: rank-local state (round counters,
epochs, partial sums). Both are freed by close(), which the owning op calls
after a group barrier.
"""

from __future__ import annotations

import torch

# hipIpcGetMemHandle exports whole pages; uncached allocations below 2 MiB do
# not export unless page-sized, so IPC buffers are rounded up to 2 MiB.
_IPC_GRANULE = 2 << 20


def _round_up(n: int, a: int) -> int:
    return (n + a - 1) // a * a


class _CudaArray:
    def __init__(self, ptr: int, nbytes: int):
        self.__cuda_array_interface__ = {
            "shape": (nbytes,),
            "typestr": "|u1",
            "data": (ptr, False),
            "version": 3,
        }


def byte_view(ptr: int, nbytes: int, device: torch.device) -> torch.Tensor:
    """uint8 tensor over existing device memory (no copy, no ownership)."""
    return torch.as_tensor(_CudaArray(ptr, nbytes), device=device)


class LocalBuffer:
    """Device memory only this rank touches."""

    def __init__(self, ctx, nbytes: int, uncached: bool = False, fill: int | None = None):
        self.ctx = ctx
        self.nbytes = max(int(nbytes), 16)
        self.uncached = uncached
        self.ptr = ctx.rt.alloc(self.nbytes, uncached)
        if fill is not None:
            ctx.rt.memset(self.ptr, fill, self.nbytes)

    @property
    def peers(self) -> list[int]:
        raise TypeError("a LocalBuffer is not mapped on the peers")

    def close(self) -> None:
        if self.ptr:
            self.ctx.rt.free(self.ptr)
            self.ptr = 0


class IpcBuffer:
    """Device memory every rank of the group maps: `ptr` is this rank's,
    `peers[r]` is rank r's as mapped into this process (peers[rank] == ptr).

    Collective: all ranks construct their IpcBuffers in the same order. The
    fill lands before the handle is published, so no peer can write into the
    buffer before it is initialized.
    """

    def __init__(self, ctx, nbytes: int, uncached: bool = False, fill: int | None = None):
        rt = ctx.rt
        self.ctx = ctx
        self.nbytes = _round_up(max(int(nbytes), 1), _IPC_GRANULE)
        self.uncached = uncached
        self.ptr = rt.alloc(self.nbytes, uncached)
        if fill is not None:
            rt.memset(self.ptr, fill, self.nbytes)
        handles = ctx.all_gather_object(rt.ipc_handle(self.ptr))
        self.peers = [
            self.ptr if r == ctx.rank else rt.ipc_open(h) for r, h in enumerate(handles)
        ]

    def close(self) -> None:
        if not self.ptr:
            return
        rt = self.ctx.rt
        for r, p in enumerate(self.peers):
            if r != self.ctx.rank:
                rt.ipc_close(p)
        rt.free(self.ptr)
        self.ptr = 0
        self.peers = []
