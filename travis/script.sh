#!/bin/bash -e

xcodebuild -scheme McBopomofo -configuration Release clean
xcodebuild -scheme McBopomofo -configuration Release
