"""gfx1250 all_gather kernels (csrc/gfx1250/kernel/all_gather/)."""

from __future__ import annotations

from ...registry import register
from ..base import HALF, PACK_BYTES, AllGatherOp, MiB, PullOp, PushOp, nbytes_of
from ._common import check_aligned, check_gather_in_place, check_int32, check_lamport_bytes, choice

FAMILY = "gfx1250"


def _row_bytes(x, kind: str) -> int:
    """Bytes of a gathered row: the whole input along the first dim."""
    return nbytes_of(x) if kind == "first" else x.shape[-1] * x.element_size()


@register(FAMILY, "all_gather", "simple_pull")
class SimplePull(AllGatherOp, PullOp):
    """aiter ag_gfx1250_naive_unroll4 (first dim) / ag_gfx1250_lastdim (last
    dim): every thread copies 4 packs a round of every rank's staged input,
    read in place, starting with its own rank's. First dim: whole tiles of
    1024 packs (16 KiB; the unroll-4 loop skips a partial tile, aiter routes
    other sizes to simple_pull_vec). Last dim: whole packs a row."""

    def check_input(self, x, kind):
        if kind == "first":
            self.check_multiple(nbytes_of(x), PACK_BYTES * 1024, "input bytes")
        else:
            self.check_multiple(x.shape[-1] * x.element_size(), PACK_BYTES, "last dim bytes")
        check_int32(self, nbytes_of(x) // PACK_BYTES * self.world_size, "output packs")

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


@register(FAMILY, "all_gather", "simple_pull_vec")
class SimplePullVec(AllGatherOp, PullOp):
    """aiter ag_gfx1250_naive_vec: first dim, a pack a thread a round of every
    rank's staged input, read in place; any whole number of packs."""

    dims = ("first",)

    def check_input(self, x, kind):
        self.check_multiple(nbytes_of(x), PACK_BYTES, "input bytes")
        check_int32(self, nbytes_of(x) // PACK_BYTES * self.world_size, "output packs")

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


@register(FAMILY, "all_gather", "simple_pull_naive")
class SimplePullNaive(AllGatherOp, PullOp):
    """aiter ag_gfx1250_scalar: first dim, element by element, any size."""

    dims = ("first",)

    def check_input(self, x, kind):
        check_int32(self, x.numel() * self.world_size, "output elements")

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


@register(FAMILY, "all_gather", "ll")
class LL(AllGatherOp, PushOp):
    """aiter ag_ll_gfx1250: every rank pushes its input as LL lines (12 bytes
    and an epoch word in 16) into slot `rank` of every peer's FIFO, writes its
    own slice, and polls its own FIFO for the peers'; no barrier. Whole 8-byte
    packets, a row's too along the last dim; at most 4 MiB a rank (fixed FIFO,
    16 MiB x world_size a rank). The input is read in place: it lies clear of
    the output, or is this rank's slice of a first-dim gather.

    block: threads a block, 256 or 512 (None: aiter's choice per call, 256
    while 512 blocks cover the message, else 512). unroll: 12-byte units a
    thread takes a round, 1 or 2 (None: aiter's choice per call, 2 once 512
    full blocks do not cover the message)."""

    def __init__(self, ctx, max_bytes=None, block: int | None = None, unroll: int | None = None):
        self.block = choice(self, "block", block, (256, 512))
        self.unroll = choice(self, "unroll", unroll, (1, 2))
        super().__init__(ctx, max_bytes)

    def check_input(self, x, kind):
        self.check_multiple(nbytes_of(x), 8, "input bytes")
        if kind == "last":
            self.check_multiple(_row_bytes(x, kind), 8, "last dim bytes")

    def launch(self, x, out, kind):
        check_gather_in_place(self, x, out, kind)
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            nbytes_of(x),
            _row_bytes(x, kind),
            self.peers("fifo"),
            self.ptr("epoch"),
            self.block or 0,
            self.unroll or 0,
            self.rank,
            self.world_size,
            self.stream(),
        )


class _Lamport(AllGatherOp, PushOp):
    """aiter lamport_ag_gfx1250: a thread a pack pushes it into slot `rank` of
    every peer's inbox, writes its own slice, and polls its own inbox for the
    peers'; the data is its own signal, no barrier. Whole 16-byte packs, a
    row's too along the last dim; 16-byte aligned input and output, the input
    clear of the output or this rank's slice of a first-dim gather. Inbox 3 x
    world_size x max_bytes a rank (cached); max_bytes, the largest input a
    rank, a multiple of 512, default 8 MiB (aiter's TP4 cap).

    block: threads a block, 64 / 256 / 512 (None: aiter's choice per call by
    size, 64 up to 2048 packs, 256 up to 192 Ki, else 512)."""

    default_max_bytes = 8 * MiB

    def __init__(self, ctx, max_bytes=None, block: int | None = None):
        check_lamport_bytes(self, max_bytes)
        self.block = choice(self, "block", block, (64, 256, 512))
        super().__init__(ctx, max_bytes)

    def check_input(self, x, kind):
        self.check_multiple(nbytes_of(x), PACK_BYTES, "input bytes")
        if kind == "last":
            self.check_multiple(_row_bytes(x, kind), PACK_BYTES, "last dim bytes")
        check_aligned(self, x, "input")

    def launch(self, x, out, kind):
        check_aligned(self, out, "out")
        check_gather_in_place(self, x, out, kind)
        self._launch(x, out, kind)

    def _launch(self, x, out, kind):
        raise NotImplementedError


@register(FAMILY, "all_gather", "lamport")
class Lamport(_Lamport):
    """The fp16 / bf16 codec of the lamport all-gather (aiter
    LamportAgHalfSentinel): the 0xffff half-word sentinel of the other
    lamport kernels, so bit for bit except that a 0xffff half-word (a NaN)
    comes out 0x7fff (also NaN) on every rank. lamport_escape is exact
    for any dtype."""

    dtypes = HALF

    def _launch(self, x, out, kind):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            nbytes_of(x),
            _row_bytes(x, kind),
            self.peers("inbox"),
            self.ptr("round"),
            self.max_bytes,
            self.block or 0,
            self.rank,
            self.world_size,
            self.stream(),
        )


@register(FAMILY, "all_gather", "lamport_escape")
class LamportEscape(_Lamport):
    """The exact codec of the lamport all-gather (aiter LamportAgEscape, which
    aiter takes for every dtype but fp16 / bf16): words go as is, an
    all-ones word is also flagged in an escape inbox (a uint32 a pack, 3 x
    world_size x max_bytes / 4 more a rank, armed with 0). Bit for bit, any
    dtype."""

    def _launch(self, x, out, kind):
        self.mod.launch(
            x.data_ptr(),
            out.data_ptr(),
            nbytes_of(x),
            _row_bytes(x, kind),
            self.peers("inbox"),
            self.peers("escape"),
            self.ptr("round"),
            self.max_bytes,
            self.block or 0,
            self.rank,
            self.world_size,
            self.stream(),
        )
