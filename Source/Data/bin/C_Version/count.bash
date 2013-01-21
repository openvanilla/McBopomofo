#!/bin/bash
# Whom to blame: Mengjuei Hsieh
if [ $# -ne 1 ]; then
   echo "Usage: $0 <phrase string without space>"
   exit 0
fi
myPATH=$(dirname $0)
if [ ! -f "${myPATH}/C_count.occ.exe" ]; then
   ( cd $myPATH; make C_count.occ.exe )
fi
if [ "${TEXTPOOL}_test" == "_test" ]; then
   TEXTPOOL=/Volumes/ramdisk/textpool.01202013
fi
if [ -f "$TEXTPOOL" ]; then
   $myPATH/C_count.occ.exe $TEXTPOOL $1
else
   echo "File \"${TEXTPOOL}\" not found."
fi
exit 0
