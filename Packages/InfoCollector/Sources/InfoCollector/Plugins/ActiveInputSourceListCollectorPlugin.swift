import AppKit
import Carbon.HIToolbox
import Foundation

struct ActiveInputSourceListCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Active input sources collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        func getStringValue(_ source: TISInputSource, _ property: CFString) -> String? {
            if let valuePts = TISGetInputSourceProperty(source, property) {
                let value = Unmanaged<CFString>.fromOpaque(valuePts).takeUnretainedValue()
                return value as? String
            }
            return nil
        }

        // Use HIToolbox TIS APIs to get current and enabled input sources
        // Build a query for enabled input sources
        let keys: [CFString: Any] = [
            kTISPropertyInputSourceIsEnabled: true as CFBoolean
        ]
        let dict = keys as CFDictionary
        var lines: [String] = []

        //        // Current input source
        //        if let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
        //            let currentName = getStringValue(current, kTISPropertyLocalizedName)
        //            let currentID = getStringValue(current, kTISPropertyInputSourceID)
        //            lines.append("- Current Input Source: \(currentName ?? "<unknown>") (\(currentID ?? ""))")
        //        }

        // Enabled input sources
        if let list = TISCreateInputSourceList(dict, false)?.takeRetainedValue()
            as? [TISInputSource]
        {
            lines.append("- Enabled Input Sources:")
            for src in list {
                let name = getStringValue(src, kTISPropertyLocalizedName) ?? "<unknown>"
                let sid = getStringValue(src, kTISPropertyInputSourceID) ?? ""
                let category = getStringValue(src, kTISPropertyInputSourceCategory) as? String ?? ""
                lines.append("  - \(name) (\(sid)) [\(category)]")
            }
        }

        if lines.isEmpty {
            lines.append("No input sources found")
        }
        callback(.success(lines.joined(separator: "\n")))
    }
}
