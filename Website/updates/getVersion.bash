#!/bin/bash
buildNum=`git log --oneline | wc -l`
#echo "#define BUILD_VERSION $buildNum" > InfoPlist.h
echo $buildNum
