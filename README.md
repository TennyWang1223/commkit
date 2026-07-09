# commkit

A lightweight GPU communication-operator development library for ROCm/HIP
(MI3xx, gfx942). Pure C++, zero Python.

Design goals:

- **Kernel calls stay raw.** Once the comm group has prepared
  `RankData* / Signal* / RankSignals`, the test launches the kernel directly
  with `<<<grid, block, 0, stream>>>` — no dispatch, no conditional branching.
- **Comm group stays minimal.** Two lines to start:
  `CommGroup g(world_size); g.init();`. IPC handles are exchanged through a
  built-in TCP store — no torch, no MPI.
- **One sub-project per kernel.** Each kernel ships its own
  `CMakeLists.txt` + `kernel.cuh` + `test.cpp` and can be built and run
  independently of the rest of the repo.

## Layout

```
commkit/
├── CMakeLists.txt              top-level, aggregates every kernel
├── cmake/CommkitKernel.cmake   add_commkit_kernel() helper
├── scripts/run.sh              spawns N children with RANK/WORLD_SIZE/MASTER_*
├── include/
│   ├── opus/                   opus dtypes (bf16_t / vector_t / ...)
│   └── commkit/                signal / sync / cast / tmp_buf / bench / ...
├── src/                        comm_group / ipc_buffer / tcp_store
└── kernels/                    grouped by GPU arch: kernels/<arch>/<kernel>/
    ├── gfx9/                   MI300/MI308/MI355 implementations
    │   ├── allreduce_1stage/   kernel sub-project
    │   └── allreduce_2stage/
    └── gfx12/                  MI455 implementations
```

Kernels live under an arch directory because the implementation differs per
GPU arch. The cross-card memory backend (VMM) is shared, but the kernels
themselves are not — build the arch that matches your host.

## Requirements

- ROCm 7.x (defaults to `/opt/rocm`, compiler `amdclang++`)
- CMake ≥ 3.21

## Build

### All kernels (top-level)

```bash
cd commkit
cmake -B build
cmake --build build -j
```

Outputs: `build/kernels/<name>/test_<name>` plus a `run.sh` copy next to it.

### A single kernel (standalone)

Each kernel directory is itself a CMake project. It bootstraps
`commkit_core` automatically and skips sibling kernels:

```bash
cd commkit/kernels/gfx9/allreduce_1stage
cmake -B build
cmake --build build -j
```

Outputs: `build/test_allreduce_1stage` plus a `run.sh` copy next to it.

## Run

`run.sh` is copied next to every test binary at build time, so just:

```bash
cd build/kernels/gfx9/allreduce_1stage   # or the standalone build dir
./run.sh 8 ./test_allreduce_1stage
```

The first argument is the world size. Each rank prints its own line with
latency and `max_abs_err`.
