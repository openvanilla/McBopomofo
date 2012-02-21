#i!/bin/bash
TOTAL="$(perl -w bin/utf8length.pl < phrase.occ | \
         awk '{s+=($2+$3^0.5)}END{print s}' \
        )"
perl -w bin/utf8length.pl < phrase.occ | awk -v TOTAL=$TOTAL \
    '{printf("%s %.8f\n",$1,log(($2+$3^0.5)/TOTAL)/log(10))}' \
    | sed -e 's/inf$/8.0/' > PhraseFreq.txt
#awk -v TOTAL=$(awk '{s+=$2}END{print s}' phrase.occ ) \
#'{printf("%s %.8f\n",$1,log($2/TOTAL)/log(10))}' phrase.occ \
#| sed -e 's/inf$/7.0/' > PhraseFreq.txt
