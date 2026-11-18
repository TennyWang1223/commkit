"""gfx1250 all_reduce kernels (csrc/gfx1250/kernel/all_reduce/)."""

from __future__ import annotations

from ...registry import register
from ..base import HALF, MiB, AllReduceOp, PullOp, PushOp, nbytes_of
from ._common import check_aligned, check_lamport_bytes, choice

FAMILY = "gfx1250"


@register(FAMILY, "all_reduce", "simple_pull_1shot")
class OneShotSimplePull(AllReduceOp, PullOp):
    """aiter ar_gfx1250_naive_unroll4: every thread sums 4 packs a round of
    every rank's staged input, read in place, in rank order; 256-thread blocks
    between a start and an end barrier. Every rank reduces the whole message."""

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


@register(FAMILY, "all_reduce", "ll_1shot")
class OneShotLL(AllReduceOp, PushOp):
    """aiter ar_ll_gfx1250: every rank pushes its input as LL lines (8 bytes
    and two epoch flags in 16) into slot `rank` of every rank's FIFO, its own
    included, and polls its own FIFO; no barrier. Half of a block sends, half
    polls. At most 4 MiB (fixed FIFO, 16 MiB x world_size a rank).

    block: threads a block, 512 or 1024 (None: aiter's choice per call, 512
    while one block a CU covers the message, else 1024). unroll: packets a
    sender takes a round, 1 / 2 / 4 (None: aiter's choice per call, the fewest
    that keep the grid within one block a CU)."""

    def __init__(self, ctx, max_bytes=None, block: int | None = None, unroll: int | None = None):
        self.block = choice(self, "block", block, (512, 1024))
        self.unroll = choice(self, "unroll", unroll, (1, 2, 4))
        super().__init__(ctx, max_bytes)

    def launch(self, x, out):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            x.numel(),
            self.peers("fifo"),
            self.ptr("epoch"),
            self.block or 0,
            self.unroll or 0,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_reduce", "ll_2shot")
class TwoShotLL(AllReduceOp, PushOp):
    """aiter ar_2s_ll_gfx1250: a reduce-scatter and an all-gather over LL
    lines; rank c reduces chunk c, in wave groups that send, reduce (and send
    the sums) and gather. 4 or 8 ranks, at most 8 MiB (fixed FIFO, 64 MiB a
    rank), the bytes a multiple of 8 x world_size (whole packets a chunk).
    aiter takes it over from the one-shot at 1 MiB (TP4) / 512 KiB (TP8).

    roles: wave groups a block, 2 or 3 (None: aiter's choice per call, 3 while
    one block of 3 x 128 threads a CU covers a chunk, else 2). width: threads
    a group, a multiple of 64 with roles x width <= 1024 (None: aiter's choice
    per call, the fewest packets on the busiest CU)."""

    world_sizes = (4, 8)

    def __init__(self, ctx, max_bytes=None, roles: int | None = None, width: int | None = None):
        self.roles = choice(self, "roles", roles, (2, 3))
        if width is not None:
            most = 1024 // (self.roles or 3) // 64 * 64
            if not isinstance(width, int) or width <= 0 or width % 64 or width > most:
                raise ValueError(f"{self}: width must be None or a multiple of 64 up to {most}, got {width!r}")
        self.width = width
        super().__init__(ctx, max_bytes)

    def check_input(self, x):
        self.check_multiple(nbytes_of(x), 8 * self.world_size, "input bytes")

    def launch(self, x, out):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            x.numel(),
            self.peers("fifo"),
            self.ptr("epoch"),
            self.roles or 0,
            self.width or 0,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


class _Lamport(AllReduceOp, PushOp):
    """fp16 / bf16, 16-byte aligned operands. max_bytes: the largest call, a
    multiple of 512. block: threads a block, 64 / 256 / 512 (None: aiter's
    choice per call by size, 64 up to 2048 packs, 256 up to 192 Ki, else
    512)."""

    dtypes = HALF

    def __init__(self, ctx, max_bytes=None, block: int | None = None):
        check_lamport_bytes(self, max_bytes)
        self.block = choice(self, "block", block, (64, 256, 512))
        super().__init__(ctx, max_bytes)

    def check_input(self, x):
        check_aligned(self, x, "input")

    def launch(self, x, out):
        check_aligned(self, out, "out")
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            x.numel(),
            self.peers("inbox"),
            self.ptr("round"),
            self.max_bytes,
            self.block or 0,
            self.rank,
            self.world_size,
            self.dtype_code(x),
            self.stream(),
        )


@register(FAMILY, "all_reduce", "lamport_1shot")
class OneShotLamport(_Lamport):
    """aiter lamport_ar_1shot_gfx1250 (the plain all-reduce, not its input +
    other form): a thread a pack pushes it into slot `rank` of every peer's
    inbox and polls its own until no half-word is the 0xffff sentinel; the
    data is its own signal, no barrier. Inbox 3 x world_size x max_bytes a
    rank (cached), default max_bytes 8 MiB (aiter's TP4 cap; its one-shot
    leads the two-shot up to 1.25 MiB at TP4, 9 MiB at TP2)."""

    default_max_bytes = 8 * MiB


@register(FAMILY, "all_reduce", "lamport_2shot")
class TwoShotLamport(_Lamport):
    """aiter lamport_ar_2shot_gfx1250: a pushed reduce-scatter (a round of the
    data inbox) then a pushed all-gather (an inbox of its own, re-armed as it
    is read); a thread a pack of every chunk. Inbox about 4 x max_bytes a rank
    (cached), default max_bytes 32 MiB (aiter's two-shot cap at TP2 and TP4,
    world_size x the one-shot's)."""

    default_max_bytes = 32 * MiB
