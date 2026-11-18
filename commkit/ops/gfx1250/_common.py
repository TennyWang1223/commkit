"""Argument checks shared by the gfx1250 op classes."""

from __future__ import annotations

import torch

from ..base import nbytes_of

INT32_MAX = (1 << 31) - 1
# lamport inboxes and round counters are per wave of 32 16-byte packs
LAMPORT_GRAIN = 32 * 16


def choice(op, what: str, value, allowed: tuple):
    """A launch-config kwarg: None (aiter's choice per call) or one of allowed."""
    if value is not None and value not in allowed:
        raise ValueError(f"{op}: {what} must be None or one of {allowed}, got {value!r}")
    return value


def check_lamport_bytes(op, max_bytes) -> None:
    """A lamport inbox holds whole waves of packs, indexed with int32 (the
    largest index is kLamportBuffers x 8 ranks x the slot)."""
    if max_bytes is None:
        return
    if max_bytes <= 0 or max_bytes % LAMPORT_GRAIN:
        raise ValueError(f"{op}: max_bytes must be a positive multiple of {LAMPORT_GRAIN}, got {max_bytes}")
    if max_bytes // 16 > INT32_MAX // (3 * 8):
        raise ValueError(f"{op}: max_bytes {max_bytes} is past the int32 range of the inbox")


def check_int32(op, value: int, what: str) -> None:
    """The simple kernels index with int32."""
    if value > INT32_MAX:
        op.fail(f"{what} ({value}) is past the int32 range the kernel indexes with")


def check_aligned(op, t: torch.Tensor, what: str, align: int = 16) -> None:
    """The lamport kernels move their operands in whole 16-byte packs."""
    if t.data_ptr() % align:
        op.fail(f"{what} must be {align}-byte aligned (the kernel moves whole {align}-byte packs)")


def check_gather_in_place(op, x: torch.Tensor, out: torch.Tensor, kind: str) -> None:
    """The push all-gathers read the input while they write the output: the
    input lies clear of the output, or is this rank's own slice of a
    first-dim gather (rewritten with the same bytes)."""
    n, lo, olo = nbytes_of(x), x.data_ptr(), out.data_ptr()
    if olo >= lo + n or lo >= olo + n * op.world_size:
        return
    if kind == "first" and lo == olo + n * op.rank:
        return
    op.fail("the input overlaps the output other than as this rank's slice of a first-dim gather")
