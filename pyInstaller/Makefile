# Author of this Makefile:
#     Mengjuei Hsieh, University of California Irvine

info:
	@echo "This script is for mjhsieh only"
	@echo "You need to read the Makefile to see what it's doing"

clean:
	xcodebuild clean

release:
	xcodebuild -target Installer -configuration Release \
	-arch i386 -arch x86_64

debug:
	xcodebuild -target Installer -configuration Debug \
	-arch i386 -arch x86_64
