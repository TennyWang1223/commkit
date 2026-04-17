# commkit

轻量级 GPU 通信算子开发库，面向 ROCm/HIP（MI3xx 系 gfx942），纯 C++、0 Python。

设计目标：

- **kernel 调用尽量原始**：通信组准备好 `RankData* / Signal* / RankSignals` 后，test 直接 `<<<grid, block, 0, stream>>>` launch，不做条件判断、不做 dispatch。
- **通信组使用尽量精简**：`CommGroup g(world_size); g.init();` 两行起步，IPC handle 交换走内置 TCP store，无需 torch / MPI。
- **每个 kernel 一个独立子项目**：自带 `CMakeLists.txt` + `kernel.cuh` + `test.cpp`，能脱离主项目独立编译/运行。

## 目录结构

```
commkit/
├── CMakeLists.txt              顶层，聚合所有 kernel
├── cmake/CommkitKernel.cmake   add_commkit_kernel() helper
├── scripts/run.sh              起 N 个子进程，设 RANK/WORLD_SIZE/MASTER_*
├── include/
│   ├── opus/                   opus 数据类型 (bf16_t / vector_t 等)
│   └── commkit/                signal / sync / cast / tmp_buf / bench / ...
├── src/                        comm_group / ipc_buffer / tcp_store
└── kernels/
    ├── allreduce_1stage/       kernel 子项目
    └── allreduce_2stage/
```

## 依赖

- ROCm 7.x（路径默认 `/opt/rocm`，编译器 `amdclang++`）
- CMake ≥ 3.21

## 编译

### 全部算子（顶层）

```bash
cd commkit
cmake -B build
cmake --build build -j
```

产物：`build/kernels/<name>/test_<name>` + 同目录下的 `run.sh`。

### 单算子（独立编译）

每个 kernel 子目录都能独立 `cmake`，会自动 bootstrap 依赖的 `commkit_core`，且不会编译其它 kernel：

```bash
cd commkit/kernels/allreduce_1stage
cmake -B build
cmake --build build -j
```

产物：`build/test_allreduce_1stage` + 同目录下的 `run.sh`。

## 运行

`run.sh` 会在编译后自动拷贝到可执行文件旁边，直接：

```bash
cd build/kernels/allreduce_1stage   # 或单算子的 build 目录
./run.sh 8 ./test_allreduce_1stage
```

第一个参数是 rank 数。每个 rank 自己打印一行 latency / max_abs_err。
