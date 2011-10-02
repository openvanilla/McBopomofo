from Foundation import *
from AppKit import *
import os, shutil, platform

class InstallerAppDelegate(NSObject):

	window = objc.IBOutlet()
	licenseView = objc.IBOutlet()
	licenseTextView = objc.IBOutlet()
	agreeButton = objc.IBOutlet()
	cancelButton = objc.IBOutlet()

	def checkOSVerion(self):
		mac_version = platform.mac_ver()[0].split(".")
		if int(mac_version[1]) < 6:
			NSRunAlertPanel("McBoPoMoFo requires on Mac OS X 10.6 or later verion.", "", "OK", None, None)
			NSApp.terminate_(self)
	
	def showLicenseWindow(self):
		self.licenseTextView.textStorage().mutableString().setString_("License")
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
		call(["killall", "McBopomofo"])
		
		inputMethodDir = os.path.expanduser("~/Library/Input Methods")
		if os.path.exists(inputMethodDir) is False:
			os.makedirs(inputMethodDir)
		
		packagePath = NSBundle.mainBundle().pathForResource_ofType_("McBopomofo", "app")			
		McBopomofoPath = os.path.join(inputMethodDir, "McBopomofo.app")
		if os.path.exists(McBopomofoPath) is True:
			try:
				shutil.rmtree(McBopomofoPath)
			except:
				NSRunAlertPanel("Failed to remove existing application!", "", "OK", None, None)
		try:
			shutil.copytree(packagePath, McBopomofoPath)
		except:
			NSRunAlertPanel("Failed to copy application!", "", "OK", None, None)
			NSApp.terminate_(self)

		print McBopomofoPath
		try:
			call([os.path.join(McBopomofoPath, "Contents/MacOS/McBopomofo"), "install"])
		except:
			NSRunAlertPanel("Failed to install McBopomofo!", "", "OK", None, None)
			NSApp.terminate_(self)
		NSRunAlertPanel("Done!", "", "OK", None, None)
		NSApp.terminate_(self)

	@objc.IBAction
	def disagreeLicenseAction_(self, sender):
		NSApp.terminate_(self)
		
	def applicationDidFinishLaunching_(self, sender):
		self.checkOSVerion()
		self.showLicenseWindow()
		pass
		
		
		
