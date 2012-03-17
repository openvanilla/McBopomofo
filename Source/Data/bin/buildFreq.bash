#i!/bin/bash
TOTAL="$(perl -w bin/utf8length.pl < phrase.occ | \
         awk '{s+=($2+2.7^$3)}END{print s}' \
        )"
perl -w bin/utf8length.pl < phrase.occ \
 | awk -v TOTAL=$TOTAL \
       ' $2>0{printf("%s %.8f\n",$1,log(( $2*3.7^($3-1))/TOTAL)/log(10))}
        $2==0{printf("%s %.8f\n",$1,log((0.5*3.7^($3-1))/TOTAL)/log(10))}' \
 | sed -e 's/inf$/8.0/' > PhraseFreq.txt
#perl -w bin/utf8length.pl < phrase.occ | awk -v TOTAL=$TOTAL \
#    ' $2>0{printf("%s %.8f\n",$1,log( $2/TOTAL)/log(10))}
#     $2==0{printf("%s %.8f\n",$1,log(0.5/TOTAL)/log(10))}' \
#    | sed -e 's/inf$/7.0/' > PhraseFreq.txt
