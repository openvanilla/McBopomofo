#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import os
import codecs
import ConfigParser
import multiprocessing

__author__ = 'Mengjuei Hsieh'

__doc__ = """
   A facility to print a list of counts for substrings / phrases
   in a text pool file, given a list of phrases."""

config = ConfigParser.ConfigParser()
config.read('/'.join(os.path.abspath(sys.argv[0]).split('/')[:-1]) + '/textpool.rc')
corpus_path = config.get('data', 'corpus_path')
if corpus_path[0] == '~':
    corpus_path = os.path.expanduser(corpus_path)

# store the content of a text pool file in a global variable
# not ideal, but should be sufficient.
bigstring = ''
try:
    handle = codecs.open(corpus_path, encoding='utf-8', mode='r')
    bigstring = handle.read()
    handle.close()
except IOError as e:
    print("({})".format(e))
    raise e


# return a tuple of (substring, count, status)
def count_string(substring):
    if bigstring and substring:
        return substring, bigstring.count(substring), True
    return '', 0, False


if __name__ == '__main__':
    """
    bin/count.occurrence.py phrase.list > phrase.occ
    """
    import argparse
    max_cores = multiprocessing.cpu_count()

    parser = argparse.ArgumentParser()
    parser.add_argument("-j", metavar='<nproc>', type=int, help="specify number of simutaneous search thread")
    parser.add_argument("phraselist", help="file with one phrase per line, use - for standard input")
    args = parser.parse_args()

    allstrings = []

    if not args.j:
        pass
    elif max_cores >= args.j:
        max_cores = args.j
    else:
        pass
    ncores = max_cores
    if args.phraselist is '-':
        while True:
            try:
                line = raw_input().decode("utf-8")
                if not line: break
                if line[0] == '#': continue
                elements = line.rstrip().split()
                allstrings.append(elements[0])
            except (EOFError): break
    else:
        try:
            handle = codecs.open(args.phraselist, encoding='utf-8', mode='r')
        except IOError as e:
            print("({})".format(e))
        while True:
            line = handle.readline()
            if not line: break
            if line[0] == '#': continue
            elements = line.rstrip().split()
            allstrings.append(elements[0])
        handle.close()
    pool = multiprocessing.Pool(ncores)
    results = pool.map_async(count_string, allstrings).get(9999999)
    outputs = [(phrase, count) for phrase, count, state in results if state is True]
    for phrase, count in outputs:
        outstring = u'%s	%d' % (phrase, count)
        print outstring.encode('utf-8', 'ignore')
# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4
