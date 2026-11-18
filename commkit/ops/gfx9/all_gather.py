"""gfx9 all_gather kernels (csrc/gfx9/kernel/all_gather/)."""

from __future__ import annotations

from ...registry import register
from ..base import PACK_BYTES, AllGatherOp, PullOp

FAMILY = "gfx9"


@register(FAMILY, "all_gather", "simple_pull")
class SimplePull(AllGatherOp, PullOp):
    """aiter allgather_vec (first dim) / allgather_lastdim (last dim): per-peer
    thread groups copy each rank's input in 16-byte packs."""

    def check_input(self, x, kind):
        if kind == "first":
            self.check_multiple(x.numel() * x.element_size(), PACK_BYTES, "input bytes")
        else:
            self.check_multiple(x.shape[-1] * x.element_size(), PACK_BYTES, "last dim bytes")

    def launch(self, x, out, kind):
        self.mod.launch(
            self.stage(x),
            self.peers("signal"),
            out.data_ptr(),
            x.numel(),
            0 if kind == "first" else x.shape[-1],
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_gather", "simple_pull_naive")
class SimplePullNaive(AllGatherOp, PullOp):
    """aiter allgather_naive: first dim, element by element, any size."""

    dims = ("first",)

    def launch(self, x, out, kind):
        self.mod.launch(
            self.stage(x),
            self.peers("signal"),
            out.data_ptr(),
            x.numel(),
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )
