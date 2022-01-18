//
// OVInputSourceHelper.swift
//
// Copyright (c) 2011 The McBopomofo Project.
//
// Contributors:
//     Mengjuei Hsieh (@mjhsieh)
//     Weizhong Yang (@zonble)
//
// Based on the Syrup Project and the Formosana Library
// by Lukhnos Liu (@lukhnos).
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

import Cocoa
import Carbon

public class InputSourceHelper: NSObject {

    @available(*, unavailable)
    public override init() {
        super.init()
    }

    public static func allInstalledInputSources() -> [TISInputSource] {
        TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
    }

    @objc(inputSourceForProperty:stringValue:)
    public static func inputSource(for propertyKey: CFString, stringValue: String) -> TISInputSource? {
        let stringID = CFStringGetTypeID()
        for source in allInstalledInputSources() {
            if let propertyPtr = TISGetInputSourceProperty(source, propertyKey) {
                let property = Unmanaged<CFTypeRef>.fromOpaque(propertyPtr).takeUnretainedValue()
                let typeID = CFGetTypeID(property)
                if typeID != stringID {
                    continue
                }
                if stringValue == property as? String {
                    return source
                }
            }
        }
        return nil
    }

    @objc(inputSourceForInputSourceID:)
    public static func inputSource(for sourceID: String) -> TISInputSource? {
        inputSource(for: kTISPropertyInputSourceID, stringValue: sourceID)
    }

    @objc(inputSourceEnabled:)
    public static func inputSourceEnabled(for source: TISInputSource) -> Bool {
        if let valuePts = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
            let value = Unmanaged<CFBoolean>.fromOpaque(valuePts).takeUnretainedValue()
            return value == kCFBooleanTrue
        }
        return false
    }

    @objc(enableInputSource:)
    public static func enable(inputSource: TISInputSource) -> Bool {
        let status = TISEnableInputSource(inputSource)
        return status == noErr
    }

    @objc(enableAllInputModesForInputSourceBundleID:)
    public static func enableAllInputMode(for inputSourceBundleD: String) -> Bool {
        var enabled = false
        for source in allInstalledInputSources() {
            guard let bundleIDPtr = TISGetInputSourceProperty(source, kTISPropertyBundleID),
                  let _ = TISGetInputSourceProperty(source, kTISPropertyInputModeID) else {
                continue
            }
            let bundleID = Unmanaged<CFString>.fromOpaque(bundleIDPtr).takeUnretainedValue()
            if String(bundleID) == inputSourceBundleD {
                let modeEnabled = self.enable(inputSource: source)
                if !modeEnabled {
                    return false
                }
                enabled = true
            }
        }

        return enabled
    }

    @objc(enableInputMode:forInputSourceBundleID:)
    public static func enable(inputMode modeID: String, for bundleID: String) -> Bool {
        for source in allInstalledInputSources() {
            guard let bundleIDPtr = TISGetInputSourceProperty(source, kTISPropertyBundleID),
                  let modePtr = TISGetInputSourceProperty(source, kTISPropertyInputModeID) else {
                continue
            }
            let inputsSourceBundleID = Unmanaged<CFString>.fromOpaque(bundleIDPtr).takeUnretainedValue()
            let inputsSourceModeID = Unmanaged<CFString>.fromOpaque(modePtr).takeUnretainedValue()
            if modeID == String(inputsSourceModeID) && bundleID == String(inputsSourceBundleID) {
                let enabled = enable(inputSource: source)
                print("Attempt to enable input source of mode: \(modeID), bundle ID: \(bundleID), result: \(enabled)")
                return enabled
            }

        }
        print("Failed to find any matching input source of mode: \(modeID), bundle ID: \(bundleID)")
        return false

    }

    @objc(disableInputSource:)
    public static func disable(inputSource: TISInputSource) -> Bool {
        let status = TISDisableInputSource(inputSource)
        return status == noErr
    }

    @objc(registerInputSource:)
    public static func registerTnputSource(at url: URL) -> Bool {
        let status = TISRegisterInputSource(url as CFURL)
        return status == noErr
    }

}

