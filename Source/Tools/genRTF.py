#!/usr/bin/env python
import sys, os
import platform
myversion, _, _ = platform.mac_ver()
myversion = float('.'.join(myversion.split('.')[:2]))

if myversion == 10.8:
    os.environ["MACOSX_DEPLOYMENT_TARGET"] = "10.8"
    print myversion
else:
    os.environ["MACOSX_DEPLOYMENT_TARGET"] = "10.7"

os.environ["PYTHONPATH"] = "/System/Library/Frameworks/Python.framework/Versions/2.6/Extras/lib/python/"

import subprocess, getopt
from Foundation import *
from AppKit import *

def generateRTF(inString="", inFile=""):
    if len(inString) == 0: return
    if len(inFile) == 0: return
    paragraphStyle = NSMutableParagraphStyle.alloc().init()
    paragraphStyle.setAlignment_(NSCenterTextAlignment)
    attributedString = NSAttributedString.alloc().initWithString_attributes_(inString, {
        NSParagraphStyleAttributeName: paragraphStyle,
        NSFontAttributeName: NSFont.systemFontOfSize_(11)
    })
    data = attributedString.RTFFromRange_documentAttributes_(NSMakeRange(0, len(inString)), None)
    try: os.remove(inFile)
    except: pass
    data.writeToFile_atomically_(inFile, True)
    os.utime(inFile, None) # Touch the file

def main(argv=None):
    if argv is None:
        argv = sys.argv
    try:
        path = argv[1]
    except:
        return

    path = os.path.abspath(path)
    cmd = "/usr/bin/git log --format='%h' -1"
    try:
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        lines = ""
        while True:
            line = p.stdout.readline()
            if not line: break
            line = line.strip()
            if len(line): lines += line + "\n"
        lines = lines.strip()
        generateRTF("Build: " + lines, os.path.join(path, "Credits.rtf"))
    except Exception, e:
        pass

if __name__ == "__main__":
    sys.exit(main())
