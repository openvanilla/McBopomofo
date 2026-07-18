#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-/tmp/McBopomofoEngineProfilerBuild}"
NEON_BUILD_DIR="${NEON_BUILD_DIR:-$BUILD_DIR-NEON}"
OUTPUT_DIR="${OUTPUT_DIR:-$SOURCE_DIR/Engine/Report}"
PYTHON="${PYTHON:-python3}"
PROFILE_DURATION="${PROFILE_DURATION:-20}"
TRACE_TIME_LIMIT="${TRACE_TIME_LIMIT:-$((PROFILE_DURATION + 10))s}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Time Profiler requires macOS." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

make -C "$SOURCE_DIR/Data" "PYTHON=$PYTHON" all

profile_engine() {
    local result_name="$1"
    local build_dir="$2"
    local neon_enabled="$3"
    local trace_path="$OUTPUT_DIR/$result_name-$TIMESTAMP.trace"
    local target_log="$OUTPUT_DIR/$result_name-$TIMESTAMP.log"
    local profile_binary="$build_dir/Engine/EngineProfile"

    mkdir -p "$build_dir/Data"
    cp "$SOURCE_DIR/Data/data.txt" "$build_dir/Data/data.txt"
    cmake \
        -S "$SOURCE_DIR" \
        -B "$build_dir" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DENABLE_TEST=OFF \
        -DENABLE_ENGINE_PROFILE=ON \
        -DENABLE_EXPERIMENTAL_SIMD_SUPPORT_NEON="$neon_enabled"
    cmake --build "$build_dir" --target EngineProfile -j

    xcrun xctrace record \
        --template "Time Profiler" \
        --time-limit "$TRACE_TIME_LIMIT" \
        --output "$trace_path" \
        --target-stdout "$target_log" \
        --no-prompt \
        --launch \
        -- "$profile_binary" "$PROFILE_DURATION"

    local scenario
    for scenario in short medium long; do
        if ! grep -q "^${scenario}_iterations=" "$target_log"; then
            echo "Profiling workload did not complete successfully. See: $target_log" >&2
            exit 1
        fi
    done

    echo "Time Profiler trace: $trace_path"
}

profile_engine "engine" "$BUILD_DIR" OFF
profile_engine "engine-neon" "$NEON_BUILD_DIR" ON
