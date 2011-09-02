#!/bin/bash
myFILE=$(mktemp /tmp/XXXXXXX)
awk '$NF=="big5"' BPMFBase.txt > $myFILE
awk '{print $1}' $myFILE BPMFMappings.txt |sort| uniq > 1-4w.list
rm -f $myFILE
