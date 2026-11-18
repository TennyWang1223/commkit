"""Minimal JIT for commkit's HIP modules.

Each kernel is its own module, built from one launch file
(``csrc/<family>/kernel/<type>/<mode>/<name>.cu``) into
``build/jit/<arch>/<module>/<module>.so`` the first time a process loads it.

ninja tracks every included header through depfiles, so editing a .cuh /
.hpp rebuilds exactly the modules that include it on their next load; there is
no .so to delete by hand. A file lock serializes the ranks of one job: the
first one builds, the others then find nothing to do.

Prebuild from the command line (parallel across modules)::

    python -m commkit                          # every kernel of this GPU's arch
    python -m commkit --arch gfx942 all_reduce/simple_pull_1shot
"""

from __future__ import annotations

import argparse
import fcntl
import importlib.util
import os
import shutil
import subprocess
import sys
import sysconfig
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSRC = ROOT / "csrc"
ROCM_PATH = Path(os.environ.get("ROCM_PATH", "/opt/rocm"))
HIPCC = os.environ.get("COMMKIT_HIPCC", str(ROCM_PATH / "bin" / "hipcc"))
JIT_DIR = Path(os.environ.get("COMMKIT_JIT_DIR", ROOT / "build" / "jit"))

# Same code generation as aiter's JIT, so the ported kernels compile to the
# same ISA. OPUS_FP32_to_BF16_DEFAULT=5 is the round-to-nearest-even fp32 ->
# bf16 that aiter sets for its custom all-reduce; opus defaults to truncation.
HIP_FLAGS = [
    "-O3",
    "-std=c++20",
    "-fPIC",
    "-D__HIP_PLATFORM_AMD__=1",
    "-U__HIP_NO_HALF_CONVERSIONS__",
    "-U__HIP_NO_HALF_OPERATORS__",
    "-DOPUS_FP32_to_BF16_DEFAULT=5",
    "-fgpu-flush-denormals-to-zero",
    "-fno-offload-uniform-block",
    "-mllvm --amdgpu-kernarg-preload-count=32",
    "-mllvm --lsr-drop-solution=1",
    "-mllvm -enable-post-misched=0",
    "-mllvm -amdgpu-early-inline-all=true",
    "-mllvm -amdgpu-function-calls=false",
    "-mllvm -amdgpu-coerce-illegal-types=1",
    "-Wno-unused-result",
    "-Wno-switch-bool",
    "-Wno-vla-cxx-extension",
    "-Wno-undefined-func-template",
    "-Wno-macro-redefined",
    "-Wno-missing-template-arg-list-after-template-kw",
]

_loaded: dict[tuple[str, str], object] = {}


def _ninja() -> str:
    exe = shutil.which("ninja")
    if exe is None:
        try:
            import ninja  # type: ignore

            exe = str(Path(ninja.BIN_DIR) / "ninja")
        except ImportError as err:
            raise RuntimeError("commkit JIT needs ninja: pip install ninja") from err
    return exe


def _includes() -> list[str]:
    import pybind11

    return [
        f"-I{CSRC / 'include'}",
        f"-I{CSRC}",
        f"-I{pybind11.get_include()}",
        f"-I{sysconfig.get_paths()['include']}",
    ]


def _manifest(module: str, sources: list[Path], arch: str, extra_flags: list[str]) -> str:
    flags = HIP_FLAGS + [f"--offload-arch={arch}", f"-DCOMMKIT_MODULE_NAME={module}"]
    flags += _includes() + list(extra_flags)
    lines = [
        "ninja_required_version = 1.3",
        f"cxx = {HIPCC}",
        f"cflags = {' '.join(flags)}",
        "",
        "rule compile",
        "  command = $cxx -c $in -o $out $cflags -MD -MF $out.d",
        "  depfile = $out.d",
        "  deps = gcc",
        "  description = HIPCC $out",
        "",
        "rule link",
        "  command = $cxx -shared $in -o $out",
        "  description = LINK $out",
        "",
    ]
    objs = []
    for src in sources:
        obj = f"{src.stem}.o"
        objs.append(obj)
        lines.append(f"build {obj}: compile {src}")
    lines.append(f"build {module}.so: link {' '.join(objs)}")
    lines.append(f"default {module}.so")
    return "\n".join(lines) + "\n"


def build(module: str, sources: list[Path], arch: str, extra_flags: list[str] = ()) -> Path:
    """Brings build/jit/<arch>/<module>/<module>.so up to date; returns its path."""
    for src in sources:
        if not src.is_file():
            raise FileNotFoundError(f"commkit JIT: no source {src}")
    bdir = JIT_DIR / arch / module
    bdir.mkdir(parents=True, exist_ok=True)
    manifest = _manifest(module, sources, arch, list(extra_flags))
    with open(bdir / ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            ninja_file = bdir / "build.ninja"
            if not ninja_file.exists() or ninja_file.read_text() != manifest:
                ninja_file.write_text(manifest)
            start = time.perf_counter()
            res = subprocess.run([_ninja(), "-C", str(bdir)], capture_output=True, text=True)
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)
    if res.returncode != 0:
        raise RuntimeError(
            f"commkit JIT: building {module} for {arch} failed\n{res.stdout[-12000:]}{res.stderr[-4000:]}"
        )
    if "no work to do" not in res.stdout:
        print(f"[commkit] built {module} ({arch}) in {time.perf_counter() - start:.1f}s", flush=True)
    return bdir / f"{module}.so"


def load(module: str, sources: list[Path], arch: str, extra_flags: list[str] = ()):
    """Builds (if needed) and imports a module, once per process."""
    key = (module, arch)
    if key not in _loaded:
        so = build(module, sources, arch, extra_flags)
        spec = importlib.util.spec_from_file_location(module, so)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _loaded[key] = mod
    return _loaded[key]


def kernel_module_name(family: str, kernel_type: str, name: str) -> str:
    return f"ck_{family}_{kernel_type}_{name}"


def kernel_source(family: str, kernel_type: str, mode: str, name: str) -> Path:
    return CSRC / family / "kernel" / kernel_type / mode / f"{name}.cu"


def load_kernel(family: str, arch: str, kernel_type: str, mode: str, name: str):
    return load(
        kernel_module_name(family, kernel_type, name),
        [kernel_source(family, kernel_type, mode, name)],
        arch,
    )


def runtime(arch: str):
    return load("ck_runtime", [CSRC / "runtime" / "runtime.cu"], arch)


def _main() -> None:
    from .arch import arch_family, device_arch
    from .registry import list_kernels, lookup

    parser = argparse.ArgumentParser(description="prebuild commkit JIT modules")
    parser.add_argument("--arch", help="offload arch, default: this GPU's")
    parser.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 8)
    parser.add_argument("kernels", nargs="*", help="<type>/<name>, default: every kernel of the arch")
    args = parser.parse_args()
    arch = args.arch or device_arch()
    family = arch_family(arch)
    if args.kernels:
        wanted = [tuple(k.split("/", 1)) for k in args.kernels]
        wanted = [(t, lookup(family, t, n).mode, n) for t, n in wanted]
    else:
        wanted = [(k.kernel_type, k.mode, k.name) for k in list_kernels(family=family)]
    jobs = [("ck_runtime", [CSRC / "runtime" / "runtime.cu"])]
    jobs += [(kernel_module_name(family, t, n), [kernel_source(family, t, m, n)]) for t, m, n in wanted]
    failed = 0
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(build, mod, srcs, arch): mod for mod, srcs in jobs}
        for fut, mod in futures.items():
            try:
                fut.result()
            except Exception as err:  # noqa: BLE001 - report every failure
                failed += 1
                print(f"[commkit] {mod}: {err}", file=sys.stderr)
    print(f"[commkit] {len(jobs) - failed}/{len(jobs)} modules up to date for {arch}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    _main()
