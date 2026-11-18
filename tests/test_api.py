"""The Python layer: registry, Kernel construction checks, argument checks,
input_buffer(), close().

How to run:
    python tests/test_api.py          # or: python -m pytest tests/test_api.py
Checks: every registered kernel follows the naming rule and has its source at
csrc/<family>/kernel/<type>/<mode>/<name>.cu; on 2 GPUs, Kernel() raises on an
unknown name and on arguments that differ between ranks (instead of hanging),
run() rejects bad sizes / dtypes / layouts, input_buffer() is zero-copy,
close() can be called twice.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest
import torch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the repo root, for `import commkit`
import commkit  # noqa: E402
from commkit import jit  # noqa: E402
from commkit.registry import KERNEL_TYPES, MODES, PROTOS  # noqa: E402
from utils import init_dist, launch  # noqa: E402

NAME = re.compile(r"^(simple_(pull|push)|ll|ll128|lamport)(_(1shot|2shot))?(_[a-z0-9]+)*$")


def test_registry():
    kernels = commkit.list_kernels(family="all")
    assert kernels, "no kernel registered"
    for k in kernels:
        assert k.kernel_type in KERNEL_TYPES and k.proto in PROTOS and k.mode in MODES
        assert NAME.match(k.name), f"{k.kernel_type}/{k.name} breaks the naming rule"
        assert k.name.split("_")[0] == k.proto, f"{k.name}: proto disagrees with the name"
        if k.proto == "simple":
            assert k.name.startswith(f"simple_{k.mode}"), f"{k.name}: a simple kernel spells its mode"
        else:
            assert k.mode == "push", f"{k.name}: LL / LL128 / lamport kernels push"
        src = jit.kernel_source(k.family, k.kernel_type, k.mode, k.name)
        assert src.is_file() and src.with_suffix(".cuh").is_file(), f"{k.name}: no {src}(h)"
    # every kernel type has kernels on this arch
    here = commkit.list_kernels()
    assert {k.kernel_type for k in here} == set(KERNEL_TYPES)


def _api_worker(rank: int, world_size: int, port: int):
    init_dist(rank, world_size, port)
    problems = []

    def expect(exc, fn, what):
        try:
            fn()
        except exc:
            return
        except Exception as err:  # noqa: BLE001
            problems.append(f"{what}: raised {type(err).__name__}: {err}")
            return
        problems.append(f"{what}: did not raise {exc.__name__}")

    expect(KeyError, lambda: commkit.Kernel("all_reduce", "no_such_kernel"), "unknown name")
    # different arguments on different ranks: raise everywhere instead of hanging
    expect(RuntimeError, lambda: commkit.Kernel("all_reduce", "simple_pull_1shot", max_bytes=(rank + 1) << 20),
           "mismatched constructor arguments")

    k = commkit.Kernel("all_reduce", "simple_pull_1shot", max_bytes=1 << 20)
    x = torch.ones(1024, dtype=torch.bfloat16, device="cuda")
    expect(ValueError, lambda: k.run(torch.ones(1 << 20, dtype=torch.bfloat16, device="cuda")), "over capacity")
    expect(ValueError, lambda: k.run(torch.ones(1001, dtype=torch.bfloat16, device="cuda")), "not whole packs")
    expect(TypeError, lambda: k.run(x.to(torch.int32)), "unsupported dtype")
    expect(ValueError, lambda: k.run(torch.ones(64, 64, dtype=torch.bfloat16, device="cuda").t()), "non-contiguous")
    expect(ValueError, lambda: k.run(x, out=torch.empty(8, dtype=torch.bfloat16, device="cuda")), "bad out shape")

    # input_buffer: written in place, read by the peers without a copy
    xb = k.input_buffer((1024,), torch.bfloat16)
    if xb.data_ptr() != k.staging.ptr:
        problems.append("input_buffer() is not the staging buffer")
    xb.fill_(1.0)
    out = k.run(xb)
    if not torch.equal(out, torch.full_like(out, world_size)):
        problems.append("zero-copy all-reduce of ones is not world_size")
    expect(ValueError, lambda: k.run(xb[8:]), "input inside the staging buffer at an offset")
    expect(ValueError, lambda: k.input_buffer((1 << 20,), torch.bfloat16), "input_buffer over capacity")
    k.close()
    k.close()  # a second close is a no-op

    # push kernels have no staging buffer
    p = commkit.Kernel("all_reduce", "ll_1shot")
    if p.mode != "push" or hasattr(p.op, "staging"):
        problems.append("ll_1shot should be a push kernel without staging")
    p.close()

    if problems:
        raise AssertionError("\n".join(problems))
    return True


@pytest.mark.skipif(torch.cuda.device_count() < 2, reason="needs 2 GPUs")
def test_api():
    launch(_api_worker, 2)


if __name__ == "__main__":
    test_registry()
    test_api()
    print("api tests passed")
