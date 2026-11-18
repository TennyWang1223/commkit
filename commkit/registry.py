"""Kernel registry: (arch family, kernel type, kernel name) -> op class.

A kernel's source is csrc/<family>/kernel/<type>/<mode>/<name>.{cuh,cu}; the
mode (the folder, and the op's base class PullOp / PushOp) is
  pull   peers read this rank's input in place, so run() first copies the
         input into the op's IPC staging buffer (one D2D copy)
  push   this rank writes its data into the peers' buffers; no input copy
Names are unique within a kernel type of one family. LL, LL128 and lamport
always push, so their names carry no mode: <proto>[_<1shot|2shot>][_<variant>].
simple has both modes, so its names do: simple_<pull|push>[_<1shot|2shot>][_<variant>].
"""

from __future__ import annotations

from dataclasses import dataclass, field

KERNEL_TYPES = ("all_reduce", "all_gather", "reduce_scatter", "all_reduce_rmsnorm")
PROTOS = ("simple", "ll", "ll128", "lamport")
MODES = ("pull", "push")


@dataclass(frozen=True)
class KernelInfo:
    family: str
    kernel_type: str
    name: str
    proto: str
    mode: str
    cls: type = field(repr=False, compare=False)


_KERNELS: dict[tuple[str, str, str], KernelInfo] = {}


def register(family: str, kernel_type: str, name: str):
    """Registers an op class. The proto is the name's first word, the mode
    the class's (PullOp / PushOp); simple names also spell the mode."""
    if kernel_type not in KERNEL_TYPES:
        raise ValueError(f"unknown kernel type {kernel_type!r}, expected one of {KERNEL_TYPES}")
    proto = name.split("_", 1)[0]
    if proto not in PROTOS:
        raise ValueError(f"{kernel_type}/{name}: the name must start with a proto, one of {PROTOS}")

    def deco(cls):
        key = (family, kernel_type, name)
        if key in _KERNELS:
            raise ValueError(f"kernel {key} registered twice")
        mode = getattr(cls, "mode", None)
        if mode not in MODES:
            raise ValueError(f"{kernel_type}/{name}: the class must derive from PullOp or PushOp")
        if proto == "simple" and not name.startswith(f"simple_{mode}"):
            raise ValueError(f"{kernel_type}/{name}: a simple {mode} kernel is named simple_{mode}...")
        cls.family, cls.kernel_type, cls.name, cls.proto = family, kernel_type, name, proto
        _KERNELS[key] = KernelInfo(family, kernel_type, name, proto, mode, cls)
        return cls

    return deco


def lookup(family: str, kernel_type: str, name: str) -> type:
    info = _KERNELS.get((family, kernel_type, name))
    if info is None:
        known = sorted(k.name for k in list_kernels(kernel_type, family=family))
        raise KeyError(
            f"no {kernel_type!r} kernel named {name!r} for {family}; available: {known}"
        )
    return info.cls


def _current_family() -> str | None:
    try:
        import torch

        if torch.cuda.is_available():
            from .arch import arch_family, device_arch

            return arch_family(device_arch())
    except Exception:  # noqa: BLE001 - no GPU: list every family
        pass
    return None


def list_kernels(
    kernel_type: str | None = None,
    *,
    family: str | None = None,
    proto: str | None = None,
    mode: str | None = None,
) -> list[KernelInfo]:
    """Registered kernels, by default those of this GPU's arch family
    (family="all" lists every family)."""
    if family is None:
        family = _current_family()
    if family == "all":
        family = None
    return [
        k
        for k in _KERNELS.values()
        if (family is None or k.family == family)
        and (kernel_type is None or k.kernel_type == kernel_type)
        and (proto is None or k.proto == proto)
        and (mode is None or k.mode == mode)
    ]
