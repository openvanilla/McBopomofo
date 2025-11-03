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

import Carbon
import Foundation
import IOKit
import IOKit.hid

struct KeyboardTypeCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Keyboard type collector" }

    func intValue(_ dict: CFDictionary, _ key: String) -> Int? {
        // Access value as Any? once, then branch by runtime type without conditional CF downcast warnings
        let anyValue = (dict as NSDictionary)[key]
        if let intVal = anyValue as? Int { return intVal }
        if let number = anyValue as? NSNumber { return number.intValue }
        return nil
    }

    func strValue(_ dict: CFDictionary, _ key: String) -> String? {
        (dict as NSDictionary)[key] as? String
    }

    func usagePage(from props: CFDictionary) -> Int? {
        return intValue(props, kIOHIDPrimaryUsagePageKey as String)
            ?? intValue(props, "PrimaryUsagePage")
    }
    func usage(from props: CFDictionary) -> Int? {
        return intValue(props, kIOHIDPrimaryUsageKey as String) ?? intValue(props, "PrimaryUsage")
    }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        let matching = IOServiceMatching("IOHIDDevice")
        var iter: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iter)
        guard kr == KERN_SUCCESS else {
            callback(
                .failure(
                    NSError(
                        domain: "KeyboardTypeCollectorPlugin", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "IOServiceGetMatchingServices failed \(kr)"
                        ])))
            return

        }
        defer { IOObjectRelease(iter) }
        var entry = IOIteratorNext(iter)
        var idx = 0
        var lines: [String] = []

        while entry != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            let r = IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0)
            if r == KERN_SUCCESS, let dict = props?.takeRetainedValue() {
                if let up = usagePage(from: dict), up == kHIDPage_GenericDesktop {
                    if let u = usage(from: dict),
                        u == kHIDUsage_GD_Keyboard || u == kHIDUsage_GD_Keypad
                    {
                        idx += 1
                        let product =
                            strValue(dict, kIOHIDProductKey as String) ?? strValue(dict, "Product")
                            ?? "(Unknown Product)"
                        let manufacturer =
                            strValue(dict, kIOHIDManufacturerKey as String)
                            ?? "(Unknown Manufacturer)"
                        let transport = strValue(dict, kIOHIDTransportKey as String) ?? "Unknown"
                        let vendorID = intValue(dict, kIOHIDVendorIDKey as String)
                        let productID = intValue(dict, kIOHIDProductIDKey as String)
                        let location = intValue(dict, kIOHIDLocationIDKey as String)
                        let countryID = intValue(dict, kIOHIDCountryCodeKey as String)

                        lines.append("  - \(product)")
                        lines.append("    - Manufacturer: \(manufacturer)")
                        lines.append("    - Transport: \(transport)")
                        if let vendorID {
                            lines.append("    - VendorID: \(vendorID)")
                        }
                        if let productID {
                            lines.append("    - ProductID: \(productID)")
                        }
                        if let countryID {
                            lines.append("    - Country Code: \(countryID)")
                        }
                        if let location {
                            lines.append("    - Location: \(numberToHex(location))")
                        }
                    }
                }
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iter)
        }

        if lines.isEmpty {
            callback(.success(""))
        } else {
            callback(.success("- Keyboards:\n" + lines.joined(separator: "\n")))
        }
    }
}
