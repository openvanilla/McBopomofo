#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
#uquery=unicode(sys.argv[1],"utf-8")
myCount=0
#f = codecs.open('/Volumes/ramdisk/newTEXT.txt', encoding='utf-8')
f = open('/Volumes/ramdisk/newTEXT.txt')
for line in f:
    #myCount=myCount+line.count(uquery)
    myCount=myCount+line.count(sys.argv[1])

print myCount
