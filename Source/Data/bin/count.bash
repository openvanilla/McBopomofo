#!/bin/bash
if [ $# -ne 1 ]; then
   echo "Usage: $0 <phrase string without space>"
   exit 0
fi
myPATH=$(dirname $0)
if [ ! -f "${myPATH}/C_count.occ.exe" ]; then
   ( cd $myPATH; make C_count.occ.exe )
fi
if [ "${TEXTPOOL}_test" == "_test" ]; then
   TEXTPOOL=/Volumes/ramdisk/textpool.02282012
fi
if [ -f "$TEXTPOOL" ]; then
   $myPATH/C_count.occ.exe $TEXTPOOL $1
fi
