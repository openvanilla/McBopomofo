#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import codecs
import multiprocessing

__author__ = 'Mengjuei Hsieh'
__doc__    = """
   A facility to print a list of counts for substrings / phrases
   in a text pool file, given a list of phrases."""

# store the content of a text pool file in a global variable
# not ideal, but should be sufficient.
bigstring = ''
try:
    handle = codecs.open('/Volumes/ramdisk/textpool.01202013', encoding='utf-8', mode='r')
except IOError as e:
    print("({})".format(e))
bigstring=handle.read()
handle.close()

# return a tuple of (substring, count, status)
def count_string(substring):
    if bigstring and substring:
        return substring, bigstring.count(substring), True
    return '', 0, False

def my_open(filename, mode): 
    return codecs.open(filename, mode, 'utf8') 

if __name__=='__main__':
    """
    bin/count.occurrence.py phrase.list > phrase.occ
    """
    max_cores = multiprocessing.cpu_count()
    ncores    = max_cores
    if sys.argv[1] is '-':
        allstrings = []
        while True:
            try:
                line = raw_input().decode("utf-8")
                if not line: break
                if line[0] == '#': continue
                elements = line.rstrip().split()
                allstrings.append(elements[0])
            except (EOFError):
                break
    else:
        try:
            handle = codecs.open(sys.argv[1], encoding='utf-8', mode='r')
        except IOError as e:
            print("({})".format(e))
        allstrings = []
        while True:
            line = handle.readline()
            if not line: break
            if line[0] == '#': continue
            elements = line.rstrip().split()
            allstrings.append(elements[0])
        handle.close()
    pool = multiprocessing.Pool(ncores)
    results = pool.map_async(count_string,allstrings).get(9999999)
    outputs = [ (phrase, count) for phrase, count, state in results if state is True]
    for phrase, count in outputs:
        outstring = u'%s	%d' % (phrase,count)
        print outstring.encode('utf-8', 'ignore')
