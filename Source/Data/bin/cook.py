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


if __name__=='__main__':
    if len(sys.argv) < 5:
        sys.exit('Usage: cook.py phrase-freqs bpmf-mappings bpmf-base output')
    handle=open('heterophony1.list',"r")
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        bpmf_phon1[elements[0]] = elements[1]
    handle.close()
    handle=open('heterophony2.list',"r")
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
        bpmf_phon2[elements[0]] = elements[1]
    handle.close()
    handle=open('heterophony3.list',"r")
    while True:
        line = handle.readline()
        if not line: break
        if line[0] == '#': break
        elements = line.rstrip().split()
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
    handle=open(sys.argv[1],"r")
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
                    print "%s %s %s" % ( mykey, r, myvalue )
                    pass
                continue
            else:
                for r in readings:
                    if not mykey in bpmf_phon1:
                        print "%s %s %s" % ( mykey, r, myvalue )
                        continue
                    elif str(bpmf_phon1[mykey]) == r:
                        print "%s %s %s" % ( mykey, r, myvalue )
                        continue
                    elif not mykey in bpmf_phon2:
                        print "%s %s %f" % ( mykey, r, H_DEFLT_FREQ )
                        continue
                    elif str(bpmf_phon2[mykey]) == r:
                        if float(myvalue)-0.28768207245178 > H_DEFLT_FREQ:
                            print "%s %s %f" % ( mykey, r, float(myvalue)-0.28768207245178 )
                            continue
                        else:
                            print "%s %s %f" % ( mykey, r, H_DEFLT_FREQ )
                            continue
                    elif not mykey in bpmf_phon3:
                        print "%s %s %f" % ( mykey, r, H_DEFLT_FREQ )
                        continue
                    elif str(bpmf_phon3[mykey]) == r:
                        if float(myvalue)-0.28768207245178*2 > H_DEFLT_FREQ:
                            print "%s %s %f" % ( mykey, r, float(myvalue)-0.28768207245178*2 )
                            continue
                        else:
                            print "%s %s %f" % ( mykey, r, H_DEFLT_FREQ )
                            continue
                    print "%s %s %f" % ( mykey, r, H_DEFLT_FREQ )
    handle.close()
    for k in bpmf_chars:
        if not k in phrases:
            for v in bpmf_chars[k]:
                print "%s %s %f" % (k, v, UNK_LOG_FREQ)
                pass
