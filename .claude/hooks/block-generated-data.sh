#!/usr/bin/env bash
# PreToolUse hook: block direct edits to generated dictionary data files.
# These files are produced by the dictionary compiler and must not be edited manually.
# Exit code 2 blocks the tool from executing.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Reject paths with newlines or path traversal
if [[ "$FILE_PATH" =~ $'\n' ]] || [[ "$FILE_PATH" == *".."* ]]; then
  exit 2
fi

# Block generated data files in Source/Data/
case "$FILE_PATH" in
  */Source/Data/data.txt|*/Source/Data/data-plain-bpmf.txt|*/Source/Data/associated-phrases-v2.txt)
    echo "Blocked: $FILE_PATH is a generated file. Edit the source and rebuild instead." >&2
    exit 2
    ;;
esac
