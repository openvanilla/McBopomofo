from Foundation import *
from AppKit import *
import os, shutil, platform

MIT_LICENSE = """Copyright (C) 2011 by OpenVanilla.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
"""

class InstallerAppDelegate(NSObject):

    window = objc.IBOutlet()
    licenseView = objc.IBOutlet()
    licenseTextView = objc.IBOutlet()
    messageLabel = objc.IBOutlet()
    agreeButton = objc.IBOutlet()
    cancelButton = objc.IBOutlet()

    def awakeFromNib(self):
        self.window.setDelegate_(self)
        self.window.setTitle_(NSLocalizedString("McBopomofo", ""))
        self.agreeButton.setTitle_(NSLocalizedString("Agree", ""))
        self.cancelButton.setTitle_(NSLocalizedString("Cancel", ""))
        self.messageLabel.setStringValue_(NSLocalizedString("Do you agree with the license?", ""))
        self.licenseTextView.textStorage().mutableString().setString_(MIT_LICENSE)

    def windowWillClose_(self, notification):
        NSApp.terminate_(self)

    def checkOSVerion(self):
        mac_version = platform.mac_ver()[0].split(".")
        if int(mac_version[1]) < 6:
            NSRunAlertPanel(NSLocalizedString("McBopomofo requires on Mac OS X 10.6 or later verion.", ""),
                NSLocalizedString("Unable to install McBopomofo on your Mac.",""), 
                NSLocalizedString("OK", ""), None, None)
            NSApp.terminate_(self)

    def showLicenseWindow(self):
        windowFrame = self.window.frame()
        windowFrame.size = self.licenseView.frame().size
        windowFrame.size.height += 20.0
        self.window.setFrame_display_animate_(windowFrame, True, True)
        self.window.contentView().addSubview_(self.licenseView)
        self.window.center()
        self.window.setDefaultButtonCell_(self.agreeButton.cell())
        self.window.makeKeyAndOrderFront_(None)

    @objc.IBAction
    def agreeLicenseAction_(self, sender):
        self.window.orderOut_(None)
        from subprocess import call
        call(["/usr/bin/killall", "-9", "McBopomofo"])

        inputMethodDir = os.path.expanduser("~/Library/Input Methods")
        if os.path.exists(inputMethodDir) is False:
            os.makedirs(inputMethodDir)

        packagePath = NSBundle.mainBundle().pathForResource_ofType_("McBopomofo", "app")
        McBopomofoPath = os.path.join(inputMethodDir, "McBopomofo.app")

        WrongPath = os.path.join(McBopomofoPath, "McBopomofo.app")
        if os.path.exists(WrongPath) is True:
            try:
                shutil.rmtree(WrongPath)
            except:
                """do nothing"""

        if os.path.exists(McBopomofoPath) is True:
            if os.path.isfile(McBopomofoPath) is True:
                try:
                    call(["/bin/rm","-f",McBopomofoPath])
                except:
                    """do nothing"""
            try:
                call(["/bin/cp", "-R", packagePath, inputMethodDir]) 
            except:
                NSRunAlertPanel(NSLocalizedString("Failed to install McBopomofo!", ""),
                    NSLocalizedString("Failed to overwrite existing installation.", ""),
                    NSLocalizedString("OK", ""), None, None)
        else:
            try:
                shutil.copytree(packagePath, McBopomofoPath)
            except:
                NSRunAlertPanel(NSLocalizedString("Failed to install McBopomofo!", ""),
                    NSLocalizedString("Failed to copy application.", ""),
                    NSLocalizedString("OK", ""), None, None)
                NSApp.terminate_(self)

        try:
            call([os.path.join(McBopomofoPath, "Contents/MacOS/McBopomofo"), "install"])
        except:
            NSRunAlertPanel(NSLocalizedString("Failed to install McBopomofo!", ""), 
                NSLocalizedString("Failed to activate McBopomofo", ""), 
                NSLocalizedString("OK", ""), None, None)
            NSApp.terminate_(self)
        NSRunAlertPanel(NSLocalizedString("Done!", ""),
            NSLocalizedString("McBopomofo has been installed on your Mac.", ""),
            NSLocalizedString("OK", ""), None, None)
        NSApp.terminate_(self)

    @objc.IBAction
    def disagreeLicenseAction_(self, sender):
        NSApp.terminate_(self)

    def applicationDidFinishLaunching_(self, sender):
        NSApp.activateIgnoringOtherApps_(True)
        self.checkOSVerion()
        self.showLicenseWindow()

