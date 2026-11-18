"""Plumbing shared by the test scripts; nothing here knows about a kernel.

launch()      runs worker(rank, world_size, port, *args) in one process per GPU
              (multiprocessing.Pool, spawn), returns every rank's result. A
              rank that raises, or a hang (a kernel spinning on a flag that
              never comes), stops the run with that message.
init_dist()   cuda device + torch.distributed on gloo (no RCCL).
time_us()     median per-call latency of a launch function, CUDA events.
print_table() a pandas DataFrame to the terminal.
"""

from __future__ import annotations

import multiprocessing as mp
import re
import socket
import statistics
import traceback

import pandas as pd
import torch
import torch.distributed as dist

DTYPES = {"bf16": torch.bfloat16, "fp16": torch.float16, "fp32": torch.float32}
DTYPE_NAMES = {v: k for k, v in DTYPES.items()}


def parse_size(s: str) -> int:
    """'64k' -> 65536, '2m' -> 2097152, '100' -> 100"""
    s = s.strip().lower()
    units = {"k": 1 << 10, "m": 1 << 20, "g": 1 << 30}
    return int(float(s[:-1]) * units[s[-1]]) if s[-1] in units else int(s)


def size_str(nbytes: int) -> str:
    for unit, div in (("M", 1 << 20), ("K", 1 << 10)):
        if nbytes >= div and nbytes % div == 0:
            return f"{nbytes // div}{unit}"
    return f"{nbytes}B"


def parse_kernels(spec: str | None, available: list[str], configs: dict) -> list[tuple[str, dict]]:
    """'a,b:block=512' -> [('a', {}), ('b', {'block': 512})]. Without a spec:
    every available kernel, plus the extra configs listed for it."""
    if not spec:
        return [(n, {}) for n in available] + [(n, c) for n in available for c in configs.get(n, [])]
    out = []
    for item in spec.split(","):
        name, _, rest = item.partition(":")
        if name not in available:
            raise SystemExit(f"unknown kernel {name!r}; available: {', '.join(available)}")
        cfg = {}
        for kv in filter(None, rest.split(";")):
            key, _, value = kv.partition("=")
            cfg[key] = int(value) if value.lstrip("-").isdigit() else value
        out.append((name, cfg))
    return out


def kernel_label(name: str, cfg: dict) -> str:
    return name + "".join(f":{k}={v}" for k, v in cfg.items())


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def init_dist(rank: int, world_size: int, port: int) -> None:
    torch.cuda.set_device(rank)
    # the tests drive the GPU; one CPU thread per rank keeps 8 ranks from
    # fighting over cores, which shows up as noise in the eager timings
    torch.set_num_threads(1)
    dist.init_process_group(
        "gloo", init_method=f"tcp://127.0.0.1:{port}", rank=rank, world_size=world_size
    )


def _run(worker, rank, world_size, port, args):
    try:
        return worker(rank, world_size, port, *args)
    except BaseException:  # noqa: BLE001 - the parent prints it
        raise RuntimeError(f"rank {rank}:\n{traceback.format_exc()}") from None


def launch(worker, world_size: int, *args, timeout: float = 1800):
    """Runs worker on ranks 0..world_size-1, one process each; returns their
    results in rank order. Raises RuntimeError on a failure or a hang."""
    ctx = mp.get_context("spawn")
    port = free_port()
    with ctx.Pool(world_size, maxtasksperchild=1) as pool:
        jobs = [pool.apply_async(_run, (worker, r, world_size, port, args)) for r in range(world_size)]
        out = []
        for r, job in enumerate(jobs):
            try:
                out.append(job.get(timeout=timeout))
            except mp.TimeoutError:
                pool.terminate()
                raise RuntimeError(f"rank {r} did not finish in {timeout:.0f}s (hang?)") from None
            except Exception:
                pool.terminate()
                raise
        return out


def time_us(run, warm, iters: int, repeats: int = 20) -> float:
    """Median over `repeats` of (time of run()) / iters, in us. Before each
    timed run: a barrier, then warm() untimed (one call: it waits out the
    ranks' skew after the barrier, so the timed calls start in lockstep)."""
    times = []
    for _ in range(repeats):
        dist.barrier()
        warm()
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        start.record()
        run()
        stop.record()
        stop.synchronize()
        times.append(start.elapsed_time(stop) * 1000 / iters)
    return statistics.median(times)


def time_eager_graph(eager_run, eager_warm, graph_run, graph_warm, iters: int, rounds: int = 3):
    """(eager us, graph us): time_us of each, alternated over `rounds` rounds
    so both see the same drift (other jobs on the host), median of the rounds."""
    eager, graph = [], []
    for _ in range(rounds):
        eager.append(time_us(eager_run, eager_warm, iters))
        graph.append(time_us(graph_run, graph_warm, iters))
    return statistics.median(eager), statistics.median(graph)


def print_table(title: str, df: pd.DataFrame) -> None:
    print(f"\n{title}")
    with pd.option_context("display.max_rows", None, "display.max_columns", None, "display.width", 250):
        print(df.to_string())


# --------------------------------------------------------------------------
# reports: rows come back from every rank, one table per world size
# --------------------------------------------------------------------------
# a graph run may be this much slower than eager before it counts as slower
# (measurement noise on the slowest rank)
GRAPH_SLACK_RATIO = 1.05
GRAPH_SLACK_US = 1.0


def report_accuracy(title: str, ranks_rows: list[list[dict]]) -> list[str]:
    """Rows: dict(kernel, dtype, case, status), status 'ok', a failure, or
    '-: <why the kernel does not take the case>'. Prints kernel x case;
    returns the failures."""
    merged: dict[tuple, str] = {}
    for rank, rows in enumerate(ranks_rows):
        for row in rows:
            key = (row["kernel"], row["dtype"], row["case"])
            status = row["status"]
            if status != "ok" and not status.startswith("-") and not merged.get(key, "ok").startswith("rank"):
                status = f"rank {rank}: {status}"
            merged.setdefault(key, status)
            if status.startswith("rank"):
                merged[key] = status
    if not merged:
        return []
    cases = list(dict.fromkeys(k[2] for k in merged))
    index = list(dict.fromkeys(k[:2] for k in merged))
    cell = {k: ("ok" if v == "ok" else "-" if v.startswith("-") else "FAIL") for k, v in merged.items()}
    df = pd.DataFrame(
        [[cell.get(i + (c,), "") for c in cases] for i in index],
        index=pd.MultiIndex.from_tuples(index, names=["kernel", "dtype"]),
        columns=cases,
    )
    print_table(title, df)
    # one line per kernel and reason ("input is N bytes, over ..." -> "over ...")
    skipped = sorted({(k[0], re.sub(r"^input is \d+ bytes, ", "", v[2:].strip())) for k, v in merged.items() if v.startswith("-")})
    for kernel, why in skipped:
        print(f"  - {kernel}: {why}")
    failures = [f"{k[0]} {k[1]} {k[2]}: {v}" for k, v in merged.items() if cell[k] == "FAIL"]
    for f in failures:
        print(f"  FAIL {f}")
    return failures


def report_latency(title: str, ranks_rows: list[list[dict]]) -> list[str]:
    """Rows: dict(kernel, case, eager, graph) in us, or skip=<why>. Prints the
    slowest rank's graph and eager tables (case x kernel) and returns the
    cases where the graph is slower than eager."""
    slowest: dict[tuple, dict] = {}
    for rows in ranks_rows:
        for row in rows:
            key = (row["case"], row["kernel"])
            cur = slowest.setdefault(key, {})
            for mode in ("eager", "graph"):
                if row.get(mode) is not None:
                    cur[mode] = max(cur.get(mode) or 0.0, row[mode])
    if not slowest:
        return []
    cases = list(dict.fromkeys(k[0] for k in slowest))
    kernels = list(dict.fromkeys(k[1] for k in slowest))

    def table(mode):
        df = pd.DataFrame(index=pd.Index(cases, name="case"), columns=kernels, dtype=object)
        for (case, kernel), row in slowest.items():
            df.loc[case, kernel] = "-" if row.get(mode) is None else f"{row[mode]:.1f}"
        best = []
        for case in cases:
            timed = [(slowest[(case, k)][mode], k) for k in kernels if slowest.get((case, k), {}).get(mode) is not None]
            best.append(min(timed)[1] if timed else "-")
        df["fastest"] = best
        return df

    print_table(f"{title}: graph, us per call (slowest rank)", table("graph"))
    print_table(f"{title}: eager, us per call (slowest rank)", table("eager"))
    slower = []
    for (case, kernel), row in slowest.items():
        g, e = row.get("graph"), row.get("eager")
        if g is not None and e is not None and g > e * GRAPH_SLACK_RATIO + GRAPH_SLACK_US:
            slower.append(f"{kernel} {case}: graph {g:.1f} us > eager {e:.1f} us")
    print("  graph slower than eager: " + ("none" if not slower else ""))
    for s in slower:
        print(f"  SLOWER {s}")
    return slower
