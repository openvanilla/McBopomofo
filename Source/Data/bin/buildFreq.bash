#i!/bin/bash
# Whom to blame: Mengjuei Hsieh
TOTAL="$(perl -w bin/utf8length.pl < phrase.occ | \
         awk '{s+=($2+2.7^$3)}END{print s}' \
        )"
# Getting a hint from algorithm of Max-match segmentation
# Make it easier to greedily search from longer "phrase"
perl -w bin/utf8length.pl < phrase.occ \
 | awk -v TOTAL=$TOTAL \
       ' $2>0{printf("%s %.8f\n",$1,log(( $2*3.7^($3-1))/TOTAL)/log(10))}
        $2==0{printf("%s %.8f\n",$1,log((0.5*3.7^($3-1))/TOTAL)/log(10))}' \
 | sed -e 's/inf$/8.0/' > PhraseFreq.txt
# Following is the un-length-weighted score with an arbitrarily score of
# baseline of zero frequency phrases.
#perl -w bin/utf8length.pl < phrase.occ | awk -v TOTAL=$TOTAL \
#    ' $2>0{printf("%s %.8f\n",$1,log( $2/TOTAL)/log(10))}
#     $2==0{printf("%s %.8f\n",$1,log(0.5/TOTAL)/log(10))}' \
#    | sed -e 's/inf$/7.0/' > PhraseFreq.txt
