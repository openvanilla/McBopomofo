#!/bin/bash -e

xcodebuild -target McBopomofo -configuration Release clean
xcodebuild -target McBopomofo -configuration Release
