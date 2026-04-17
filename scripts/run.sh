#!/usr/bin/env bash
# Launcher: spawn N child processes, each bound to a unique GPU, and set the
# env vars CommGroup expects.
#
# Usage:
#   scripts/run.sh <N> <executable> [args...]
#
# Example:
#   scripts/run.sh 8 ./build/kernels/allreduce_1stage/test_allreduce_1stage
#
# Each child gets RANK / LOCAL_RANK / WORLD_SIZE / MASTER_ADDR / MASTER_PORT.
# stdout/stderr from all ranks goes to the same terminal — ordering may
# interleave; rank 0 typically prints summary lines.
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <world_size> <executable> [args...]" >&2
    exit 1
fi

N=$1; shift
PORT=${MASTER_PORT:-29500}
ADDR=${MASTER_ADDR:-127.0.0.1}

pids=()
for ((r=0; r<N; r++)); do
    RANK=$r LOCAL_RANK=$r WORLD_SIZE=$N \
    MASTER_ADDR=$ADDR MASTER_PORT=$PORT \
        "$@" &
    pids+=($!)
done

# Forward signals so Ctrl-C cleanly tears down all children.
trap 'kill "${pids[@]}" 2>/dev/null || true' INT TERM

status=0
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        status=$?
    fi
done
exit $status
