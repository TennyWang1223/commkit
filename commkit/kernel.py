"""commkit.Kernel: one communication kernel bound to a process group."""

from __future__ import annotations

from .context import Context
from .registry import lookup


class Kernel:
    """
        ar = commkit.Kernel("all_reduce", "lamport_1shot_warpsplit")
        out = ar.run(x)
        ar.close()

    The kernel type picks the run() signature, the name picks the
    implementation for this GPU's arch, and keyword arguments configure it
    (max_bytes, block sizes, ...; see the op class).

    Collective: every rank of the group creates the same kernels in the same
    order (the constructor allocates the kernel's own scratch and exchanges
    IPC handles), calls run() with the same shapes, and calls close().
    """

    def __init__(self, kernel_type: str, kernel_name: str, group=None, **cfg):
        ctx = Context.get(group)
        cls = lookup(ctx.family, kernel_type, kernel_name)
        ctx.check_same("Kernel() arguments", (kernel_type, kernel_name, sorted(cfg.items())))
        self.op = cls(ctx, **cfg)

    def run(self, *args, **kwargs):
        return self.op.run(*args, **kwargs)

    def close(self) -> None:
        self.op.close()

    def __getattr__(self, attr):
        # input_buffer(), max_bytes, proto, mode, ... of the op
        if attr == "op":
            raise AttributeError(attr)
        return getattr(self.op, attr)

    def __enter__(self) -> "Kernel":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    def __repr__(self) -> str:
        op = self.op
        return (
            f"Kernel({op.kernel_type}/{op.name}, {op.family}, proto={op.proto}, mode={op.mode}, "
            f"rank={op.rank}/{op.world_size}, max_bytes={op.max_bytes})"
        )
