"""gfx1250 reduce_scatter kernels (csrc/gfx1250/kernel/reduce_scatter/)."""

from __future__ import annotations

from ...registry import register
from ..base import PACK_BYTES, PullOp, ReduceScatterOp
from ._common import check_int32

FAMILY = "gfx1250"


class _SimplePull(ReduceScatterOp, PullOp):
    def check_input(self, x, m, n, k):
        check_int32(self, x.numel(), "input elements")

    def launch(self, x, out, m, n, k):
        self.mod.launch(
            self.stage(x),
            self.peers("signal"),
            out.data_ptr(),
            m,
            n,
            k,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "reduce_scatter", "simple_pull")
class SimplePull(_SimplePull):
    """aiter rs_gfx1250_split_{first_dim,lastdim,middim}: 16-byte packs, rank r
    sums its chunk in rank order straight from the peers' staged inputs. The
    chunk must be whole packs along the contiguous dims (else
    simple_pull_naive)."""

    def check_input(self, x, m, n, k):
        super().check_input(x, m, n, k)
        elem = x.element_size()
        if m == 1:  # first dim: chunk r is a contiguous range
            self.check_multiple(n * k * elem, PACK_BYTES * self.world_size, "input bytes")
        elif k == 1:  # last dim
            self.check_multiple(n * elem, PACK_BYTES * self.world_size, "scattered dim bytes")
        else:
            self.check_multiple(k * elem, PACK_BYTES, "bytes after the scattered dim")


@register(FAMILY, "reduce_scatter", "simple_pull_naive")
class SimplePullNaive(_SimplePull):
    """aiter rs_gfx1250_split_{lastdim,middim}_naive: element by element, any
    shape (a first-dim scatter runs as the middle-dim kernel with m = 1)."""
