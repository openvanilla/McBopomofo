"""Compile plain BPMF data with uniform zero scores for traditional input mode."""

import re
import sys

from .compiler_utils import HEADER, convert_vks_rows_to_sorted_kvs_rows

__author__ = "Lukhnos Liu and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

SKIP_PATTERN = re.compile(r"．\s+_punctuation.*_>")
INSERT_ENTRY = ["．", '_punctuation_"', "0.0"]


def load_bpmf_base(file_path: str) -> list[tuple[str, str, str]]:
    """Load base BPMF character mappings with zero scores."""
    output = []
    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line:
                continue
            kv = line.split(" ")
            if len(kv) >= 2:
                output.append((kv[0], kv[1], "0.0"))
    return output


def load_punctuation(file_path: str) -> list[tuple[str, str, str]]:
    """Load punctuation mappings, skipping entries matching SKIP_PATTERN."""
    output = []
    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line:
                continue
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

    output = load_bpmf_base(bpmf_base_path)
    punctuation = load_punctuation(punctuation_path)
    output.extend(punctuation)
    output.append(tuple(INSERT_ENTRY))
    output = convert_vks_rows_to_sorted_kvs_rows(output)

    with open(output_path, "w", encoding="utf-8") as fout:
        fout.write(HEADER)
        for row in output:
            fout.write(f"{row[0]} {row[1]} {row[2]}\n")


if __name__ == "__main__":
    main()
