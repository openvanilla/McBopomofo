.PHONY: all install deps release debug

all: release
install: install-release

ifdef ARCHS
BUILD_SETTINGS += ARCHS="$(ARCHS)"
BUILD_SETTINGS += ONLY_ACTIVE_ARCH=NO
endif

release: 
	xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofo -configuration Release $(BUILD_SETTINGS) build
	xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoInstaller -configuration Release $(BUILD_SETTINGS) build

debug: 
	xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofo -configuration Debug $(BUILD_SETTINGS) build
	xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoInstaller -configuration Debug $(BUILD_SETTINGS) build

DSTROOT = /Library/Input Methods
OV_APP_ROOT = $(DSTROOT)/McBopomofo.app

.PHONY: permission-check install-debug install-release

permission-check:
	[ -w "$(DSTROOT)" ] && [ -w "$(OV_APP_ROOT)" ] || sudo chown -R ${USER} "$(DSTROOT)"

install-debug: debug permission-check
	rm -rf "$(OV_APP_ROOT)"
	cp -R Build/Debug/McBopomofo.app "$(DSTROOT)"

install-release: release permission-check
	rm -rf "$(OV_APP_ROOT)"
	cp -R Build/Products/Release/McBopomofo.app "$(DSTROOT)"

.PHONY: clean

clean:
	xcodebuild -scheme McBopomofo -configuration Debug $(BUILD_SETTINGS)  clean
	xcodebuild -scheme McBopomofo -configuration Debug $(BUILD_SETTINGS) clean
	xcodebuild -scheme McBopomofo -configuration Release $(BUILD_SETTINGS)  clean
	xcodebuild -scheme McBopomofo -configuration Release $(BUILD_SETTINGS) clean