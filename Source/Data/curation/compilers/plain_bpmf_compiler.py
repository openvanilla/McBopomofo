#!/usr/bin/env python3
"""
Plain BPMF compiler for traditional Bopomofo input method mode.

Generates data-plain-bpmf.txt from base character mappings and punctuation,
with uniform zero scores for all entries.
"""

import re
import sys

from .compiler_utils import HEADER, convert_vks_rows_to_sorted_kvs_rows

__author__ = "Lukhnos Liu and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

# Skip punctuation entries matching this pattern
SKIP_PATTERN = re.compile("．\s+_punctuation.*_>")

# Insert this special punctuation entry
INSERT_ENTRY = ["．", '_punctuation_"', "0.0"]


def load_bpmf_base(file_path: str) -> list[tuple[str, str, str]]:
    """
    Load base BPMF character mappings with zero scores.

    Args:
        file_path: Path to BPMFBase.txt file

    Returns:
        List of (character, reading, score) tuples with 0.0 scores
    """
    output: list[tuple[str, str, str]] = []

    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line:
                continue

            kv = line.split(" ")
            if len(kv) >= 2:
                output.append((kv[0], kv[1], "0.0"))

    return output


def load_punctuation(file_path: str) -> list[tuple[str, str, str]]:
    """
    Load punctuation mappings, skipping certain entries.

    Args:
        file_path: Path to punctuation list file

    Returns:
        List of (punctuation, reading, score) tuples
    """
    output: list[tuple[str, str, str]] = []

    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line:
                continue

            # Skip entries matching the pattern
            if SKIP_PATTERN.search(line):
                continue

            row = line.rstrip().split(" ")
            if len(row) == 3:
                output.append(tuple(row))

    return output


def main() -> None:
    """Main entry point for plain BPMF compiler."""
    if len(sys.argv) < 4:
        sys.exit("Usage: cook-plain-bpmf.py bpmf-base punctuation-list output")

    bpmf_base_path = sys.argv[1]
    punctuation_path = sys.argv[2]
    output_path = sys.argv[3]

    # Load base character mappings
    output = load_bpmf_base(bpmf_base_path)

    # Load and append punctuation
    punctuation = load_punctuation(punctuation_path)
    output.extend(punctuation)

    # Add special insert entry
    output.append(tuple(INSERT_ENTRY))

    # Convert and sort output
    output = convert_vks_rows_to_sorted_kvs_rows(output)

    # Write output file
    with open(output_path, "w", encoding="utf-8") as fout:
        fout.write(HEADER)
        for row in output:
            fout.write(f"{row[0]} {row[1]} {row[2]}\n")


if __name__ == "__main__":
    main()
