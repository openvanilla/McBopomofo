#!/usr/bin/env bash
# PostToolUse hook: auto-format C++/ObjC files with clang-format after edits.
# Reads the tool input JSON from stdin to extract the edited file path.

set -euo pipefail

# Read stdin JSON and extract file_path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only format C++/ObjC source files
case "$FILE_PATH" in
  *.cpp|*.h|*.mm|*.m)
    if [[ -f "$FILE_PATH" ]]; then
      xcrun clang-format -i "$FILE_PATH"
    fi
    ;;
esac
