#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = 'Mengjuei Hsieh'
__doc__    = """Extremely dumb self-check, is in need to adopt algorithms
                from the engine."""

import sys
XXXXXXX = ['ㄕㄨ˙','ㄌㄧ˙','ㄒㄧ˙','ㄍㄨ˙','ㄊㄞ˙','ㄨㄚ˙',
           'ㄉㄧㄢ˙','ㄒㄧㄝ˙','ㄌㄡ˙','ㄋㄧㄤ˙','ㄌㄨ˙', 'ㄐㄧㄝ˙']

# TODO: move section of find highest score from the list to here

# end of TODO

def threeCharWalk(testbpmf, (targetP, targetS)):
    bpmfinput = testbpmf.split('-')
    candidate = []
    i = 0
    #
    mytest = '-'.join(bpmfinput[0:3])
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
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput:
            myscore = -9999.99
            mycand = ''
            if mybpmf not in phrases:
                print mybpmf
                print testbpmf
                sys.exit(0)
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
    if bpmfinput[0] not in XXXXXXX and '-'.join(bpmfinput[1:3]) in phrases:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        myscore = -9999.99
        mycand = ''
        if mybpmf not in phrases:
            print mybpmf
            print testbpmf
            sys.exit(0)
        for a,b in phrases[mybpmf]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        mytest = '-'.join(bpmfinput[1:3])
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
    if bpmfinput[2] not in XXXXXXX and '-'.join(bpmfinput[0:2]) in phrases:
        segcand = ''
        segscore = 0
        mytest = '-'.join(bpmfinput[0:2])
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        mybpmf = bpmfinput[2]
        myscore = -9999.99
        mycand = ''
        if mybpmf not in phrases:
            print mybpmf
            print testbpmf
            sys.exit(0)
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
    candidate.sort(key=lambda x: x[1], reverse=True)
    #for i in range(6):
    #    print '%s %f' % candidate[i]
    #sys.exit(0)
    if (targetP, targetS) == candidate[0]:
        pass
    else:
        (a, b) = candidate[0]
        print '%s %f %s %f' % (targetP, targetS, a, b)

def fourCharWalk(testbpmf, (targetP, targetS)):
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
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput:
            myscore = -9999.99
            mycand = ''
            if mybpmf not in phrases:
                print mybpmf
                print testbpmf
                sys.exit(0)
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
    if bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and mytest in phrases:
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
    if bpmfinput[0] not in XXXXXXX and bpmfinput[3] and '-'.join(bpmfinput[1:3]) in phrases:
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
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and '-'.join(bpmfinput[2:4]) in phrases:
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
    #
    if bpmfinput[0] not in XXXXXXX and '-'.join(bpmfinput[1:4]) in phrases:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mybpmf]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        mytest = '-'.join(bpmfinput[1:4])
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
    if bpmfinput[3] not in XXXXXXX and '-'.join(bpmfinput[0:3]) in phrases:
        segcand = ''
        segscore = 0
        mytest = '-'.join(bpmfinput[0:3])
        myscore = -9999.99
        mycand = ''
        for a,b in phrases[mytest]:
            if myscore < b:
                mycand = a
                myscore = b
        segcand += mycand
        segscore += myscore   
        mybpmf = bpmfinput[3]
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
    candidate.sort(key=lambda x: x[1], reverse=True)
    #for i in range(6):
    #    print '%s %f' % candidate[i]
    #sys.exit(0)
    if (targetP, targetS) == candidate[0]:
        pass
    else:
        (a, b) = candidate[0]
        print '%s %f %s %f' % (targetP, targetS, a, b)

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
        if len(phrases[mybpmf]) > 1:
            phrases[mybpmf].sort(key=lambda x: x[1], reverse=True)
        if len(mybpmf.split('-')) is 3:
            threeCharWalk(mybpmf,phrases[mybpmf][0])
            #print mybpmf
        if len(mybpmf.split('-')) is 4:
            fourCharWalk(mybpmf,phrases[mybpmf][0])
    #fourCharWalk(testbpmf)
