"""gfx9 all_reduce + residual + RMSNorm kernels
(csrc/gfx9/kernel/all_reduce_rmsnorm/)."""

from __future__ import annotations

import torch

from ...buffer import LocalBuffer
from ...registry import register
from ..base import HALF, PACK_BYTES, AllReduceRmsnormOp, PullOp, PushOp

FAMILY = "gfx9"


class _SimplePull(AllReduceRmsnormOp, PullOp):
    def launch(self, x, residual, weight, out, residual_out, rows, hidden, eps, gemma_norm):
        self.mod.launch(
            self.stage(x),
            self.peers("signal"),
            residual.data_ptr(),
            weight.data_ptr(),
            out.data_ptr(),
            residual_out.data_ptr(),
            rows,
            hidden,
            eps,
            gemma_norm,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_reduce_rmsnorm", "simple_pull_1shot")
class OneShotSimplePull(_SimplePull):
    """aiter allreduce_fusion_kernel_1stage: a block per row pulls the row from
    every rank, adds the residual and normalizes. hidden <= 1024 packs."""

    def check_input(self, x, rows, hidden):
        packs = hidden * x.element_size() // PACK_BYTES
        if packs > 1024:
            self.fail(f"hidden {hidden} is {packs} packs, at most 1024 (a row is one block)")


@register(FAMILY, "all_reduce_rmsnorm", "simple_pull_2shot")
class TwoShotSimplePull(_SimplePull):
    """aiter allreduce_fusion_kernel_2stage: a block per row reduce-scatters
    its row in LDS, pushes the sums to every rank, then normalizes. hidden /
    pack is a multiple of 32 and of the world size, at most 1024."""

    def check_input(self, x, rows, hidden):
        packs = hidden * x.element_size() // PACK_BYTES
        if packs > 1024 or packs % 32 or packs % self.world_size:
            self.fail(
                f"hidden {hidden} is {packs} packs: needs a multiple of 32 and of the world size, "
                "at most 1024"
            )


@register(FAMILY, "all_reduce_rmsnorm", "simple_pull_2shot_split")
class TwoShotSimplePullSplit(_SimplePull):
    """aiter reduce_scatter_cross_device_store + local_device_load_rmsnorm: a
    reduce-scatter launch that pushes the sums to every rank, then a local
    RMSNorm launch. 64 <= hidden / pack <= 2048; rows * hidden / pack is a
    multiple of the world size."""

    def check_input(self, x, rows, hidden):
        packs = hidden * x.element_size() // PACK_BYTES
        if not 64 <= packs <= 2048:
            self.fail(f"hidden {hidden} is {packs} packs, needs 64 to 2048")
        self.check_multiple(rows * packs, self.world_size, "rows * hidden packs")


class _Lamport(AllReduceRmsnormOp, PushOp):
    """hidden a multiple of 512, at most 8192 (a row fits one block)."""

    dtypes = HALF

    def check_input(self, x, rows, hidden):
        if hidden % 512 or hidden > 8192:
            self.fail(f"hidden {hidden} must be a multiple of 512, at most 8192")


class _OneShotLamport(_Lamport):
    """One-shot kernels: rows split over blocks publish sum-of-squares
    partials in rank-local state kept per hidden size. That state is made by
    the first eager call with a hidden size (or up front: hiddens=[...]); a
    graph capture cannot allocate it."""

    def __init__(self, ctx, max_bytes=None, hiddens=()):
        super().__init__(ctx, max_bytes)
        self._partials: dict[int, tuple[LocalBuffer, LocalBuffer]] = {}
        for hidden in hiddens:
            self._partial_state(hidden)

    def _partial_state(self, hidden: int) -> tuple[int, int]:
        state = self._partials.get(hidden)
        if state is None:
            if torch.cuda.is_current_stream_capturing():
                self.fail(
                    f"hidden {hidden} first seen inside a graph capture: run it once eagerly "
                    "(or pass hiddens=[...]) to create its rank-local state",
                    RuntimeError,
                )
            state = (
                LocalBuffer(self.ctx, self.mod.partials_bytes, uncached=True, fill=0xFF),
                LocalBuffer(self.ctx, self.mod.partial_round_bytes, fill=0),
            )
            self._partials[hidden] = state
        return state[0].ptr, state[1].ptr

    def close(self):
        if not getattr(self, "_closed", True):
            super().close()
            for a, b in self._partials.values():
                a.close()
                b.close()

    def _launch(self, x, residual, weight, out, residual_out, rows, hidden, eps, gemma_norm, cfg):
        partials, partial_round = self._partial_state(hidden)
        self.mod.launch(
            x.data_ptr(),
            residual.data_ptr(),
            weight.data_ptr(),
            out.data_ptr(),
            residual_out.data_ptr(),
            rows,
            hidden,
            eps,
            gemma_norm,
            self.peers("inbox"),
            self.ptr("round"),
            partials,
            partial_round,
            cfg,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_reduce_rmsnorm", "lamport_1shot_flat")
class OneShotLamportFlat(_OneShotLamport):
    """aiter lamportArRmsFlat: a thread per pack pushes it to every peer and
    polls every slot of its inbox, then the residual + RMSNorm epilogue.
    block = 0: a row per block; 64 / 128 / 256: packs per block (the row's
    blocks exchange sum-of-squares partials). At most 640 KiB."""

    def __init__(self, ctx, max_bytes=None, block: int = 0, hiddens=()):
        if block not in (0, 64, 128, 256):
            raise ValueError(f"block must be 0 (a row), 64, 128 or 256, got {block}")
        self.block = block
        super().__init__(ctx, max_bytes, hiddens)

    def check_input(self, x, rows, hidden):
        super().check_input(x, rows, hidden)
        if self.block:
            self.check_multiple(hidden * x.element_size() // PACK_BYTES, self.block, "hidden packs")

    def launch(self, *args):
        self._launch(*args, self.block)


@register(FAMILY, "all_reduce_rmsnorm", "lamport_1shot_warpsplit")
class OneShotLamportWarpSplit(_OneShotLamport):
    """aiter lamportArRmsWaveSplit: as the lamport one-shot all-reduce (per 64
    positions ngpus waves, wave w talks to one peer), then the epilogue.
    groups: 64-position groups per block (1 / 2 / 4 / 8, world_size * groups
    <= 16). At most 640 KiB."""

    def __init__(self, ctx, max_bytes=None, groups: int = 1, hiddens=()):
        if groups not in (1, 2, 4, 8) or ctx.world_size * groups > 16:
            raise ValueError(f"groups must be 1, 2, 4 or 8 with world_size * groups <= 16, got {groups}")
        self.groups = groups
        super().__init__(ctx, max_bytes, hiddens)

    def check_input(self, x, rows, hidden):
        super().check_input(x, rows, hidden)
        self.check_multiple(hidden * x.element_size() // PACK_BYTES, 64 * self.groups, "hidden packs")

    def launch(self, *args):
        self._launch(*args, self.groups)


@register(FAMILY, "all_reduce_rmsnorm", "lamport_2shot")
class TwoShotLamport(_Lamport):
    """aiter lamportArRmsTwoShot: chunk g of every row is reduced on rank g
    and pushed to every rank's broadcast inbox; every block then folds the
    whole row's sum of squares. split: blocks per row (1 / 2 / 4; None: the
    fewest with at most 512 threads). At most 128 rows."""

    def __init__(self, ctx, max_bytes=None, split: int | None = None):
        if split not in (None, 1, 2, 4):
            raise ValueError(f"split must be None, 1, 2 or 4, got {split}")
        self.split = split
        super().__init__(ctx, max_bytes)

    def _split(self, row_packs: int) -> int:
        return self.split or (2 if row_packs > 512 else 1)

    def check_input(self, x, rows, hidden):
        super().check_input(x, rows, hidden)
        if rows > self.mod.max_rows:
            self.fail(f"{rows} rows, at most {self.mod.max_rows}")
        row_packs = hidden * x.element_size() // PACK_BYTES
        self.check_multiple(row_packs, 32 * self._split(row_packs), "hidden packs")

    def launch(self, x, residual, weight, out, residual_out, rows, hidden, eps, gemma_norm):
        row_packs = hidden * x.element_size() // PACK_BYTES
        self.mod.launch(
            x.data_ptr(),
            residual.data_ptr(),
            weight.data_ptr(),
            out.data_ptr(),
            residual_out.data_ptr(),
            rows,
            hidden,
            eps,
            gemma_norm,
            self.peers("inbox"),
            self.ptr("row_round"),
            self.ptr("row_written"),
            self._split(row_packs),
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )
