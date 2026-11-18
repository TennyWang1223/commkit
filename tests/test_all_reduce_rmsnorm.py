"""all_reduce + residual add + RMSNorm: accuracy and latency of every commkit
all_reduce_rmsnorm kernel.

How to run (plain python; the script spawns one process per GPU itself):
    python tests/test_all_reduce_rmsnorm.py                 # every kernel, TP 2 / 4 / 8, accuracy + latency
    python tests/test_all_reduce_rmsnorm.py -t 8 -k lamport_1shot_warpsplit,simple_pull_1shot
    python tests/test_all_reduce_rmsnorm.py -t 8 -k "lamport_2shot:split=2" -s 32x7168 --no-acc
    python tests/test_all_reduce_rmsnorm.py --no-perf       # accuracy only

Arguments:
    -t, --tp          world sizes, e.g. 2,8 (default 2,4,8, those that fit the GPUs)
    -k, --kernels     kernel names, comma separated; "name:key=value;key=value" passes
                      constructor arguments (default: every all_reduce_rmsnorm kernel of
                      this GPU's arch, plus the extra launch configs in CONFIGS below)
    -d, --dtypes      accuracy dtypes, e.g. bf16,fp16 (default: every dtype a kernel takes)
    -s, --sizes       latency shapes ROWSxHIDDEN, e.g. 1x4096,32x7168 (default PERF_SHAPES)
    --perf-dtype      latency dtype (default bf16)
    --no-acc          skip the accuracy part
    --no-perf         skip the latency part

What is checked against what:
    accuracy  k = commkit.Kernel("all_reduce_rmsnorm", name);
              out, residual_out = k.run(x, residual, weight, EPS, gemma_norm) for every
              dtype, ACC_SHAPES and gemma_norm off / on ("g" in the case name), eagerly and
              replayed from a CUDA graph (pull kernels also with x written into
              k.input_buffer(), no copy). The residual and the weight are the same on
              every rank, as in tensor parallelism. Reference, in fp32:
                  acc = (rank-order fp32 sum of every rank's x, rounded to the dtype) + residual
                  residual_out = acc rounded               -> must match bit for bit
                  out = acc * rsqrt(mean(acc**2) + EPS) * weight (weight + 1 with gemma_norm)
                                                           -> within 2 ulp (64 for fp32; the
                                                              sum-of-squares order differs)
              and out must be bit-identical on every rank. Lamport kernels also must match
              simple_pull_1shot bit for bit (same rounding steps), and get the 0xffff
              sentinel in rank 0's x (must come out NaN, not hang). "-" in the table: the
              kernel does not take the case (reason below the table).
    latency   us per call, slowest rank, ITERS calls in a row: eager = k.run(...) from python
              (pull kernels copy x into their staging buffer, aiter's eager path); graph =
              the same calls in one CUDA graph (pull kernels read x from k.input_buffer(),
              aiter's registered-input graph path). A graph slower than eager fails the run.
    Exit code 1 on any mismatch, hang, or graph slower than eager.
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

import torch
import torch.distributed as dist

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # the repo root, for `import commkit`
import commkit  # noqa: E402
from utils import (  # noqa: E402
    DTYPE_NAMES,
    DTYPES,
    init_dist,
    kernel_label,
    launch,
    parse_kernels,
    report_accuracy,
    report_latency,
    time_eager_graph,
)

# (rows, hidden); a kernel that does not take one shows "-"
ACC_SHAPES = [(1, 1024), (7, 4096), (32, 7168), (128, 4096), (5, 8192), (80, 2048), (200, 7168)]
PERF_SHAPES = "1x4096,4x7168,32x7168,128x7168,512x7168"
# launch configs tested besides each kernel's default
CONFIGS = {
    "lamport_1shot_flat": [{"block": 128}, {"block": 64}],
    "lamport_1shot_warpsplit": [{"groups": 2}],
    "lamport_2shot": [{"split": 1}, {"split": 4}],
}
EPS = 1e-6
ITERS = 10


def make_inputs(shape, dtype, world_size: int, seed: int):
    """Every rank's x (a seed per rank, so each rank can build all of them for
    the reference), and the residual and weight every rank shares."""
    xs = []
    for r in range(world_size):
        gen = torch.Generator(device="cuda").manual_seed(seed * 1000 + r)
        xs.append(torch.randn(shape, generator=gen, device="cuda").to(dtype))
    gen = torch.Generator(device="cuda").manual_seed(seed * 1000 + 999)
    residual = torch.randn(shape, generator=gen, device="cuda").to(dtype)
    weight = (torch.rand(shape[-1], generator=gen, device="cuda") + 0.5).to(dtype)
    return xs, residual, weight


def reference(xs, residual, weight, gemma_norm):
    """(out, residual_out) in fp32, rounded like the kernels"""
    acc = xs[0].float()
    for x in xs[1:]:
        acc += x.float()
    acc = acc.to(xs[0].dtype).float() + residual.float()
    rms = torch.rsqrt(acc.pow(2).mean(-1, keepdim=True) + EPS)
    w = weight.float() + (1.0 if gemma_norm else 0.0)
    return (acc * rms * w).to(xs[0].dtype), acc.to(xs[0].dtype)


def count_diff(out: torch.Tensor, ref: torch.Tensor) -> int:
    """elements that are not bit-identical (NaN equals NaN)"""
    return int(((out != ref) & ~(out.isnan() & ref.isnan())).sum())


def count_far(out: torch.Tensor, ref: torch.Tensor) -> int:
    """elements more than 2 ulp (64 for fp32) of max(|ref|, 1) away from ref"""
    ulps = 64 if out.dtype == torch.float32 else 2
    tol = ulps * torch.finfo(out.dtype).eps * ref.float().abs().clamp(min=1.0)
    return int(((out.float() - ref.float()).abs() > tol).sum())


def same_on_every_rank(t: torch.Tensor) -> bool:
    digest = hashlib.sha1(t.view(torch.int16 if t.element_size() == 2 else torch.int32).cpu().numpy().tobytes())
    digests = [None] * dist.get_world_size()
    dist.all_gather_object(digests, digest.hexdigest())  # gloo
    return len(set(digests)) == 1


def compare(what, got, xs, residual, weight, gemma_norm, problems):
    out, res_out = got
    ref_out, ref_res = reference(xs, residual, weight, gemma_norm)
    if n := count_diff(res_out, ref_res):
        problems.append(f"{what} residual_out {n} differ")
    if n := count_far(out, ref_out):
        problems.append(f"{what} out {n} beyond tolerance")
    if not same_on_every_rank(out):
        problems.append(f"{what} out differs between ranks")


def check_accuracy(k, one_stage, rank, world_size, dtypes, label):
    rows, seed = [], 0
    for dtype in dtypes:
        if dtype not in k.dtypes:
            continue
        for shape in ACC_SHAPES:
            for gemma_norm in (False, True):
                row = dict(kernel=label, dtype=DTYPE_NAMES[dtype], case=f"{shape[0]}x{shape[1]}" + (" g" if gemma_norm else ""))

                def inputs():
                    nonlocal seed
                    seed += 1
                    xs, residual, weight = make_inputs(shape, dtype, world_size, seed)
                    if k.proto == "lamport":
                        xs[0].view(torch.int16).view(-1)[::97] = -1  # the 0xffff sentinel, a NaN
                    return xs, residual, weight

                # eager
                xs, residual, weight = inputs()
                try:
                    got = k.run(xs[rank], residual, weight, EPS, gemma_norm)
                except ValueError as err:  # the kernel does not take this case (same on every rank)
                    rows.append(dict(row, status="-: " + str(err).split(": ", 1)[-1]))
                    continue
                problems = []
                compare("eager", got, xs, residual, weight, gemma_norm, problems)

                # lamport kernels repeat the 1-stage epilogue step by step: bit for bit
                if one_stage is not None and k.proto == "lamport":
                    want = one_stage.run(xs[rank], residual, weight, EPS, gemma_norm)
                    if n := count_diff(got[0], want[0]) + count_diff(got[1], want[1]):
                        problems.append(f"{n} differ from simple_pull_1shot")

                # CUDA graph: capture one call, replay it twice with new inputs
                x = torch.empty_like(xs[rank])
                graph = torch.cuda.CUDAGraph()
                with torch.cuda.graph(graph):
                    got = k.run(x, residual, weight, EPS, gemma_norm)
                for _ in range(2):
                    xs, _, _ = inputs()
                    x.copy_(xs[rank])
                    graph.replay()
                    torch.cuda.synchronize()
                    compare("graph", got, xs, residual, weight, gemma_norm, problems)

                # pull kernels: input written into the staging buffer (no copy), in a graph
                if k.mode == "pull":
                    xb = k.input_buffer(x.shape, dtype)
                    graph = torch.cuda.CUDAGraph()
                    with torch.cuda.graph(graph):
                        got = k.run(xb, residual, weight, EPS, gemma_norm)
                    xs, _, _ = inputs()
                    xb.copy_(xs[rank])
                    graph.replay()
                    torch.cuda.synchronize()
                    compare("input_buffer graph", got, xs, residual, weight, gemma_norm, problems)
                rows.append(dict(row, status="; ".join(problems) or "ok"))
    return rows


def measure_latency(k, shapes, dtype, label):
    rows = []
    for rows_, hidden in shapes:
        row = dict(kernel=label, case=f"{rows_}x{hidden}")
        x = torch.randn(rows_, hidden, device="cuda").to(dtype)
        residual = torch.randn(rows_, hidden, device="cuda").to(dtype)
        weight = torch.rand(hidden, device="cuda").to(dtype)
        try:
            k.run(x, residual, weight, EPS)
        except (ValueError, TypeError) as err:
            rows.append(dict(row, skip=str(err)))
            continue
        # eager: ITERS calls from python
        def eager():
            for _ in range(ITERS):
                k.run(x, residual, weight, EPS)

        # graph: the same calls in one CUDA graph; pull kernels read x from input_buffer()
        src = k.input_buffer(x.shape, dtype).copy_(x) if k.mode == "pull" else x
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            for _ in range(ITERS):
                k.run(src, residual, weight, EPS)
        warm = torch.cuda.CUDAGraph()  # one call, replayed untimed before each timed replay
        with torch.cuda.graph(warm):
            k.run(src, residual, weight, EPS)
        eager_us, graph_us = time_eager_graph(eager, lambda: k.run(x, residual, weight, EPS),
                                              graph.replay, warm.replay, ITERS)
        rows.append(dict(row, eager=eager_us, graph=graph_us))
        del graph, warm
    return rows


def worker(rank, world_size, port, kernels, args):
    init_dist(rank, world_size, port)
    # the kernel the lamport ones must match bit for bit
    one_stage = None
    if not args.no_acc and any(name.startswith("lamport") for name, _ in kernels):
        one_stage = commkit.Kernel("all_reduce_rmsnorm", "simple_pull_1shot")
    acc, perf = [], []
    for name, cfg in kernels:
        label = kernel_label(name, cfg)
        try:
            k = commkit.Kernel("all_reduce_rmsnorm", name, **cfg)
        except ValueError as err:  # e.g. the kernel does not run at this world size
            acc.append(dict(kernel=label, dtype="-", case="-", status="-: " + str(err).split(": ", 1)[-1]))
            continue
        if rank == 0:
            print(f"[tp{world_size}] {label}", flush=True)
        if not args.no_acc:
            acc += check_accuracy(k, one_stage, rank, world_size, args.dtypes, label)
        if not args.no_perf:
            perf += measure_latency(k, args.sizes, args.perf_dtype, label)
        k.close()
    if one_stage is not None:
        one_stage.close()
    dist.destroy_process_group()
    return acc, perf


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-t", "--tp", default="2,4,8")
    parser.add_argument("-k", "--kernels", default="")
    parser.add_argument("-d", "--dtypes", default="bf16,fp16,fp32")
    parser.add_argument("-s", "--sizes", default=PERF_SHAPES)
    parser.add_argument("--perf-dtype", default="bf16", choices=DTYPES)
    parser.add_argument("--no-acc", action="store_true")
    parser.add_argument("--no-perf", action="store_true")
    args = parser.parse_args(argv)
    args.dtypes = [DTYPES[d] for d in args.dtypes.split(",")]
    args.sizes = [tuple(int(v) for v in s.lower().split("x")) for s in args.sizes.split(",")]
    args.perf_dtype = DTYPES[args.perf_dtype]
    world_sizes = [int(t) for t in args.tp.split(",") if int(t) <= torch.cuda.device_count()]
    kernels = parse_kernels(args.kernels, [k.name for k in commkit.list_kernels("all_reduce_rmsnorm")], CONFIGS)

    failed = []
    for ws in world_sizes:
        try:
            ranks = launch(worker, ws, kernels, args)
        except RuntimeError as err:
            print(f"\n[tp{ws}] FAILED\n{err}")
            failed.append(f"tp{ws}: {str(err).splitlines()[0]}")
            continue
        if not args.no_acc:
            failed += report_accuracy(f"[tp{ws}] all_reduce_rmsnorm accuracy (see the header for the checks)",
                                      [r[0] for r in ranks])
        if not args.no_perf:
            failed += report_latency(f"[tp{ws}] all_reduce_rmsnorm {DTYPE_NAMES[args.perf_dtype]}",
                                     [r[1] for r in ranks])
    print("\nall passed" if not failed else f"\n{len(failed)} failure(s)")
    return 1 if failed else 0


def test_all_reduce_rmsnorm():  # pytest entry: the full default run
    assert main([]) == 0


if __name__ == "__main__":
    sys.exit(main())
