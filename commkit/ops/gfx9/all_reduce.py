"""gfx9 all_reduce kernels (csrc/gfx9/kernel/all_reduce/)."""

from __future__ import annotations

from ...registry import register
from ..base import HALF, PACK_BYTES, AllReduceOp, PullOp, PushOp

FAMILY = "gfx9"


class _SimplePull(AllReduceOp, PullOp):
    def launch(self, x, out):
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


class _EqualChunks:
    """Two-shot kernels that need every rank's chunk the same size."""

    def check_input(self, x):
        self.check_multiple(x.numel() * x.element_size(), PACK_BYTES * self.world_size, "input bytes")


@register(FAMILY, "all_reduce", "simple_pull_1shot")
class OneShotSimplePull(_SimplePull):
    """aiter cross_device_reduce_1stage: per-peer thread groups pull every
    rank's input into an LDS double buffer, group 0 sums in rank order."""


@register(FAMILY, "all_reduce", "simple_pull_1shot_naive")
class OneShotSimplePullNaive(_SimplePull):
    """aiter cross_device_reduce_1stage_naive (vLLM): each thread sums its
    pack over every rank straight from the peers' memory."""


@register(FAMILY, "all_reduce", "simple_pull_2shot_naive")
class TwoShotSimplePullNaive(_SimplePull):
    """aiter cross_device_reduce_2stage_naive (vLLM): reduce-scatter into the
    owner's tmp, then all-gather from the owners' tmp."""


@register(FAMILY, "all_reduce", "simple_pull_2shot")
class TwoShotSimplePull(_EqualChunks, _SimplePull):
    """aiter cross_device_reduce_2stage: per-peer thread groups pull chunk
    `rank` into LDS for the reduce-scatter, then pull the reduced chunks."""


@register(FAMILY, "all_reduce", "simple_push_2shot")
class TwoShotSimplePush(_EqualChunks, AllReduceOp, PushOp):
    """aiter cross_device_reduce_2stage_write_mode: push the chunks into the
    owners' tmp, the owners push the sums back, each rank copies them out.
    The sums live at a fixed tmp offset (fixes a race of aiter's kernel when
    consecutive calls change size, see the .cuh)."""

    def launch(self, x, out):
        self.mod.launch(
            x.data_ptr(),
            self.peers("signal"),
            self.max_bytes,
            out.data_ptr(),
            x.numel(),
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


class _BlockConfig:
    """Threads per block, fixed for the kernel's lifetime (the per-block
    epochs assume the same block size on every call)."""

    blocks = (256, 512, 1024)

    def __init__(self, ctx, max_bytes=None, block: int = 256):
        if block not in self.blocks:
            raise ValueError(f"{self}: block must be one of {self.blocks}, got {block}")
        self.block = block
        super().__init__(ctx, max_bytes)


@register(FAMILY, "all_reduce", "ll_1shot")
class OneShotLL(_BlockConfig, AllReduceOp, PushOp):
    """aiter ar_ll_gfx9: every rank pushes its input as LL lines (8B data +
    flags in 16B) into every peer's FIFO and polls its own; no barrier.
    Capacity max_bytes (default 128 KiB, the FIFO grows 4 * world_size * it)."""

    default_max_bytes = 128 << 10

    def launch(self, x, out):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            x.numel(),
            self.peers("fifo"),
            self.ptr("epoch"),
            self.max_bytes,
            self.block,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_reduce", "ll128_1shot")
class OneShotLL128(_BlockConfig, AllReduceOp, PushOp):
    """aiter ar_ll128_unroll2: 8-lane groups push 240 bytes as two 128-byte
    lines with in-line flags into every peer's FIFO; no barrier. fp16 / bf16,
    at most 4 MiB (fixed FIFO layout)."""

    dtypes = HALF

    def launch(self, x, out):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            x.numel(),
            self.peers("fifo"),
            self.ptr("epoch"),
            self.block,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


class _Lamport(AllReduceOp, PushOp):
    dtypes = HALF

    def launch(self, x, out):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            x.numel(),
            self.peers("inbox"),
            self.ptr("round"),
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_reduce", "lamport_1shot_warpsplit")
class OneShotLamportWarpSplit(_Lamport):
    """aiter lamportAllReduceWaveSplit: per 64 positions a block of ngpus
    waves, wave w pushes into and polls rank (rank + w) % ngpus only; the
    sentinel-armed inbox is the signal, no barrier. fp16 / bf16, at most
    640 KiB."""


@register(FAMILY, "all_reduce", "lamport_2shot_warpsplit")
class TwoShotLamportWarpSplit(_EqualChunks, _Lamport):
    """aiter lamportAllReduceTwoShotWaveSplit: pushed reduce-scatter, then the
    sums pushed to every rank, wave split as the one-shot. fp16 / bf16, at
    most 2 MiB, whole packs per rank."""
