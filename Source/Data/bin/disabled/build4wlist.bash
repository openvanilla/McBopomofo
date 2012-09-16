#!/bin/bash
myFILE=$(mktemp /tmp/XXXXXXX)
awk '$NF=="big5"' BPMFBase.txt > $myFILE
awk '{print $1}' $myFILE BPMFMappings.txt |sort| uniq > phrase.list
rm -f $myFILE
