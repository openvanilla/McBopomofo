#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys

UNK_LOG_FREQ = -99.0
H_DEFLT_FREQ = -6.8

bpmf_chars = {}
bpmf_phrases = {}
phrases = {}
bpmf_phon1 = {}
bpmf_phon2 = {}
bpmf_phon3 = {}
bpmf_hetero = {}

if __name__=='__main__':
    if len(sys.argv) < 5:
        sys.exit('Usage: cook.py phrase-freqs bpmf-mappings bpmf-base output')
    # Read a list of heterophonic singulars and its estimated frequency
    # not active yet
    #try:
    #    handle=open('heterophony.list',"r")
    #except IOError as e:
    #    print("({})".format(e))
    #while True:
    #    line = handle.readline()
    #    if not line: break
    #    if line[0] == '#': break
    #    elements = line.rstrip().split()
    #    myword = elements[0]
    #    myvalue = {elements[1], elements[2]}
    #    if myword in bpmf_hetero:
    #        bpmf_hetero[myword].append(myvalue)
    #    else:
    #        bpmf_hetero[myword] = []
    #        bpmf_hetero[myword].append(myvalue)
    #handle.close()
    # Reading-in a list of heterophonic words and
    # its most frequent pronunciation
    try:
        handle=open('heterophony1.list',"r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        #if elements[0] in bpmf_hetero: break
        bpmf_phon1[elements[0]] = elements[1]
    handle.close()
    try:
        handle=open('heterophony2.list',"r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        #if elements[0] in bpmf_hetero: break
        bpmf_phon2[elements[0]] = elements[1]
    handle.close()
    try:
        handle=open('heterophony3.list',"r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        #if elements[0] in bpmf_hetero: break
        bpmf_phon3[elements[0]] = elements[1]
    handle.close()
    #bpmfbase
    handle=open(sys.argv[3],"r")
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        mytype = elements[4]
        mykey = elements[0]
        myvalue = elements[1]
        #print mykey
        if mykey in bpmf_chars:
            bpmf_chars[mykey].append(myvalue)
        else:
            bpmf_chars[mykey] = []
            bpmf_chars[mykey].append(myvalue)
        if mykey in bpmf_phrases:
            bpmf_phrases[mykey].append(myvalue)
        else:
            bpmf_phrases[mykey] = []
            bpmf_phrases[mykey].append(myvalue)
    handle.close()
    #bpmf-mappings
    handle=open(sys.argv[2],"r")
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        mykey = elements.pop(0)
        myvalue = "-".join(elements)
        #print mykey
        #print myvalue
        if mykey in bpmf_phrases:
            bpmf_phrases[mykey].append(myvalue)
        else:
            bpmf_phrases[mykey] = []
            bpmf_phrases[mykey].append(myvalue)
    handle.close()
    #phrase-freqs
    handle=open(sys.argv[1],"r")
    fout=open(sys.argv[4],"w")
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        mykey = elements.pop(0)
        myvalue = elements.pop(0)
        readings = bpmf_phrases[mykey]
        phrases[mykey] = True
        #print mykey
        if readings:
            #剛好一個中文字字的長度目前還是 3 (標點、聲調好像都是2)       
            if len(mykey) > 3:
                for r in readings:
                    fout.write("%s %s %s\n" % ( mykey, r, myvalue ))
                    pass
                continue
            else:
                # lookup the table from canonical list
                for r in readings:
                    if not mykey in bpmf_phon1:
                        fout.write("%s %s %s\n" % ( mykey, r, myvalue ))
                        continue
                    elif str(bpmf_phon1[mykey]) == r:
                        fout.write("%s %s %s\n" % ( mykey, r, myvalue ))
                        continue
                    elif not mykey in bpmf_phon2:
                        fout.write("%s %s %f\n" % ( mykey, r, H_DEFLT_FREQ ))
                        continue
                    elif str(bpmf_phon2[mykey]) == r:
                        # l(3/4) = -0.28768207245178 / 頻率打七五折之意
                        if float(myvalue)-0.28768207245178 > H_DEFLT_FREQ:
                            fout.write("%s %s %f\n" % ( mykey, r, float(myvalue)-0.28768207245178 ))
                            continue
                        else:
                            fout.write("%s %s %f\n" % ( mykey, r, H_DEFLT_FREQ ))
                            continue
                    elif not mykey in bpmf_phon3:
                        fout.write("%s %s %f\n" % ( mykey, r, H_DEFLT_FREQ ))
                        continue
                    elif str(bpmf_phon3[mykey]) == r:
                        # l(3/4*3/4) = -0.28768207245178*2
                        if float(myvalue)-0.28768207245178*2 > H_DEFLT_FREQ:
                            fout.write("%s %s %f\n" % ( mykey, r, float(myvalue)-0.28768207245178*2 ))
                            continue
                        else:
                            fout.write("%s %s %f\n" % ( mykey, r, H_DEFLT_FREQ ))
                            continue
                    fout.write("%s %s %f\n" % ( mykey, r, H_DEFLT_FREQ ))
                    # 如果是破音字, set it to default.
                    # 很罕用的注音建議不要列入 heterophony?.list，這樣的話
                    # 就可以直接進來這個 condition
    handle.close()
    for k in bpmf_chars:
        if not k in phrases:
            for v in bpmf_chars[k]:
                fout.write("%s %s %f\n" % (k, v, UNK_LOG_FREQ))
                pass
    fout.close()
