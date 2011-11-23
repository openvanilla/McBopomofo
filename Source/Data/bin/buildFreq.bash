#!/bin/bash
awk -v TOTAL=$(awk '{s+=$2}END{print s}' phrase.occ ) \
'{printf("%s %.8f\n",$1,log($2/TOTAL)/log(10))}' phrase.occ \
| sed -e 's/inf$/7.0/' > PhraseFreq.txt
