#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys

__author__ = 'Mengjuei Hsieh'
__doc__    = """Extremely dumb self-check, is in need to adopt algorithms
                from the engine."""

XXXXXXX = ['ㄕㄨ˙', 'ㄌㄧ˙', 'ㄒㄧ˙', 'ㄍㄨ˙', 'ㄊㄞ˙', 'ㄨㄚ˙', 'ㄋㄞ˙',
           'ㄒㄧㄝ˙', 'ㄌㄡ˙', 'ㄌㄨ˙', 'ㄐㄧㄝ˙', 'ㄉㄧ˙', 'ㄍㄨㄥ˙',
           'ㄌㄠ˙']


def segPick(thisbpmf, segcand='', segscore=0):
    myscore = -9999.99
    mycand = ''
    if thisbpmf not in phrases:
        print thisbpmf
        sys.exit(1)
    for a, b in phrases[thisbpmf]:
        if myscore < b:
            mycand = a
            myscore = b
    segcand += mycand
    segscore += myscore
    return (segcand, segscore)


def twoCharWalk(bpmf2walk):
    bpmfinput = bpmf2walk.split('-')
    candidate = []
    # 1-2
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX:
        segcand = ''
        segscore = 0
        for mybpmf in bpmfinput:
            if mybpmf not in phrases:
                print mybpmf
                print bpmf2walk
                sys.exit(0)
            (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 12
    thisbpmf = '-'.join(bpmfinput[0:2])
    if thisbpmf in phrases:
        segcand = ''
        segscore = 0
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    if candidate == []:
        print bpmf2walk
        sys.exit()
    return candidate[0]


def threeCharWalk(bpmf2walk):
    bpmfinput = bpmf2walk.split('-')
    candidate = []
    # 1-2-3 and 1-23
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        if mybpmf not in phrases:
            print mybpmf
            print bpmf2walk
            sys.exit(0)
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[1:3])
        (a, b) = twoCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123
    thisbpmf = '-'.join(bpmfinput[0:3])
    if thisbpmf in phrases:
        segcand = ''
        segscore = 0
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 12-3
    if bpmfinput[2] not in XXXXXXX and '-'.join(bpmfinput[0:2]) in phrases:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:2])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[2]
        if mybpmf not in phrases:
            print mybpmf
            print bpmf2walk
            sys.exit(0)
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def fourCharWalk(bpmf2walk):
    bpmfinput = bpmf2walk.split('-')
    candidate = []
    # 1-2-3-4, 1-23-4, 1-2-34, 1-234
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[1:4])
        (a, b) = threeCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12-3-4, 12-34
    if bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and '-'.join(bpmfinput[0:2]) in phrases:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:2])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[2:4])
        (a, b) = twoCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123-4
    if bpmfinput[3] not in XXXXXXX and '-'.join(bpmfinput[0:3]) in phrases:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:3])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[3]
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 1234
    thisbpmf = '-'.join(bpmfinput[0:4])
    if thisbpmf in phrases:
        segcand = ''
        segscore = 0
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def fiveCharWalk(bpmf2walk):
    bpmfinput = bpmf2walk.split('-')
    candidate = []
    # 1-2345(expand)
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and bpmfinput[4] not in XXXXXXX:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[1:5])
        (a, b) = fourCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12-345(expand)
    if '-'.join(bpmfinput[0:2]) in phrases and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and bpmfinput[4] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:2])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[2:5])
        (a, b) = threeCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123-45(expand)
    if '-'.join(bpmfinput[0:3]) in phrases and bpmfinput[3] not in XXXXXXX and bpmfinput[4] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:3])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[3:5])
        (a, b) = twoCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 1234-5
    if '-'.join(bpmfinput[0:4]) in phrases and bpmfinput[4] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:4])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[4]
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 12345
    if '-'.join(bpmfinput[0:5]) in phrases:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:5])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def sixCharWalk(bpmf2walk):
    bpmfinput = bpmf2walk.split('-')
    candidate = []
    # 1-23456(exp)
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and bpmfinput[4] not in XXXXXXX and bpmfinput[5] not in XXXXXXX:
        segcand = ''
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[1:6])
        (a, b) = fourCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12-3456(exp)
    if '-'.join(bpmfinput[0:2]) in phrases and bpmfinput[2] not in XXXXXXX and bpmfinput[3] not in XXXXXXX and bpmfinput[4] not in XXXXXXX and bpmfinput[5] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:2])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[2:6])
        (a, b) = threeCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123-456(exp)
    if '-'.join(bpmfinput[0:3]) in phrases and bpmfinput[3] not in XXXXXXX and bpmfinput[4] not in XXXXXXX and bpmfinput[5] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:3])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[3:6])
        (a, b) = threeCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 1234-56(exp)
    if '-'.join(bpmfinput[0:4]) in phrases and bpmfinput[4] not in XXXXXXX and bpmfinput[5] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:4])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        thisbpmf = '-'.join(bpmfinput[4:6])
        (a, b) = twoCharWalk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12345-6
    if '-'.join(bpmfinput[0:5]) in phrases and bpmfinput[5] not in XXXXXXX:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:5])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[5]
        (segcand, segscore) = segPick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 123456
    if '-'.join(bpmfinput[0:6]) in phrases:
        segcand = ''
        segscore = 0
        thisbpmf = '-'.join(bpmfinput[0:6])
        (segcand, segscore) = segPick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def chkBPMFoutput(phrases, bpmf2chk):
    if len(bpmf2chk.split('-')) is 2:
        (a, b) = twoCharWalk(bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print '%s %f %s %f' % (c, d, a, b)
    if len(bpmf2chk.split('-')) is 3:
        (a, b) = threeCharWalk(bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print '%s %f %s %f' % (c, d, a, b)
    if len(bpmf2chk.split('-')) is 4:
        (a, b) = fourCharWalk(bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print '%s %f %s %f' % (c, d, a, b)
    if len(bpmf2chk.split('-')) is 5:
        (a, b) = fiveCharWalk(bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print '%s %f %s %f' % (c, d, a, b)
    if len(bpmf2chk.split('-')) is 6:
        (a, b) = sixCharWalk(bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print '%s %f %s %f' % (c, d, a, b)


if __name__ == '__main__':
    phrases = {}
    try:
        handle = open('data.txt', "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': continue
        if '_' in line: continue
        elements = line.rstrip().split()
        if len(elements[1].split('-')) > 6: continue
        if elements[1] not in phrases:
            phrases[elements[1]] = []
        phrases[elements[1]].append((elements[0], float(elements[2])))
    handle.close()
    # mybpmf = 'ㄍㄨㄛˊ-ㄐㄧㄚ-ㄍㄨㄥ-ㄩㄢˊ'
    for mybpmf in phrases:
        if len(phrases[mybpmf]) > 1:
            phrases[mybpmf].sort(key=lambda x: x[1], reverse=True)
        chkBPMFoutput(phrases, mybpmf)
