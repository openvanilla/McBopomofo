#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from .compiler_utils import HEADER, convert_vks_rows_to_sorted_kvs_rows
import argparse
import re

__author__ = "Lukhnos Liu and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

# Punctuation fix for Plain Bopomofo mode
SKIP_RE = re.compile(r"．\s+_punctuation.*_>")
PUNCTUATION_FIX = ["．", '_punctuation_"', "0.0"]


def cook(bpmf_base_path, punctuations_path, output_path):
    output = []

    with open(bpmf_base_path, "r") as bpmf_base:
        for line in bpmf_base:
            line = line.strip()
            if not line:
                continue
            elements = line.split(" ")
            assert len(elements) >= 2
            output.append((elements[0], elements[1], "0.0"))

    with open(punctuations_path, "r") as punctuation_list:
        for line in punctuation_list:
            if SKIP_RE.search(line):
                continue
            row = line.rstrip().split(" ")
            assert len(row) == 3
            output.append(row)

    output.append(PUNCTUATION_FIX)

    output = convert_vks_rows_to_sorted_kvs_rows(output)
    with open(output_path, "w") as output_file:
        output_file.write(HEADER)
        for row in output:
            output_file.write("%s %s %s\n" % tuple(row))


def main():
    parser = argparse.ArgumentParser(
        description="compile plain Bopomofo phrases database"
    )
    parser.add_argument("--bpmf_base", required=True)
    parser.add_argument("--punctuations", required=True)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()
    cook(
        bpmf_base_path=args.bpmf_base,
        punctuations_path=args.punctuations,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
