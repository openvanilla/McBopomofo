#!/bin/bash
# Whom to blame: Mengjuei Hsieh
if [ $# -ne 1 ]; then
   echo "Usage: $0 <phrase string without space>"
   exit 0
fi
myPATH=$(dirname $0)
$myPATH/count.occurrence.py -j 1 - << EOF
$1
EOF
exit 0
