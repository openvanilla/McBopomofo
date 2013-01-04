#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = 'Mengjuei Hsieh'
__doc__    = """Extremely dumb self-check, is in need to adopt algorithms
                from the engine."""

import sys
XXXXXXX = ['ㄕㄨ˙','ㄌㄧ˙','ㄒㄧ˙','ㄍㄨ˙','ㄊㄞ˙','ㄨㄚ˙',
           'ㄒㄧㄝ˙','ㄌㄡ˙','ㄌㄨ˙', 'ㄐㄧㄝ˙']
# 'ㄋㄧㄤ˙','ㄉㄧㄢ˙',

def segPick(mytest,segcand='',segscore=0):
    myscore = -9999.99
    mycand = ''
    for a,b in phrases[mytest]:
        if myscore < b:
            mycand = a
            myscore = b
    segcand += mycand
    segscore += myscore
    return (segcand, segscore)

def threeCharWalk(testbpmf, (targetP, targetS)):
    bpmfinput = testbpmf.split('-')
    candidate = []
    i = 0
    #123
    mytest = '-'.join(bpmfinput[0:3])
    if mytest in phrases:
        segcand = ''
        segscore = 0
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #1-2-3
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput:
            if mybpmf not in phrases:
                print mybpmf
                print testbpmf
                sys.exit(0)
            (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #1-23
    if bpmfinput[0] not in XXXXXXX and '-'.join(bpmfinput[1:3]) in phrases:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        if mybpmf not in phrases:
            print mybpmf
            print testbpmf
            sys.exit(0)
        (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        mytest = '-'.join(bpmfinput[1:3])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #12-3
    if bpmfinput[2] not in XXXXXXX and '-'.join(bpmfinput[0:2]) in phrases:
        segcand = ''
        segscore = 0
        mytest = '-'.join(bpmfinput[0:2])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        mybpmf = bpmfinput[2]
        if mybpmf not in phrases:
            print mybpmf
            print testbpmf
            sys.exit(0)
        (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]

    candidate.sort(key=lambda x: x[1], reverse=True)
    if (targetP, targetS) == candidate[0]:
        pass
    else:
        (a, b) = candidate[0]
        print '%s %f %s %f' % (targetP, targetS, a, b)

def fourCharWalk(testbpmf, (targetP, targetS)):
    bpmfinput = testbpmf.split('-')
    candidate = []
    i = 0
    #1234
    mytest = '-'.join(bpmfinput[0:4])
    if mytest in phrases:
        segcand = ''
        segscore = 0
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #1-2-3-4
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput:
            if mybpmf not in phrases:
                print mybpmf
                print testbpmf
                sys.exit(0)
            (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #12-3-4
    mytest = '-'.join(bpmfinput[0:2])
    if bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and mytest in phrases:
        segcand = ''
        segscore = 0
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        for mybpmf in bpmfinput[2:4]:
            (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #1-23-4
    if bpmfinput[0] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and '-'.join(bpmfinput[1:3]) in phrases:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput[0:1]:
            (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        mytest = '-'.join(bpmfinput[1:3])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        for mybpmf in bpmfinput[3:4]:
            (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #12-34
    if '-'.join(bpmfinput[0:2]) in phrases and '-'.join(bpmfinput[2:4]) in phrases:
        segcand = ''
        segscore = 0
        mytest = '-'.join(bpmfinput[0:2])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        mytest = '-'.join(bpmfinput[2:4])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #1-2-34
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and '-'.join(bpmfinput[2:4]) in phrases:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput[0:2]:
            (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        mytest = '-'.join(bpmfinput[2:4])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #1-234
    if bpmfinput[0] not in XXXXXXX and '-'.join(bpmfinput[1:4]) in phrases:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        mytest = '-'.join(bpmfinput[1:4])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]
    #123-4
    if bpmfinput[3] not in XXXXXXX and '-'.join(bpmfinput[0:3]) in phrases:
        segcand = ''
        segscore = 0
        mytest = '-'.join(bpmfinput[0:3])
        (segcand, segscore) = segPick(mytest,segcand,segscore)
        mybpmf = bpmfinput[3]
        (segcand, segscore) = segPick(mybpmf,segcand,segscore)
        candidate.append((segcand, segscore))
        i += 1
        #print '%s %f' % candidate[i]

    candidate.sort(key=lambda x: x[1], reverse=True)
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
    #mybpmf = 'ㄍㄨㄛˊ-ㄐㄧㄚ-ㄍㄨㄥ-ㄩㄢˊ'
    for mybpmf in phrases:
        if len(phrases[mybpmf]) > 1:
            phrases[mybpmf].sort(key=lambda x: x[1], reverse=True)
        if len(mybpmf.split('-')) is 3:
            threeCharWalk(mybpmf,phrases[mybpmf][0])
        if len(mybpmf.split('-')) is 4:
            fourCharWalk(mybpmf,phrases[mybpmf][0])
