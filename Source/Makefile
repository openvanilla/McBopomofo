# Author of this Makefile:
#     Mengjuei Hsieh, University of California Irvine

info:
	@echo "This script is for mjhsieh only"
	@echo "You need to read the Makefile to see what it's doing"

clean:
	xcodebuild clean

# mjhsieh: if you want to just update the data.txt, do:
#	killall -9 McBopomofo
#	mv data.txt ~/L/I/L/C/R/
#	~/L/I/L/C/M/McBofomofo install

release:
	@killall -9 McBopomofo; sleep 2
	xcodebuild -target Lettuce -configuration Release

debug:
	@killall -9 McBopomofo; sleep 2
	xcodebuild -target Lettuce -configuration Debug

install: release
	$(HOME)/Library/Input\ Methods/McBopomofo.app/Contents/MacOS/McBopomofo install

installdebug: debug
	$(HOME)/Library/Input\ Methods/McBopomofo.app/Contents/MacOS/McBopomofo install

.PHONY: info clean release debug install installdebug
