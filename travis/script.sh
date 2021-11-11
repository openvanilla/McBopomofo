#!/bin/bash -e

xcodebuild -scheme McBopomofo -configuration Release clean
xcodebuild -scheme McBopomofo -configuration Release build
xcodebuild -scheme McBopomofoInstaller -configuration Release clean
xcodebuild -scheme McBopomofoInstaller -configuration Release build