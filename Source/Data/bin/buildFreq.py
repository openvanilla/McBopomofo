#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import math

__author__ = 'Mengjuei Hsieh'

norm      = 0.0
fscale    = 2.7
phrases   = {}
exclusion = {}

if __name__ == '__main__':
    if len(sys.argv) > 1:
        sys.exit('This command does not take any argument')

    try:
        handle = open('phrase.occ', "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == '#':
            continue
        elements = line.rstrip().split()
        phrases[elements[0]] = int(elements[1])
    handle.close()

    try:
        handle = open('exclusion.txt', "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == '#':
            continue
        elements = line.rstrip().split()
        mykey = elements[0]
        myval = elements[1]
        if myval.count(mykey) < 1:
            continue
        # print "%s %s" % (elements[0], elements[1])
        if mykey in exclusion:
            exclusion[mykey].append(myval)
        else:
            exclusion[mykey] = []
            exclusion[mykey].append(myval)
    handle.close()

    # eg: if BC and ABC are not related ( BC is meaningless when ABC occurs)
    #     then count(BC) = count(BC) - count(ABC)
    for k in exclusion:
        for v in exclusion[k]:
            if k in phrases and v in phrases:
                phrases[k] = phrases[k]-phrases[v]

    # Getting a hint from algorithm of Max-match segmentation
    # norm = sum ( fscale^(len(phrase)-1) * count(phrase) )
    for k in phrases:
        norm += fscale**(len(k)/3-1)*phrases[k]

    try:
        handle = open('PhraseFreq.txt', "w")
    except IOError as e:
        print("({})".format(e))
    for k in phrases:
        # if it's zero count, we treat it as a 0.5 count.
        if phrases[k] < 1:
            handle.write('%s %.8f\n' % (k, math.log(fscale**(len(k)/3-1)*0.5       /norm, 10)))
        else:
            handle.write('%s %.8f\n' % (k, math.log(fscale**(len(k)/3-1)*phrases[k]/norm, 10)))
    handle.close()
