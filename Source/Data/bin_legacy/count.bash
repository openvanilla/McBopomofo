#!/bin/bash
# Whom to blame: Mengjuei Hsieh
if [ $# -ne 1 ]; then
   echo "Usage: $0 <phrase string without space>"
   exit 0
fi
myPATH=$(dirname $0)
$myPATH/../scripts/count_occurrences.py -j 1 - << EOF | sed -e 's/\t/ /'
$1
EOF
exit 0
