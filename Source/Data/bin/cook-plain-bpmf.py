#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from cook_util import HEADER, convert_vks_rows_to_sorted_kvs_rows
import re
import sys

skip = re.compile("．\s+_punctuation.*_>")

insert = ["．",  "_punctuation_\"", "0.0"]

if len(sys.argv) < 4:
    sys.exit('Usage: cook-plain-bpmf.py bpmf-base punctuation-list output')

bpmf_base = open(sys.argv[1], "r")
punctuation_list = open(sys.argv[2], "r")
output = []

while True:
    line = bpmf_base.readline()
    if not line: break
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
with open(sys.argv[3], "w") as fout:
    fout.write(HEADER)
    for row in output:
        fout.write("%s %s %s\n" % tuple(row))
