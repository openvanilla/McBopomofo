// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

import Cocoa
import Carbon

fileprivate extension NSToolbarItem.Identifier {
    static let basic = NSToolbarItem.Identifier(rawValue: "basic")
    static let advanced = NSToolbarItem.Identifier(rawValue: "advanced")
}

fileprivate let kWindowTitleHeight: CGFloat = 78


// Please note that the class should be exposed as "PreferencesWindowController"
// in Objective-C in order to let IMK to see the same class name as
// the "InputMethodServerPreferencesWindowControllerClass" in Info.plist.
@objc(PreferencesWindowController) class PreferencesWindowController: NSWindowController {
    @IBOutlet weak var fontSizePopUpButton: NSPopUpButton!
    @IBOutlet weak var basisKeyboardLayoutButton: NSPopUpButton!
    @IBOutlet weak var selectionKeyComboBox: NSComboBox!
    @IBOutlet weak var basicSettingsView: NSView!
    @IBOutlet weak var advancedSettingsView: NSView!

    override func awakeFromNib() {
        let toolbar = NSToolbar(identifier: "preference toolbar")
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.sizeMode = .default
        toolbar.delegate = self
        toolbar.selectedItemIdentifier = .basic
        toolbar.showsBaselineSeparator = true
        window?.titlebarAppearsTransparent = false
        if #available(macOS 11.0, *) {
            window?.toolbarStyle = .preference
        }
        window?.toolbar = toolbar
        window?.title = NSLocalizedString("Basic", comment: "")
        use(view: basicSettingsView)

        let list = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
        var usKeyboardLayoutItem: NSMenuItem? = nil
        var chosenItem: NSMenuItem? = nil

        basisKeyboardLayoutButton.menu?.removeAllItems()

        let basisKeyboardLayoutID = Preferences.basisKeyboardLayout
        for source in list {

            func getString(_ key: CFString) -> String? {
                if let ptr = TISGetInputSourceProperty(source, key) {
                    return String(Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue())
                }
                return nil
            }

            func getBool(_ key: CFString) -> Bool? {
                if let ptr = TISGetInputSourceProperty(source, key) {
                    return Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue() == kCFBooleanTrue
                }
                return nil
            }

            if let category = getString(kTISPropertyInputSourceCategory) {
                if category != String(kTISCategoryKeyboardInputSource) {
                    continue
                }
            } else {
                continue
            }

            if let asciiCapable = getBool(kTISPropertyInputSourceIsASCIICapable) {
                if !asciiCapable {
                    continue
                }
            } else {
                continue
            }

            if let sourceType = getString(kTISPropertyInputSourceType) {
                if sourceType != String(kTISTypeKeyboardLayout) {
                    continue
                }
            } else {
                continue
            }

            guard let sourceID = getString(kTISPropertyInputSourceID),
                  let localizedName = getString(kTISPropertyLocalizedName) else {
                continue
            }

            let menuItem = NSMenuItem()
            menuItem.title = localizedName
            menuItem.representedObject = sourceID

            if let iconPtr = TISGetInputSourceProperty(source, kTISPropertyIconRef) {
                let icon = IconRef(iconPtr)
                let image = NSImage(iconRef: icon)

                func resize(_ image: NSImage) -> NSImage {
                    let newImage = NSImage(size: NSSize(width: 16, height: 16))
                    newImage.lockFocus()
                    image.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                    newImage.unlockFocus()
                    return newImage
                }

                menuItem.image = resize(image)
            }

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
        selectionKeyComboBox.removeAllItems()
        selectionKeyComboBox.addItems(withObjectValues: Preferences.suggestedCandidateKeys)

        var candidateSelectionKeys = Preferences.candidateKeys
        if candidateSelectionKeys.isEmpty {
            candidateSelectionKeys = Preferences.defaultCandidateKeys
        }

        selectionKeyComboBox.stringValue = candidateSelectionKeys
    }

    @IBAction func updateBasisKeyboardLayoutAction(_ sender: Any) {
        if let sourceID = basisKeyboardLayoutButton.selectedItem?.representedObject as? String {
            Preferences.basisKeyboardLayout = sourceID
        }
    }

    @IBAction func changeSelectionKeyAction(_ sender: Any) {
        guard let keys = (sender as AnyObject).stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() else {
            return
        }
        do {
            try Preferences.validate(candidateKeys: keys)
            Preferences.candidateKeys = keys
        } catch Preferences.CandidateKeyError.empty {
            selectionKeyComboBox.stringValue = Preferences.candidateKeys
        } catch {
            if let window = window {
                let alert = NSAlert(error: error)
                alert.beginSheetModal(for: window) { response in
                    self.selectionKeyComboBox.stringValue = Preferences.candidateKeys
                }
            }
        }
    }

}


extension PreferencesWindowController: NSToolbarDelegate {
    func use(view: NSView) {
        guard let window = window else {
            return
        }
        window.contentView?.subviews.first?.removeFromSuperview()
        let viewFrame = view.frame
        var windowRect = window.frame
        windowRect.size.height = kWindowTitleHeight + viewFrame.height
        windowRect.size.width = viewFrame.width
        windowRect.origin.y = window.frame.maxY - (viewFrame.height + kWindowTitleHeight)
        window.setFrame(windowRect, display: true, animate: true)
        window.contentView?.frame = view.bounds
        window.contentView?.addSubview(view)
    }

    @objc func showBasicView(_ sender: Any?) {
        use(view: basicSettingsView)
        window?.toolbar?.selectedItemIdentifier = .basic
        window?.title = NSLocalizedString("Basic", comment: "")
    }

    @objc func showAdvancedView(_ sender: Any?) {
        use(view: advancedSettingsView)
        window?.toolbar?.selectedItemIdentifier = .advanced
        window?.title = NSLocalizedString("Advanced", comment: "")
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.basic, .advanced]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.basic, .advanced]
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.basic, .advanced]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.target = self
        switch itemIdentifier {
        case .basic:
            let title = NSLocalizedString("Basic", comment: "")
            item.label = title
            if #available(macOS 11.0, *) {
                item.image = NSImage(systemSymbolName: "switch.2", accessibilityDescription: title)
            } else {
                item.image = NSImage(named: NSImage.preferencesGeneralName)
            }
            item.action = #selector(showBasicView(_:))

        case .advanced:
            let title = NSLocalizedString("Advanced", comment: "")
            item.label = title
            if #available(macOS 11.0, *) {
                item.image = NSImage(systemSymbolName: "gear", accessibilityDescription: title)
            } else {
                item.image = NSImage(named: NSImage.advancedName)
            }
            item.action = #selector(showAdvancedView(_:))
        default:
            return nil
        }
        return item
    }
}
