"""Op base classes.

Op            one kernel instance: loads its JIT module, allocates the scratch
              its launch file declares (scratch_spec), checks arguments.
PullOp        peers read this rank's input in place; owns an IPC staging
              buffer and copies the input into it (one D2D copy) unless the
              input was written into input_buffer() directly.
PushOp        this rank writes into the peers' buffers; the input stays put.
*Op (types)   run() of each kernel type: argument checks, output allocation,
              then the kernel's launch(). No dispatch: a kernel either takes
              the arguments or raises with the reason.
"""

from __future__ import annotations

import math

import torch

from .. import jit
from ..buffer import IpcBuffer, LocalBuffer, byte_view

FLOAT = (torch.float32, torch.float16, torch.bfloat16)
HALF = (torch.float16, torch.bfloat16)
# dtype codes of csrc/include/commkit/host.hpp
DTYPE_CODE = {torch.float32: 0, torch.float16: 1, torch.bfloat16: 2}
PACK_BYTES = 16

MiB = 1 << 20


def nbytes_of(t: torch.Tensor) -> int:
    return t.numel() * t.element_size()


class Op:
    # set by @register
    family: str
    kernel_type: str
    name: str
    proto: str
    # set by PullOp / PushOp
    mode: str

    dtypes = FLOAT
    world_sizes = (2, 4, 8)
    default_max_bytes = 64 * MiB

    def __init__(self, ctx, max_bytes: int | None = None):
        if ctx.world_size not in self.world_sizes:
            raise ValueError(
                f"{self}: world size {ctx.world_size} not supported, needs one of {self.world_sizes}"
            )
        self.ctx = ctx
        self.rank = ctx.rank
        self.world_size = ctx.world_size
        self.mod = jit.load_kernel(ctx.family, ctx.arch, self.kernel_type, self.mode, self.name)
        # kernels whose scratch layout is compile-time export their capacity
        limit = getattr(self.mod, "max_bytes", None)
        if max_bytes is None:
            max_bytes = limit if limit is not None else self.default_max_bytes
        self.max_bytes = int(max_bytes)
        if self.max_bytes <= 0:
            raise ValueError(f"{self}: max_bytes must be positive")
        if limit is not None and self.max_bytes > limit:
            raise ValueError(f"{self}: max_bytes {self.max_bytes} exceeds the kernel's fixed capacity {limit}")
        self.bufs: dict[str, IpcBuffer | LocalBuffer] = {}
        for name, nbytes, ipc, uncached, fill in self.mod.scratch_spec(self.max_bytes, self.world_size):
            kind = IpcBuffer if ipc else LocalBuffer
            self.bufs[name] = kind(ctx, nbytes, uncached, None if fill < 0 else fill)
        self._setup()
        # every rank's scratch is initialized and mapped before anyone launches
        torch.cuda.synchronize(ctx.device)
        ctx.barrier()
        self._closed = False

    def _setup(self) -> None:
        """Hook for buffers that are not in scratch_spec (pull staging)."""

    # ----------------------------------------------------------- helpers ---
    def stream(self) -> int:
        # the raw query; torch.cuda.current_stream().cuda_stream costs ~4 us
        # of CPU per call, which shows in eager latency
        return torch._C._cuda_getCurrentRawStream(self.ctx.device.index)

    @staticmethod
    def dtype_code(t: torch.Tensor) -> int:
        return DTYPE_CODE[t.dtype]

    def peers(self, name: str) -> list[int]:
        return self.bufs[name].peers

    def ptr(self, name: str) -> int:
        return self.bufs[name].ptr

    def fail(self, msg: str, exc=ValueError):
        raise exc(f"{self}: {msg}")

    def check_tensor(self, t: torch.Tensor, what: str = "input") -> None:
        if not isinstance(t, torch.Tensor):
            self.fail(f"{what} must be a tensor", TypeError)
        if t.device != self.ctx.device:
            self.fail(f"{what} is on {t.device}, the kernel on {self.ctx.device}")
        if t.dtype not in self.dtypes:
            self.fail(f"{what} dtype {t.dtype} not supported, needs one of {self.dtypes}", TypeError)
        if not t.is_contiguous():
            self.fail(f"{what} must be contiguous")

    def check_like(self, t: torch.Tensor, ref: torch.Tensor, what: str, shape=None) -> None:
        shape = tuple(ref.shape) if shape is None else tuple(shape)
        if not isinstance(t, torch.Tensor) or tuple(t.shape) != shape:
            self.fail(f"{what} must have shape {shape}")
        if t.dtype != ref.dtype or t.device != ref.device or not t.is_contiguous():
            self.fail(f"{what} must be contiguous, {ref.dtype}, on {ref.device}")

    def check_capacity(self, nbytes: int, limit: int | None = None, what: str = "input") -> None:
        limit = self.max_bytes if limit is None else limit
        if nbytes > limit:
            self.fail(
                f"{what} is {nbytes} bytes, over the kernel's {limit}-byte capacity "
                f"(max_bytes={self.max_bytes})"
            )

    def check_multiple(self, value: int, multiple: int, what: str) -> None:
        if value % multiple:
            self.fail(f"{what} ({value}) must be a multiple of {multiple}")

    def close(self) -> None:
        """Collective: frees the scratch once every rank is done with it."""
        if getattr(self, "_closed", True):
            return
        torch.cuda.synchronize(self.ctx.device)
        self.ctx.barrier()
        for buf in self.bufs.values():
            buf.close()
        self._closed = True

    def __str__(self) -> str:
        return f"{getattr(self, 'kernel_type', '?')}/{getattr(self, 'name', '?')}"


class PullOp(Op):
    """Peers read this rank's input in place, so the input has to sit in IPC
    memory: run() copies it into the op's staging buffer first (one D2D copy;
    captured into a graph together with the kernel). Write the input into
    input_buffer() to skip the copy."""

    mode = "pull"

    def _setup(self) -> None:
        super()._setup()
        self.bufs["staging"] = self.staging = IpcBuffer(self.ctx, self.max_bytes)
        self._staging_u8 = byte_view(self.staging.ptr, self.staging.nbytes, self.ctx.device)

    def input_buffer(self, shape, dtype: torch.dtype) -> torch.Tensor:
        """A tensor over the staging buffer: an input written here is read by
        the peers directly, without the copy."""
        shape = tuple(shape) if isinstance(shape, (tuple, list, torch.Size)) else (shape,)
        nbytes = math.prod(shape) * torch.empty((), dtype=dtype).element_size()
        self.check_capacity(nbytes)
        return self._staging_u8[:nbytes].view(dtype).view(shape)

    def stage(self, x: torch.Tensor) -> list[int]:
        """Puts x into the staging buffer; returns every rank's staging pointer."""
        nbytes = nbytes_of(x)
        lo, base = x.data_ptr(), self.staging.ptr
        if lo != base:
            if base <= lo < base + self.staging.nbytes:
                self.fail("an input inside the staging buffer must start at its beginning")
            # one hipMemcpyAsync; slicing + copy_ through torch costs ~8 us of CPU
            self.ctx.rt.memcpy_async(base, lo, nbytes, self.stream())
        return self.staging.peers


class PushOp(Op):
    """This rank pushes its data into the peers' buffers; the input is read
    where it is."""

    mode = "push"


# --------------------------------------------------------------------------
# kernel types: run() signatures
# --------------------------------------------------------------------------
class AllReduceOp(Op):
    """run(x, out=None) -> out: the sum of x over the group, on every rank.
    x is whole 16-byte packs, at most max_bytes."""

    def run(self, x: torch.Tensor, out: torch.Tensor | None = None) -> torch.Tensor:
        self.check_tensor(x)
        nbytes = nbytes_of(x)
        self.check_multiple(nbytes, PACK_BYTES, "input bytes")
        self.check_capacity(nbytes)
        self.check_input(x)
        if out is None:
            out = torch.empty_like(x)
        else:
            self.check_like(out, x, "out")
        if nbytes:
            self.launch(x, out)
        return out

    def check_input(self, x: torch.Tensor) -> None:
        """Kernel-specific constraints."""

    def launch(self, x: torch.Tensor, out: torch.Tensor) -> None:
        raise NotImplementedError


class AllGatherOp(Op):
    """run(x, dim=0, out=None) -> every rank's x concatenated along dim, the
    first or the last dim. x is at most max_bytes."""

    dims = ("first", "last")

    def run(self, x: torch.Tensor, dim: int = 0, out: torch.Tensor | None = None) -> torch.Tensor:
        self.check_tensor(x)
        if x.dim() == 0:
            self.fail("input must have at least one dim")
        d = dim % x.dim()
        kind = "first" if d == 0 else ("last" if d == x.dim() - 1 else "middle")
        if kind not in self.dims:
            self.fail(f"gathers along {self.dims} dims, not dim {dim} of a {x.dim()}-d input")
        nbytes = nbytes_of(x)
        self.check_capacity(nbytes)
        self.check_input(x, kind)
        shape = list(x.shape)
        shape[d] *= self.world_size
        if out is None:
            out = x.new_empty(shape)
        else:
            self.check_like(out, x, "out", shape)
        if nbytes:
            self.launch(x, out, kind)
        return out

    def check_input(self, x: torch.Tensor, kind: str) -> None:
        """Kernel-specific constraints."""

    def launch(self, x: torch.Tensor, out: torch.Tensor, kind: str) -> None:
        raise NotImplementedError


class ReduceScatterOp(Op):
    """run(x, dim=0, out=None) -> chunk `rank` along dim of the sum of x over
    the group. x.shape[dim] is a multiple of the world size; x is at most
    max_bytes.

    x is seen as (m, n, k) = (prod(shape[:dim]), shape[dim],
    prod(shape[dim+1:])) and scattered along n."""

    def run(self, x: torch.Tensor, dim: int = 0, out: torch.Tensor | None = None) -> torch.Tensor:
        self.check_tensor(x)
        if x.dim() == 0:
            self.fail("input must have at least one dim")
        d = dim % x.dim()
        if x.shape[d] % self.world_size:
            self.fail(f"dim {dim} ({x.shape[d]}) is not a multiple of the world size")
        m, n, k = math.prod(x.shape[:d]), x.shape[d], math.prod(x.shape[d + 1 :])
        self.check_capacity(nbytes_of(x))
        self.check_input(x, m, n, k)
        shape = list(x.shape)
        shape[d] //= self.world_size
        if out is None:
            out = x.new_empty(shape)
        else:
            self.check_like(out, x, "out", shape)
        if x.numel():
            self.launch(x, out, m, n, k)
        return out

    def check_input(self, x: torch.Tensor, m: int, n: int, k: int) -> None:
        """Kernel-specific constraints."""

    def launch(self, x: torch.Tensor, out: torch.Tensor, m: int, n: int, k: int) -> None:
        raise NotImplementedError


class AllReduceRmsnormOp(Op):
    """run(x, residual, weight, eps=1e-6, gemma_norm=False) -> (out, residual_out)

        residual_out = all_reduce(x) + residual
        out          = residual_out * rsqrt(mean(residual_out**2) + eps) * w
        w            = weight (weight + 1 with gemma_norm)

    x, residual: [..., hidden], weight: [hidden]. The all-reduce result is
    rounded to the dtype before the residual add, like all_reduce followed by
    a separate add."""

    def run(
        self,
        x: torch.Tensor,
        residual: torch.Tensor,
        weight: torch.Tensor,
        eps: float = 1e-6,
        gemma_norm: bool = False,
        out: torch.Tensor | None = None,
        residual_out: torch.Tensor | None = None,
    ):
        self.check_tensor(x)
        if x.dim() == 0:
            self.fail("input must have at least one dim")
        self.check_like(residual, x, "residual")
        hidden = x.shape[-1]
        self.check_like(weight, x, "weight", (hidden,))
        rows = x.numel() // hidden if hidden else 0
        self.check_capacity(nbytes_of(x))
        self.check_multiple(hidden * x.element_size(), PACK_BYTES, "hidden bytes")
        self.check_input(x, rows, hidden)
        if out is None:
            out = torch.empty_like(x)
        else:
            self.check_like(out, x, "out")
        if residual_out is None:
            residual_out = torch.empty_like(x)
        else:
            self.check_like(residual_out, x, "residual_out")
        if x.numel():
            self.launch(x, residual, weight, out, residual_out, rows, hidden, float(eps), bool(gemma_norm))
        return out, residual_out

    def check_input(self, x: torch.Tensor, rows: int, hidden: int) -> None:
        """Kernel-specific constraints."""

    def launch(self, x, residual, weight, out, residual_out, rows, hidden, eps, gemma_norm) -> None:
        raise NotImplementedError
