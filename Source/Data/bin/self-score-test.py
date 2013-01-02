#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = 'Mengjuei Hsieh'
__doc__    = """Extremely dumb self-check, is in need to adopt algorithms
                from the engine."""

import sys
XXXXXXX = ['ㄕㄨ˙']

# TODO: move section of find highest score from the list to here

# end of TODO

def fourCharWalk(testbpmf):
    bpmfinput = testbpmf.split('-')
    candidate = []
    i = 0
    #
    mytest = '-'.join(bpmfinput[0:4])
    if mytest in phrases:
        segcand = ''
        segscore = 0
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        candidate.append((segcand, segscore))
        #print '%s %f' % candidate[i]
        i += 1
    #
    if bpmfinput[0] in XXXXXXX and bpmfinput[1] in XXXXXXX and bpmfinput[2] in XXXXXXX and bpmfinput[3] in XXXXXXX:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput:
            myscore = -9999.99
            mycand = ''
            for a,b in phrases[mybpmf]:
                if myscore < b:
                    mycand = a
                    myscore = b
            segcand += mycand
            segscore += myscore   
        candidate.append((segcand, segscore))
        #print '%s %f' % candidate[i]
        i += 1
    #
    mytest = '-'.join(bpmfinput[0:2])
    if bpmfinput[2] in XXXXXXX and bpmfinput[3] in XXXXXXX and mytest in phrases:
        segcand = ''
        segscore = 0
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        for mybpmf in bpmfinput[2:4]:
            myscore = -9999.99
            mycand = ''
            for a,b in phrases[mybpmf]:
                if myscore < b:
                    mycand = a
                    myscore = b
            segcand += mycand
            segscore += myscore   
        candidate.append((segcand, segscore))
        #print '%s %f' % candidate[i]
        i += 1
    #
    if bpmfinput[0] in XXXXXXX and bpmfinput[3] and '-'.join(bpmfinput[1:3]) in phrases:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput[0:1]:
            myscore = -9999.99
            mycand = ''
            for a,b in phrases[mybpmf]:
                if myscore < b:
                    mycand = a
                    myscore = b
            segcand += mycand
            segscore += myscore   
        myscore = -9999.99
        mycand = ''
        mytest = '-'.join(bpmfinput[1:3])
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        for mybpmf in bpmfinput[3:4]:
            myscore = -9999.99
            mycand = ''
            for a,b in phrases[mybpmf]:
                if myscore < b:
                    mycand = a
                    myscore = b
            segcand += mycand
            segscore += myscore   
        candidate.append((segcand, segscore))
        #print '%s %f' % candidate[i]
        i += 1
    #
    segcand = ''
    segscore = 0
    if '-'.join(bpmfinput[0:2]) in phrases and '-'.join(bpmfinput[2:4]) in phrases:
        mytest = '-'.join(bpmfinput[0:2])
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        mytest = '-'.join(bpmfinput[2:4])
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        candidate.append((segcand, segscore))
        #print '%s %f' % candidate[i]
        i += 1
    #
    if bpmfinput[0] in XXXXXXX and bpmfinput[1] in XXXXXXX and '-'.join(bpmfinput[2:4]) in phrases:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput[0:2]:
            myscore = -9999.99
            mycand = ''
            for a,b in phrases[mybpmf]:
                if myscore < b:
                    mycand = a
                    myscore = b
            segcand += mycand
            segscore += myscore   
        mytest = '-'.join(bpmfinput[2:4])
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        candidate.append((segcand, segscore))
        #print '%s %f' % candidate[i]
        i += 1
    candidate.sort(key=lambda x: x[1], reverse=True)
    #for i in range(6):
    #    print '%s %f' % candidate[i]
    #sys.exit(0)
    print '%s %f' % candidate[0]

if __name__=='__main__':
    phrases  = {}
    try:
        handle=open('data.txt',"r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': continue
        elements = line.rstrip().split()
        if len(elements[1].split('-')) > 4: continue
        if elements[1] not in phrases:
            phrases[elements[1]] = []
        phrases[elements[1]].append((elements[0], float(elements[2])))
    handle.close()
    #testbpmf = 'ㄍㄨㄛˊ-ㄐㄧㄚ-ㄍㄨㄥ-ㄩㄢˊ'
    for mybpmf in phrases:
        if len(mybpmf.split('-')) is not 4: continue
        if len(phrases[mybpmf]) > 1:
            phrases[mybpmf].sort(key=lambda x: x[1], reverse=True)
        sys.stdout.write('%s %f ' % phrases[mybpmf][0])
        fourCharWalk('%s' % mybpmf)
    #fourCharWalk(testbpmf)
