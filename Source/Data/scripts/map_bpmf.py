#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

bpmf = {}

if __name__ == '__main__':
    """
    A really lame bpmf mapping
    """
    # if len(sys.argv) < 5:
    #     sys.exit('Usage: cook.py phrase-freqs bpmf-mappings bpmf-base output')
    try:
        handle = open('heterophony1.list', "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': continue
        elements = line.rstrip().split()
        if elements[0] in bpmf:
            pass
        else:
            bpmf[elements[0]] = elements[1]
            # print bpmf[elements[0]]
    handle.close()
    try:
        handle = open('BPMFBase.txt', "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': continue
        elements = line.rstrip().split()
        if elements[0] in bpmf:
            pass
        else:
            bpmf[elements[0]] = elements[1]
            # print bpmf[elements[0]]
    handle.close()
    try:
        handle = open('cand.occ', "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': continue
        elements = line.rstrip().split()
        word = elements[0]
        i = 0
        phon = word
        while i < len(word):
            phon = "%s %s" % (phon, bpmf["%s" % (word[i])])
            i = i + 1
        print (phon)
    handle.close()
