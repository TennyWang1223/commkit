"""all_gather: accuracy and latency of every commkit all_gather kernel.

How to run (plain python; the script spawns one process per GPU itself):
    python tests/test_all_gather.py                         # every kernel, TP 2 / 4 / 8, accuracy + latency
    python tests/test_all_gather.py -t 8 -k simple_pull
    python tests/test_all_gather.py -t 8 -s 64k,1m --no-acc
    python tests/test_all_gather.py --no-perf               # accuracy only

Arguments:
    -t, --tp          world sizes, e.g. 2,8 (default 2,4,8, those that fit the GPUs)
    -k, --kernels     kernel names, comma separated; "name:key=value;key=value" passes
                      constructor arguments (default: every all_gather kernel of this
                      GPU's arch, plus the extra launch configs in CONFIGS below)
    -d, --dtypes      accuracy dtypes, e.g. bf16,fp16 (default: every dtype a kernel takes)
    -s, --sizes       latency sizes: bytes per rank, gathered along dim 0 (default PERF_SIZES)
    --perf-dtype      latency dtype (default bf16)
    --no-acc          skip the accuracy part
    --no-perf         skip the latency part

What is checked against what:
    accuracy  ag = commkit.Kernel("all_gather", name); out = ag.run(x, dim) for every dtype
              and (shape, dim) in ACC_CASES, eagerly and replayed from a CUDA graph (pull
              kernels also with x written into ag.input_buffer(), no copy). out must equal
              torch.cat(every rank's input, dim) bit for bit. Lamport kernels also get the
              0xffff sentinel bit pattern in rank 0's input (must come out NaN, not hang).
              "-" in the table: the kernel does not take the case (reason below the table).
    latency   us per call, slowest rank, ITERS calls in a row: eager = ag.run(x, 0) from
              python (pull kernels copy x into their staging buffer, aiter's eager path);
              graph = the same calls in one CUDA graph (pull kernels read x from
              ag.input_buffer(), aiter's registered-input graph path). A graph slower than
              eager fails the run.
    Exit code 1 on any mismatch, hang, or graph slower than eager.
"""

from __future__ import annotations

import argparse
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
    parse_size,
    report_accuracy,
    report_latency,
    size_str,
    time_eager_graph,
)

# (shape of each rank's input, dim); a kernel that does not take one shows "-"
ACC_CASES = [
    ((257,), 0),
    ((8,), 0),
    ((64, 128), 0),
    ((7, 4096), 0),
    ((3, 5, 96), 0),
    ((1024, 1024), 0),
    ((16, 512), -1),
    ((5, 8, 64), -1),
    ((3, 1000), -1),
    ((333, 1024), -1),
]
PERF_SIZES = "8k,64k,512k,2m,8m"
# launch configs tested besides each kernel's default
CONFIGS: dict = {}
ITERS = 10


def make_inputs(shape, dtype, world_size: int, seed: int) -> list[torch.Tensor]:
    """Every rank's input, from a seed per rank: each rank builds all of them
    for the reference and uses its own."""
    xs = []
    for r in range(world_size):
        gen = torch.Generator(device="cuda").manual_seed(seed * 1000 + r)
        xs.append(torch.randn(shape, generator=gen, device="cuda").to(dtype))
    return xs


def count_diff(out: torch.Tensor, ref: torch.Tensor) -> int:
    """elements that are not bit-identical (NaN equals NaN)"""
    return int(((out != ref) & ~(out.isnan() & ref.isnan())).sum())


def check_accuracy(ag, rank, world_size, dtypes, label):
    rows, seed = [], 0
    for dtype in dtypes:
        if dtype not in ag.dtypes:
            continue
        for shape, dim in ACC_CASES:
            row = dict(kernel=label, dtype=DTYPE_NAMES[dtype], case=f"{'x'.join(map(str, shape))} d{dim}")

            def inputs():
                nonlocal seed
                seed += 1
                xs = make_inputs(shape, dtype, world_size, seed)
                if ag.proto == "lamport" and dtype != torch.float32:
                    xs[0].view(torch.int16).view(-1)[::97] = -1  # the 0xffff sentinel, a NaN
                return xs

            # eager
            xs = inputs()
            try:
                out = ag.run(xs[rank], dim)
            except ValueError as err:  # the kernel does not take this case (same on every rank)
                rows.append(dict(row, status="-: " + str(err).split(": ", 1)[-1]))
                continue
            problems = []
            if n := count_diff(out, torch.cat(xs, dim)):
                problems.append(f"eager {n} differ")

            # CUDA graph: capture one call, replay it twice with new inputs
            x = torch.empty_like(xs[rank])
            graph = torch.cuda.CUDAGraph()
            with torch.cuda.graph(graph):
                out = ag.run(x, dim)
            for _ in range(2):
                xs = inputs()
                x.copy_(xs[rank])
                graph.replay()
                torch.cuda.synchronize()
                if n := count_diff(out, torch.cat(xs, dim)):
                    problems.append(f"graph {n} differ")

            # pull kernels: input written into the staging buffer (no copy), in a graph
            if ag.mode == "pull":
                xb = ag.input_buffer(x.shape, dtype)
                graph = torch.cuda.CUDAGraph()
                with torch.cuda.graph(graph):
                    out = ag.run(xb, dim)
                xs = inputs()
                xb.copy_(xs[rank])
                graph.replay()
                torch.cuda.synchronize()
                if n := count_diff(out, torch.cat(xs, dim)):
                    problems.append(f"input_buffer graph {n} differ")
            rows.append(dict(row, status="; ".join(problems) or "ok"))
    return rows


def measure_latency(ag, sizes, dtype, label):
    rows = []
    elem = torch.empty((), dtype=dtype).element_size()
    for nbytes in sizes:
        row = dict(kernel=label, case=size_str(nbytes))
        x = torch.randn(nbytes // elem, device="cuda").to(dtype)
        try:
            ag.run(x, 0)
        except (ValueError, TypeError) as err:
            rows.append(dict(row, skip=str(err)))
            continue
        # eager: ITERS calls from python
        def eager():
            for _ in range(ITERS):
                ag.run(x, 0)

        # graph: the same calls in one CUDA graph; pull kernels read x from input_buffer()
        src = ag.input_buffer(x.shape, dtype).copy_(x) if ag.mode == "pull" else x
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            for _ in range(ITERS):
                ag.run(src, 0)
        warm = torch.cuda.CUDAGraph()  # one call, replayed untimed before each timed replay
        with torch.cuda.graph(warm):
            ag.run(src, 0)
        eager_us, graph_us = time_eager_graph(eager, lambda: ag.run(x, 0), graph.replay, warm.replay, ITERS)
        rows.append(dict(row, eager=eager_us, graph=graph_us))
        del graph, warm
    return rows


def worker(rank, world_size, port, kernels, args):
    init_dist(rank, world_size, port)
    acc, perf = [], []
    for name, cfg in kernels:
        label = kernel_label(name, cfg)
        try:
            ag = commkit.Kernel("all_gather", name, **cfg)
        except ValueError as err:  # e.g. the kernel does not run at this world size
            acc.append(dict(kernel=label, dtype="-", case="-", status="-: " + str(err).split(": ", 1)[-1]))
            continue
        if rank == 0:
            print(f"[tp{world_size}] {label}", flush=True)
        if not args.no_acc:
            acc += check_accuracy(ag, rank, world_size, args.dtypes, label)
        if not args.no_perf:
            perf += measure_latency(ag, args.sizes, args.perf_dtype, label)
        ag.close()
    dist.destroy_process_group()
    return acc, perf


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-t", "--tp", default="2,4,8")
    parser.add_argument("-k", "--kernels", default="")
    parser.add_argument("-d", "--dtypes", default="bf16,fp16,fp32")
    parser.add_argument("-s", "--sizes", default=PERF_SIZES)
    parser.add_argument("--perf-dtype", default="bf16", choices=DTYPES)
    parser.add_argument("--no-acc", action="store_true")
    parser.add_argument("--no-perf", action="store_true")
    args = parser.parse_args(argv)
    args.dtypes = [DTYPES[d] for d in args.dtypes.split(",")]
    args.sizes = [parse_size(s) for s in args.sizes.split(",")]
    args.perf_dtype = DTYPES[args.perf_dtype]
    world_sizes = [int(t) for t in args.tp.split(",") if int(t) <= torch.cuda.device_count()]
    kernels = parse_kernels(args.kernels, [k.name for k in commkit.list_kernels("all_gather")], CONFIGS)

    failed = []
    for ws in world_sizes:
        try:
            ranks = launch(worker, ws, kernels, args)
        except RuntimeError as err:
            print(f"\n[tp{ws}] FAILED\n{err}")
            failed.append(f"tp{ws}: {str(err).splitlines()[0]}")
            continue
        if not args.no_acc:
            failed += report_accuracy(f"[tp{ws}] all_gather accuracy (bit for bit vs torch.cat)", [r[0] for r in ranks])
        if not args.no_perf:
            failed += report_latency(f"[tp{ws}] all_gather {DTYPE_NAMES[args.perf_dtype]}, bytes per rank",
                                     [r[1] for r in ranks])
    print("\nall passed" if not failed else f"\n{len(failed)} failure(s)")
    return 1 if failed else 0


def test_all_gather():  # pytest entry: the full default run
    assert main([]) == 0


if __name__ == "__main__":
    sys.exit(main())
