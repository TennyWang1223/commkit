"""commkit: communication kernels for AMD GPUs, selected by name.

    import commkit
    ar = commkit.Kernel("all_reduce", "simple_pull_1shot")
    out = ar.run(x)
"""

from . import ops  # noqa: F401  (registers every kernel)
from .arch import arch_family, device_arch
from .kernel import Kernel
from .registry import KERNEL_TYPES, KernelInfo, list_kernels

__all__ = ["Kernel", "KernelInfo", "KERNEL_TYPES", "list_kernels", "device_arch", "arch_family"]
