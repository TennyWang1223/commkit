"""all_reduce: accuracy and latency of every commkit all_reduce kernel.

How to run (plain python; the script spawns one process per GPU itself):
    python tests/test_all_reduce.py                         # every kernel, TP 2 / 4 / 8, accuracy + latency
    python tests/test_all_reduce.py -t 8                    # TP8 only
    python tests/test_all_reduce.py -t 8 -k lamport_1shot_warpsplit,ll_1shot
    python tests/test_all_reduce.py -t 8 -k "ll_1shot:block=512" -s 8k,64k --no-acc
    python tests/test_all_reduce.py --no-perf               # accuracy only

Arguments:
    -t, --tp          world sizes, e.g. 2,8 (default 2,4,8, those that fit the GPUs)
    -k, --kernels     kernel names, comma separated; "name:key=value;key=value" passes
                      constructor arguments (default: every all_reduce kernel of this
                      GPU's arch, plus the extra launch configs in CONFIGS below)
    -d, --dtypes      accuracy dtypes, e.g. bf16,fp16 (default: every dtype a kernel takes)
    -s, --sizes       latency message sizes in bytes, e.g. 8k,64k,1m (default PERF_SIZES)
    --perf-dtype      latency dtype (default bf16)
    --no-acc          skip the accuracy part
    --no-perf         skip the latency part

What is checked against what:
    accuracy  ar = commkit.Kernel("all_reduce", name); out = ar.run(x) for every dtype and
              ACC_SIZES, eagerly and replayed from a CUDA graph (pull kernels also with x
              written into ar.input_buffer(), no copy). out must equal, bit for bit, the
              rank-order fp32 sum of every rank's input rounded once to the dtype: what
              every kernel computes, so every rank gets the same bits. Lamport kernels
              also get the 0xffff sentinel bit pattern in rank 0's input: it must come out
              NaN and must not hang. "-" in the table: the kernel does not take the case
              (the reason is printed below the table).
    latency   us per call, slowest rank, ITERS calls in a row:
              eager  ar.run(x) from python (pull kernels first copy x into their staging
                     buffer, aiter's eager path)
              graph  the same calls captured in one CUDA graph and replayed (pull kernels
                     read x from ar.input_buffer(), aiter's registered-input graph path)
              A graph slower than eager fails the run.
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

# accuracy message sizes in bytes; a kernel that does not take one shows "-"
ACC_SIZES = [16, 128, 4096 + 128, 64 << 10, 1 << 20, 3 << 20, 16 << 20]
PERF_SIZES = "8k,64k,512k,2m,8m,32m"
# launch configs tested besides each kernel's default
CONFIGS = {
    "ll_1shot": [{"block": 512}, {"block": 1024}],
    "ll128_1shot": [{"block": 512}],
}
ITERS = 10  # calls per timed run (and per CUDA graph)


def make_inputs(numel: int, dtype, world_size: int, seed: int) -> list[torch.Tensor]:
    """Every rank's input, from a seed per rank: each rank builds all of them
    for the reference and uses its own."""
    xs = []
    for r in range(world_size):
        gen = torch.Generator(device="cuda").manual_seed(seed * 1000 + r)
        xs.append(torch.randn(numel, generator=gen, device="cuda").to(dtype))
    return xs


def reference(xs: list[torch.Tensor]) -> torch.Tensor:
    """rank-order fp32 sum, rounded once"""
    acc = xs[0].float()
    for x in xs[1:]:
        acc += x.float()
    return acc.to(xs[0].dtype)


def count_diff(out: torch.Tensor, ref: torch.Tensor) -> int:
    """elements that are not bit-identical (NaN equals NaN)"""
    return int(((out != ref) & ~(out.isnan() & ref.isnan())).sum())


def check_accuracy(ar, rank, world_size, dtypes, label):
    rows, seed = [], 0
    for dtype in dtypes:
        if dtype not in ar.dtypes:
            continue
        for nbytes in ACC_SIZES:
            numel = nbytes // torch.empty((), dtype=dtype).element_size()
            row = dict(kernel=label, dtype=DTYPE_NAMES[dtype], case=size_str(nbytes))

            def inputs():
                nonlocal seed
                seed += 1
                xs = make_inputs(numel, dtype, world_size, seed)
                if ar.proto == "lamport":
                    xs[0].view(torch.int16)[::97] = -1  # the 0xffff sentinel, a NaN
                return xs

            # eager
            xs = inputs()
            try:
                out = ar.run(xs[rank])
            except ValueError as err:  # the kernel does not take this case (same on every rank)
                rows.append(dict(row, status="-: " + str(err).split(": ", 1)[-1]))
                continue
            problems = []
            if n := count_diff(out, reference(xs)):
                problems.append(f"eager {n} differ")

            # CUDA graph: capture one call, replay it twice with new inputs
            x = torch.empty_like(xs[rank])
            graph = torch.cuda.CUDAGraph()
            with torch.cuda.graph(graph):
                out = ar.run(x)
            for _ in range(2):
                xs = inputs()
                x.copy_(xs[rank])
                graph.replay()
                torch.cuda.synchronize()
                if n := count_diff(out, reference(xs)):
                    problems.append(f"graph {n} differ")

            # pull kernels: input written into the staging buffer (no copy), in a graph
            if ar.mode == "pull":
                xb = ar.input_buffer(x.shape, dtype)
                graph = torch.cuda.CUDAGraph()
                with torch.cuda.graph(graph):
                    out = ar.run(xb)
                xs = inputs()
                xb.copy_(xs[rank])
                graph.replay()
                torch.cuda.synchronize()
                if n := count_diff(out, reference(xs)):
                    problems.append(f"input_buffer graph {n} differ")
            rows.append(dict(row, status="; ".join(problems) or "ok"))
    return rows


def measure_latency(ar, sizes, dtype, label):
    rows = []
    elem = torch.empty((), dtype=dtype).element_size()
    for nbytes in sizes:
        row = dict(kernel=label, case=size_str(nbytes))
        x = torch.randn(nbytes // elem, device="cuda").to(dtype)
        try:
            ar.run(x)
        except (ValueError, TypeError) as err:
            rows.append(dict(row, skip=str(err)))
            continue
        # eager: ITERS calls from python
        def eager():
            for _ in range(ITERS):
                ar.run(x)

        # graph: the same calls in one CUDA graph; pull kernels read x from input_buffer()
        src = ar.input_buffer(x.shape, dtype).copy_(x) if ar.mode == "pull" else x
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            for _ in range(ITERS):
                ar.run(src)
        warm = torch.cuda.CUDAGraph()  # one call, replayed untimed before each timed replay
        with torch.cuda.graph(warm):
            ar.run(src)
        eager_us, graph_us = time_eager_graph(eager, lambda: ar.run(x), graph.replay, warm.replay, ITERS)
        rows.append(dict(row, eager=eager_us, graph=graph_us))
        del graph, warm
    return rows


def worker(rank, world_size, port, kernels, args):
    init_dist(rank, world_size, port)
    acc, perf = [], []
    for name, cfg in kernels:
        label = kernel_label(name, cfg)
        try:
            ar = commkit.Kernel("all_reduce", name, **cfg)
        except ValueError as err:  # e.g. the kernel does not run at this world size
            acc.append(dict(kernel=label, dtype="-", case="-", status="-: " + str(err).split(": ", 1)[-1]))
            continue
        if rank == 0:
            print(f"[tp{world_size}] {label}", flush=True)
        if not args.no_acc:
            acc += check_accuracy(ar, rank, world_size, args.dtypes, label)
        if not args.no_perf:
            perf += measure_latency(ar, args.sizes, args.perf_dtype, label)
        ar.close()
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
    kernels = parse_kernels(args.kernels, [k.name for k in commkit.list_kernels("all_reduce")], CONFIGS)

    failed = []
    for ws in world_sizes:
        try:
            ranks = launch(worker, ws, kernels, args)
        except RuntimeError as err:
            print(f"\n[tp{ws}] FAILED\n{err}")
            failed.append(f"tp{ws}: {str(err).splitlines()[0]}")
            continue
        if not args.no_acc:
            failed += report_accuracy(f"[tp{ws}] all_reduce accuracy (bit for bit vs rank-order fp32 sum)",
                                      [r[0] for r in ranks])
        if not args.no_perf:
            failed += report_latency(f"[tp{ws}] all_reduce {DTYPE_NAMES[args.perf_dtype]}", [r[1] for r in ranks])
    print("\nall passed" if not failed else f"\n{len(failed)} failure(s)")
    return 1 if failed else 0


def test_all_reduce():  # pytest entry: the full default run
    assert main([]) == 0


if __name__ == "__main__":
    sys.exit(main())
