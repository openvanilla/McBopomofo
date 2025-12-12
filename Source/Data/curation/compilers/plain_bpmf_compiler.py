#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from .compiler_utils import HEADER, convert_vks_rows_to_sorted_kvs_rows
import argparse
import re
import sys

__author__ = "Lukhnos Liu and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

skip = re.compile(r"．\s+_punctuation.*_>")

insert = ["．", '_punctuation_"', "0.0"]


def cook(bpmf_base_path, punctuations_path, output_path):
    bpmf_base = open(bpmf_base_path, "r")
    punctuation_list = open(punctuations_path, "r")
    output = []

    while True:
        line = bpmf_base.readline()
        if not line:
            break
        kv = line.split(" ")
        output.append((kv[0], kv[1], "0.0"))

    while True:
        line = punctuation_list.readline()
        if not line:
            break
        if skip.search(line):
            continue
        row = line.rstrip().split(" ")
        assert len(row) == 3
        output.append(row)

    output.append(insert)

    output = convert_vks_rows_to_sorted_kvs_rows(output)
    with open(output_path, "w") as fout:
        fout.write(HEADER)
        for row in output:
            fout.write("%s %s %s\n" % tuple(row))


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
