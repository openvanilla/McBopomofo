#!/bin/bash
# Mengjuei Hsieh, OpenVanilla
scriptPATH=`cd $(dirname $0) && pwd`
. ${scriptPATH}/filter.bash
find * -type f -print \
    | grep -iv -e bash -e DS_S -e README \
               -e AcademiaSinicaBakeoff2005.lm \
    | xargs cat \
    | OVTrainingSetFilter \
    | python2.7 ${scriptPATH}/../nonCJK_filter.py \
    | perl -pe 's/(.{0,80})\s/$1\n/g' \
    | env LANG=C sort -u
