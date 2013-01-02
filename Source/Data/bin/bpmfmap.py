#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = 'Mengjuei Hsieh'
import sys
bpmf = {}

if __name__=='__main__':
    """
    A really lame bpmf mapping
    """
    #if len(sys.argv) < 5:
    #    sys.exit('Usage: cook.py phrase-freqs bpmf-mappings bpmf-base output')
    try:
        handle=open('heterophony1.list',"r")
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
            #print bpmf[elements[0]]
    handle.close()
    try:
        handle=open('BPMFBase.txt',"r")
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
            #print bpmf[elements[0]]
    handle.close()
    try:
        handle=open('cand.occ',"r")
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
            phon = "%s %s" % (phon,bpmf["%s%s%s" % (word[i],word[i+1],word[i+2])])
            i = i+3
        print phon
    handle.close()
