"""gfx1250 all_reduce + residual + RMSNorm kernels
(csrc/gfx1250/kernel/all_reduce_rmsnorm/)."""

from __future__ import annotations

from ...registry import register
from ..base import HALF, PACK_BYTES, AllReduceRmsnormOp, MiB, PullOp, PushOp
from ._common import check_aligned, check_lamport_bytes

FAMILY = "gfx1250"


class _SimplePull(AllReduceRmsnormOp, PullOp):
    """fp16 / bf16 (aiter's gfx1250 fused kernels), a row one block: hidden
    at most 1024 packs."""

    dtypes = HALF

    def check_input(self, x, rows, hidden):
        packs = hidden * x.element_size() // PACK_BYTES
        if packs > 1024:
            self.fail(f"hidden {hidden} is {packs} packs, at most 1024 (a row is one block)")

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
    """aiter ar_rmsnorm_gfx1250 (one-stage, no quantization): a block per row
    pulls the row from every rank's staged input, rounds the rank-order sum,
    adds the residual and normalizes (wave32 butterflies, then the wave
    partials in order), between a start and an end barrier."""


@register(FAMILY, "all_reduce_rmsnorm", "simple_pull_2shot")
class TwoShotSimplePull(_SimplePull):
    """aiter ar_rmsnorm_reduce_scatter_gfx1250 + ar_rmsnorm_gfx1250<TWO_STAGE>
    as one launch sequence: rank r reduces shard r of every row into its tmp,
    then every rank normalizes every row from the owners' shards, the launches
    ordered by single-block barriers. hidden / pack a multiple of the world
    size. aiter takes it at TP4+ for hidden >= 6144 above 4 MiB, where it
    halves the peer traffic of the one-shot."""

    def check_input(self, x, rows, hidden):
        super().check_input(x, rows, hidden)
        self.check_multiple(hidden * x.element_size() // PACK_BYTES, self.world_size, "hidden packs")


@register(FAMILY, "all_reduce_rmsnorm", "lamport_1shot")
class OneShotLamport(AllReduceRmsnormOp, PushOp):
    """aiter lamport_ar_rmsnorm_gfx1250: a thread a pack pushes it into slot
    `rank` of every peer's inbox and polls its own until no half-word is the
    0xffff sentinel (no barrier, no copy-in), then the epilogue of
    simple_pull_1shot step by step: out and residual_out match it bit for bit.
    fp16 / bf16, hidden a multiple of 256 up to 8192, 16-byte aligned
    operands. Inbox 3 x world_size x max_bytes a rank (cached); max_bytes, a
    multiple of 512, default 8 MiB (aiter's TP4 cap).

    cluster: True (aiter's choice per call) splits a row over a workgroup
    cluster of up to 16 blocks while the rows leave CUs idle and a row is
    wider than 256 packs, else a block a row; False always takes a block a
    row. A build without cluster launch (ROCm <= 7.2, mod.cluster_launch
    False) always takes a block a row."""

    dtypes = HALF
    default_max_bytes = 8 * MiB

    def __init__(self, ctx, max_bytes=None, cluster: bool = True):
        check_lamport_bytes(self, max_bytes)
        if not isinstance(cluster, bool):
            raise ValueError(f"{self}: cluster must be True or False, got {cluster!r}")
        self.cluster = cluster
        super().__init__(ctx, max_bytes)

    def check_input(self, x, rows, hidden):
        if hidden % 256 or hidden > 8192:
            self.fail(f"hidden {hidden} must be a multiple of 256, at most 8192")
        check_aligned(self, x, "input")

    def launch(self, x, residual, weight, out, residual_out, rows, hidden, eps, gemma_norm):
        for t, what in ((residual, "residual"), (weight, "weight"), (out, "out"), (residual_out, "residual_out")):
            check_aligned(self, t, what)
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
            self.ptr("cluster_partials"),
            self.max_bytes,
            self.cluster,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )
