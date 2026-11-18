"""Per-process-group state shared by the kernels created on that group."""

from __future__ import annotations

import pickle

import torch
import torch.distributed as dist
from torch.distributed import distributed_c10d as c10d

from . import jit
from .arch import arch_family, device_arch


class Context:
    """Rank, world size, device and arch of one process group, plus the two
    collectives the kernels need at construction: exchanging IPC handles and
    a barrier.

    Both go through the process group's key-value store (the TCPStore
    init_process_group set up), never through a collective of the group, so
    commkit never calls RCCL / NCCL whatever backend the group uses.
    """

    _cache: dict = {}

    @classmethod
    def get(cls, group=None) -> "Context":
        if not dist.is_initialized():
            raise RuntimeError(
                "commkit: initialize torch.distributed (dist.init_process_group) before creating kernels"
            )
        group = dist.group.WORLD if group is None else group
        ctx = cls._cache.get(group)
        if ctx is None:
            ctx = cls._cache[group] = cls(group)
        return ctx

    def __init__(self, group):
        self.group = group
        self.rank = dist.get_rank(group)
        self.world_size = dist.get_world_size(group)
        self.device = torch.device("cuda", torch.cuda.current_device())
        self.arch = device_arch(self.device.index)
        self.family = arch_family(self.arch)
        self.rt = jit.runtime(self.arch)
        self._store = c10d._get_default_store()
        # keys are namespaced by the group's global ranks and a counter that
        # advances on every exchange, the same on every rank (collective order)
        self._tag = "-".join(str(r) for r in dist.get_process_group_ranks(group))
        self._seq = 0

    def all_gather_object(self, obj) -> list:
        self._seq += 1
        prefix = f"commkit/{self._tag}/{self._seq}/"
        self._store.set(prefix + str(self.rank), pickle.dumps(obj))
        # get() blocks until the rank has set its key
        return [pickle.loads(self._store.get(prefix + str(r))) for r in range(self.world_size)]

    def barrier(self) -> None:
        self.all_gather_object(None)

    def check_same(self, what: str, value) -> None:
        """Raises on every rank if `value` differs between ranks, instead of
        letting a mismatched collective hang."""
        values = self.all_gather_object(value)
        if any(v != values[0] for v in values):
            detail = "\n".join(f"  rank {r}: {v}" for r, v in enumerate(values))
            raise RuntimeError(f"commkit: {what} differs across ranks\n{detail}")
