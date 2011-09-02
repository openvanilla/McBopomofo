#!/bin/bash

# The following files are bundled:
#
# 'Lettuce.app'
# 'CocoaDialog.app'
# 'pic_normal.png'
#

myLicense="Copyright (c) 2011, the Openvanilla Project

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."

CD="CocoaDialog.app/Contents/MacOS/CocoaDialog"
rv=$($CD yesno-msgbox --title "License Agreement" --text "Agree this before you install. :-)" --informative-text "$myLicense" --string-output --no-cancel) 

if [ $rv == "No" ]; then
   exit 0
fi

if [ $(/bin/ps xww|/usr/bin/awk '/Lettuce/{bm=1}END{print bm}')"blah" != "blah1" ]; then
   killall -9 Lettuce
   echo PROGRESS:25
fi
if [ ! -e $HOME/Library/Input\ Methods ]; then
   mkdir -p $HOME/Library/Input\ Methods
   echo PROGRESS:50
else
   echo PROGRESS:50
fi
cp -R Lettuce.app $HOME/Library/Input\ Methods/
echo PROGRESS:75
$HOME/Library/Input\ Methods/Lettuce.app/Contents/MacOS/Lettuce install
echo PROGRESS:100
$CD bubble --debug --title "Thank you!" --text "McBoPoMoPo has been installed." --icon-file pic_normal.png
