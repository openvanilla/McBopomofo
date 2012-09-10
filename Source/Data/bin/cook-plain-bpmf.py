#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import re

skip = re.compile("．\s+_punctuation.*_>")
insert = "． _punctuation_\" 0.0\n"

if len(sys.argv) < 4:
	sys.exit('Usage: cook-plain-bpmf.py bpmf-base punctuation-list output')

bpmf_base = open(sys.argv[1], "r")
punctuation_list = open(sys.argv[2], "r")
output = open(sys.argv[3], "w")

while True:
	line = bpmf_base.readline()
	if not line:
		break

	kv = line.split(" ")
	output.write("%s %s 0.0\n" % (kv[0], kv[1]))

while True:
	line = punctuation_list.readline()
	if not line:
		break

	if skip.search(line):
		continue
	
	output.write(line)

output.write(insert)
