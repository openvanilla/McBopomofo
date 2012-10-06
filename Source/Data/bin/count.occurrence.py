#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import codecs

if __name__=='__main__':
    """
    """
    bigstring = ''
    try:
        handle = codecs.open('/Volumes/ramdisk/textpool.02282012', encoding='utf-8', mode='r')
    except IOError as e:
        print("({})".format(e))
    bigstring=handle.read()
    handle.close()
    try:
        handle = codecs.open(sys.argv[1], encoding='utf-8', mode='r')
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': continue
        elements = line.rstrip().split()
        #myph = elements[0]
        #mycnt = bigstring.count(myph)
        outstring = u'%s	%d' % (elements[0],bigstring.count(elements[0]))
        print outstring.encode('utf-8', 'ignore')
    handle.close()
