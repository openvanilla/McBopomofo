//
// PreferencesWindowController.swift
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

// Please note that the class should be exposed as "PreferencesWindowController"
// in Objective-C in order to let IMK to see the same class name as
// the "InputMethodServerPreferencesWindowControllerClass" in Info.plist.
@objc (PreferencesWindowController) class PreferencesWindowController: NSWindowController {
    @IBOutlet weak var fontSizePopUpButton: NSPopUpButton!
    @IBOutlet weak var basisKeyboardLayoutButton: NSPopUpButton!
    @IBOutlet weak var selectionKeyComboBox: NSComboBox!

    override func awakeFromNib() {
        let list = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
        var usKeyboardLayoutItem: NSMenuItem? = nil
        var chosenItem: NSMenuItem? = nil

        basisKeyboardLayoutButton.menu?.removeAllItems()

        let basisKeyboardLayoutID = Preferences.basisKeyboardLayout
        for source in list {
            if let categoryPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) {
                let category = Unmanaged<CFString>.fromOpaque(categoryPtr).takeUnretainedValue()
                if category != kTISCategoryKeyboardInputSource {
                    continue
                }
            } else {
                continue
            }

            if let asciiCapablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsASCIICapable) {
                let asciiCapable = Unmanaged<CFBoolean>.fromOpaque(asciiCapablePtr).takeUnretainedValue()
                if asciiCapable != kCFBooleanTrue {
                    continue
                }
            } else {
                continue
            }

            if let sourceTypePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) {
                let sourceType = Unmanaged<CFString>.fromOpaque(sourceTypePtr).takeUnretainedValue()
                if sourceType != kTISTypeKeyboardLayout {
                    continue
                }
            } else {
                continue
            }

            guard let sourceIDPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                  let localizedNamePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else {
                continue
            }

            let sourceID = String(Unmanaged<CFString>.fromOpaque(sourceIDPtr).takeUnretainedValue())
            let localizedName = String(Unmanaged<CFString>.fromOpaque(localizedNamePtr).takeUnretainedValue())

            let menuItem = NSMenuItem()
            menuItem.title = localizedName
            menuItem.representedObject = sourceID

            if sourceID == "com.apple.keylayout.US" {
                usKeyboardLayoutItem = menuItem
            }
            if basisKeyboardLayoutID == sourceID {
                chosenItem = menuItem
            }
            basisKeyboardLayoutButton.menu?.addItem(menuItem)
        }

        basisKeyboardLayoutButton.select(chosenItem ?? usKeyboardLayoutItem)
        selectionKeyComboBox.usesDataSource = false
        selectionKeyComboBox.addItems(withObjectValues: [Preferences.defaultKeys, "asdfghjkl", "asdfzxcvb"])

        var candidateSelectionKeys = Preferences.candidateKeys ?? Preferences.defaultKeys
        if candidateSelectionKeys.isEmpty {
            candidateSelectionKeys = Preferences.defaultKeys
        }

        selectionKeyComboBox.stringValue = candidateSelectionKeys
    }

    @IBAction func updateBasisKeyboardLayoutAction(_ sender: Any) {
        if let sourceID = basisKeyboardLayoutButton.selectedItem?.representedObject as? String {
            Preferences.basisKeyboardLayout = sourceID
        }
    }

    @IBAction func changeSelectionKeyAction(_ sender: Any) {
        let keys = (sender as AnyObject).stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if keys.count != 9 || !keys.canBeConverted(to: .ascii) {
            selectionKeyComboBox.stringValue = Preferences.defaultKeys
            Preferences.candidateKeys = nil
            NSSound.beep()
            return
        }

        selectionKeyComboBox.stringValue = keys
        if keys == Preferences.defaultKeys {
            Preferences.candidateKeys = nil
        } else {
            Preferences.candidateKeys = keys
        }
    }

}

