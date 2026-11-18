# commkit

Communication kernels for AMD GPUs, one kernel per name. HIP kernels, a thin
Python layer, torch unit tests, JIT compilation (the aiter layout, without
aiter's dispatch). The kernels are ported from aiter's custom all-reduce.

```python
import torch, torch.distributed as dist
import commkit

dist.init_process_group("gloo")          # any backend; commkit only needs it at construction
torch.cuda.set_device(dist.get_rank())

ar = commkit.Kernel("all_reduce", "lamport_1shot_warpsplit")
out = ar.run(x)                          # sum of x over the group, on every rank
ar.close()

commkit.list_kernels("all_reduce", proto="lamport")
```

`Kernel(type, name, group=None, **cfg)` is collective: every rank creates the
same kernels in the same order (the constructor allocates the kernel's own
scratch and exchanges IPC handles; mismatched arguments raise instead of
hanging), calls `run()` with the same shapes, and calls `close()`. No
dispatch: a kernel takes the arguments or raises `ValueError` saying why.

| type | `run()` |
|---|---|
| `all_reduce` | `run(x, out=None) -> out` |
| `all_gather` | `run(x, dim=0, out=None) -> out`, dim is the first or the last dim |
| `reduce_scatter` | `run(x, dim=0, out=None) -> out`, chunk `rank` along dim |
| `all_reduce_rmsnorm` | `run(x, residual, weight, eps=1e-6, gemma_norm=False) -> (out, residual_out)` |

## Kernel names

Sources live in `kernel/<type>/<pull|push>/<name>.{cuh,cu}`; the name used in
`Kernel(type, name)` is the file name.

- **proto**: `simple` (flag barriers, plain loads/stores), `ll` (8B data + flags
  in 16B lines), `ll128` (128B lines, in-line flag), `lamport` (sentinel-armed
  inboxes, the data is the signal).
- **pull / push** is the folder (and the op's base class, `PullOp` / `PushOp`).
  **pull**: peers read this rank's input in place, so `run()` first copies the
  input into the kernel's IPC staging buffer (one D2D copy, captured into a
  graph like the kernel); write the input into `k.input_buffer(shape, dtype)`
  to skip the copy. **push**: this rank writes into the peers' buffers; the
  input stays where it is. No kernel copies its output.
- LL, LL128 and lamport always push, so their names carry no mode:
  `<proto>[_<1shot|2shot>][_<variant>]` (`ll_1shot`, `lamport_1shot_warpsplit`).
  simple has both, so its names spell it: `simple_<pull|push>[_...]`
  (`simple_pull_2shot`, `simple_push_2shot`).
- `__global__` functions read `<op><algorithm><proto>[<mode>][<variant>]`, op
  `ar` / `ag` / `rs` / `arRms`, algorithm `OneShot` / `TwoShot`: `arOneShotLL128`,
  `arTwoShotSimplePush`, `arRmsOneShotLamportWarpSplit`, `rsSimplePullLastDim`.
  LL and LL128 are names: always upper case (`LLLine`, `kLL128SlotStride`)
  except as the lower-case start of a function name (`llStoreB128`).
- Launch configuration is a constructor argument:
  `Kernel("all_reduce_rmsnorm", "lamport_1shot_flat", block=128)`.

## Layout

```
csrc/
  include/opus/              aiter's opus (dtypes, vectors, casts)
  include/commkit/common.cuh arch-agnostic device helpers (casts, packed sums, warp reduce)
  include/commkit/host.hpp   launch-file helpers (dtype / world-size dispatch, pybind)
  runtime/runtime.cu         device memory + hipIpc handles
  gfx9/                      gfx942 / gfx950 (wave64)
    proto/                   arch.cuh simple.cuh ll.cuh ll128.cuh lamport.cuh
    epilogue/rmsnorm.cuh     the fused kernels' RMSNorm epilogues
    kernel/<type>/<mode>/<name>.cuh  device code of one kernel (mode: pull / push)
    kernel/<type>/<mode>/<name>.cu   its launch file = one JIT module: scratch_spec() + launch()
  gfx1250/                   same structure (wave32)
commkit/
  kernel.py                  commkit.Kernel
  registry.py                (arch family, type, name) -> op class
  ops/base.py                Op / PullOp / PushOp, run() of each kernel type, argument checks
  ops/<family>/<type>.py     one registered class per kernel
  jit.py buffer.py context.py arch.py
tests/                       pytest, one process per GPU
```

Python reads the GPU's arch at run time (`gcnArchName`) and only builds and
calls that family's kernels; `COMMKIT_ARCH` overrides it.

## Scratch

Every kernel owns its scratch, declared next to the kernel by its launch
file's `scratch_spec(max_bytes, world_size)` and allocated by the op class at
construction: IPC buffers (`hipIpcGetMemHandle` / `hipIpcOpenMemHandle`,
uncached where flags or inboxes are polled) and rank-local state (round
counters, epochs). Nothing is shared between kernels. `max_bytes` sizes the
scratch of most kernels (each class has a default); kernels whose layout is
compile-time export their capacity instead (`k.max_bytes`): on gfx9 LL128 and
lamport, on gfx1250 the LL kernels.

## Build

Modules build on first use into `build/jit/<arch>/<module>/` (ninja tracks
headers: editing any `.cuh` rebuilds exactly the modules that include it).
Prebuild everything for this GPU's arch in parallel:

```bash
python -m commkit                                   # all kernels of this arch
python -m commkit all_reduce/simple_pull_1shot      # some
```

Compiler flags match aiter's JIT, including `-DOPUS_FP32_to_BF16_DEFAULT=5`
(round-to-nearest-even bf16; opus otherwise truncates on gfx942).
Environment: `ROCM_PATH`, `COMMKIT_HIPCC`, `COMMKIT_JIT_DIR`, `COMMKIT_ARCH`.

## Tests

Plain python scripts, one per kernel type. Each spawns one process per GPU and,
by default, runs every kernel of this GPU's arch at TP 2 / 4 / 8: accuracy
(eager and CUDA graph, against an explicit reference) and latency (eager and
graph, us per call on the slowest rank), printed as tables. Arguments, what is
checked against what, and how to run are in each script's header.

```bash
python tests/test_all_reduce.py                      # every kernel, TP 2 / 4 / 8
python tests/test_all_reduce.py -t 8 -k lamport_1shot_warpsplit,ll_1shot -s 8k,64k
python tests/test_all_reduce_rmsnorm.py -t 8 -k "lamport_2shot:split=2" --no-acc
python tests/test_all_gather.py --no-perf            # accuracy only
python tests/test_reduce_scatter.py
python tests/test_api.py                             # registry, argument checks, input_buffer()
```

- all_reduce / all_gather / reduce_scatter: bit for bit against the rank-order
  fp32 sum (what every kernel computes) or `torch.cat`. all_reduce_rmsnorm:
  `residual_out` bit for bit, `out` within 2 ulp (64 for fp32) and identical on
  every rank, lamport kernels bit for bit against `simple_pull_1shot`. Lamport
  kernels also get 0xffff sentinel half-words in their input.
- Latency: eager is `run()` from python (pull kernels copy the input into their
  staging buffer, like aiter's eager path); graph replays the same calls (pull
  kernels read `input_buffer()`, like aiter's registered graph path). A graph
  slower than eager fails the run, as does a mismatch or a hang.
- `python -m pytest tests/` runs the same full defaults.
- Nothing uses RCCL: the tests run torch.distributed on gloo, and commkit
  exchanges its IPC handles through the process group's TCPStore, never through
  a collective, whatever backend the group has.

## Adding a kernel

1. `csrc/<family>/kernel/<type>/<pull|push>/<name>.cuh`: the `__global__`
   function (only device code; shared pieces come from `proto/` and
   `epilogue/`).
2. `csrc/<family>/kernel/<type>/<pull|push>/<name>.cu`: `scratch_spec()`,
   `launch()` (grid / block, dtype and world-size dispatch), `CK_MODULE`.
3. `commkit/ops/<family>/<type>.py`: a class with `@register(family, type,
   name)`, deriving from the type's base and `PullOp` / `PushOp` (that is the
   mode, the name's first word the proto), with `check_input()` and `launch()`.

The tests pick it up from the registry.

## gfx9 kernels

| type | name | aiter source | notes |
|---|---|---|---|
| all_reduce | `simple_pull_1shot` | cross_device_reduce_1stage | |
| | `simple_pull_1shot_naive` | cross_device_reduce_1stage_naive | vLLM original |
| | `simple_pull_2shot` | cross_device_reduce_2stage | size a multiple of 16 B x world size |
| | `simple_pull_2shot_naive` | cross_device_reduce_2stage_naive | |
| | `simple_push_2shot` | cross_device_reduce_2stage_write_mode | see differences below |
| | `ll_1shot` | ar_ll_gfx9 | `block` 256 / 512 / 1024 |
| | `ll128_1shot` | ar_ll128_unroll2 | fp16 / bf16, at most 4 MiB, `block` |
| | `lamport_1shot_warpsplit` | lamportAllReduceWaveSplit | fp16 / bf16, at most 640 KiB |
| | `lamport_2shot_warpsplit` | lamportAllReduceTwoShotWaveSplit | fp16 / bf16, at most 2 MiB |
| all_gather | `simple_pull` | allgather_vec / allgather_lastdim | 16-byte rows |
| | `simple_pull_naive` | allgather_naive | first dim, any size |
| reduce_scatter | `simple_pull` | reduce_scatter_split_{first,last,mid}_dim | 16-byte chunks |
| | `simple_pull_naive` | reduce_scatter_split_{last,mid}dim_naive | any shape |
| all_reduce_rmsnorm | `simple_pull_1shot` | allreduce_fusion_kernel_1stage | hidden <= 1024 packs |
| | `simple_pull_2shot` | allreduce_fusion_kernel_2stage | |
| | `simple_pull_2shot_split` | reduce_scatter_cross_device_store + local_device_load_rmsnorm | two launches |
| | `lamport_1shot_flat` | lamportArRmsFlat | `block` 0 (a row) / 64 / 128 / 256 |
| | `lamport_1shot_warpsplit` | lamportArRmsWaveSplit | `groups` 1 / 2 / 4 / 8 |
| | `lamport_2shot` | lamportArRmsTwoShot | `split` 1 / 2 / 4, at most 128 rows |

World sizes 2 / 4 / 8. The simple kernels take fp32 / fp16 / bf16.

### Differences from the aiter source

- `simple_push_2shot` keeps the gathered sums at a fixed tmp offset (the
  capacity) instead of `size`: nothing orders its stage 3 against the next
  call's stage 1, so with a size-dependent offset a peer's next, larger call
  overwrote sums this rank was still copying out (reproduced at TP8 when
  consecutive calls change size).
- `ll_1shot`'s epoch wraps to 2, not 1, so the double-buffer bank still
  alternates (as LL128 and gfx1250 LL already do).
- The fused kernels round their RMSNorm output through `pinFloat()`: for fp16
  the compiler otherwise fuses the last multiply and the conversion into
  `v_fma_mix*_f16` (one rounding, straight to fp16) in some kernels and not in
  others, which moved near-tie outputs by 1 ulp between kernels that are meant
  to match bit for bit. bf16 outputs are unchanged.
- Dropped: quantized outputs, padded hidden sizes, the registered-output
  broadcast of write mode, `num_norm_rows` / `skip_residual`, TP6.

## gfx1250 kernels

Ported from aiter PR #7927 (gfx1250 lamport all-reduce, on top of #7499,
#7555, #7432, #7861). **Not run yet:** ROCm 7.0.2 on the gfx942 development
machine cannot target gfx1250, so these kernels only passed a smoke compile
for gfx942 (the `__gfx1250__`-only instruction paths compiled out). Build and
test them on gfx1250 with `python -m commkit` and `python -m pytest tests/`.

| type | name | aiter source | notes |
|---|---|---|---|
| all_reduce | `simple_pull_1shot` | ar_gfx1250_naive_unroll4 | |
| | `ll_1shot` | ar_ll_gfx1250 | at most 4 MiB; `block` 512 / 1024, `unroll` 1 / 2 / 4 |
| | `ll_2shot` | ar_2s_ll_gfx1250 | TP4 / TP8, at most 8 MiB; `roles` 2 / 3, `width` |
| | `lamport_1shot` | lamport_ar_1shot_gfx1250 (ADD=false) | fp16 / bf16, default 8 MiB; `block` |
| | `lamport_2shot` | lamport_ar_2shot_gfx1250 | fp16 / bf16, default 32 MiB; `block` |
| all_gather | `simple_pull` | ag_gfx1250_naive_unroll4 / ag_gfx1250_lastdim | |
| | `simple_pull_vec` | ag_gfx1250_naive_vec | first dim |
| | `simple_pull_naive` | ag_gfx1250_scalar | first dim |
| | `ll` | ag_ll_gfx1250 | at most 4 MiB; `block` 256 / 512, `unroll` 1 / 2 |
| | `lamport` | lamport_ag_gfx1250, half-word sentinel codec | fp16 / bf16, default 8 MiB |
| | `lamport_escape` | lamport_ag_gfx1250, escape codec | any dtype, bit exact; adds an escape inbox |
| reduce_scatter | `simple_pull` / `simple_pull_naive` | rs_gfx1250_split_* | |
| all_reduce_rmsnorm | `simple_pull_1shot` | ar_rmsnorm_gfx1250 (one stage) | fp16 / bf16 |
| | `simple_pull_2shot` | sync + ar_rmsnorm_reduce_scatter_gfx1250 + sync + ar_rmsnorm_gfx1250 (two stage) | fp16 / bf16 |
| | `lamport_1shot` | lamport_ar_rmsnorm_gfx1250 | fp16 / bf16; `cluster` (needs a ROCm with cluster launch) |

Launch kwargs left at `None` take aiter's per-call choice for that kernel
(e.g. LL threads per block by message size); pass a value to pin it. Scratch
is per kernel and large at TP8 (an LL FIFO 128 MiB, `lamport_1shot`
192 MiB at its default size). Beyond renames: the escape inbox is its own
IPC buffer, the fused two-shot shard lives in the Signal's tmp region sized
from `max_bytes`, the cluster kernel's partial sums go through `uint32`
atomics (clang 20 rejects scoped atomics on `float*`), and the push
all-gathers reject an input that overlaps the output (aiter copied it).

