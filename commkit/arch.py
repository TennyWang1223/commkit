"""Which kernel tree (csrc/<family>/) serves the GPU this process runs on."""

from __future__ import annotations

import os

import torch

# offload arch -> kernel family directory under csrc/ and commkit/ops/
ARCH_FAMILY = {
    "gfx942": "gfx9",
    "gfx950": "gfx9",
    "gfx1250": "gfx1250",
}


def device_arch(device: int | torch.device | None = None) -> str:
    """Offload arch of the device, e.g. 'gfx942'. COMMKIT_ARCH overrides it."""
    forced = os.environ.get("COMMKIT_ARCH")
    if forced:
        return forced
    if device is None:
        device = torch.cuda.current_device()
    return torch.cuda.get_device_properties(device).gcnArchName.split(":")[0]


def arch_family(arch: str) -> str:
    try:
        return ARCH_FAMILY[arch]
    except KeyError:
        raise RuntimeError(
            f"commkit has no kernels for {arch}; supported: {sorted(ARCH_FAMILY)}"
        ) from None
