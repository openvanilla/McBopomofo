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

import Darwin
import Foundation
import IOKit

struct MachineModelCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Machine model collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Helpers to read sysctl values
        func sysctlString(_ name: String) -> String? {
            var size: size_t = 0
            if sysctlbyname(name, nil, &size, nil, 0) != 0 || size == 0 { return nil }
            var buffer = [CChar](repeating: 0, count: size)
            let result = buffer.withUnsafeMutableBufferPointer { ptr -> Int32 in
                return sysctlbyname(name, ptr.baseAddress, &size, nil, 0)
            }
            if result != 0 { return nil }
            // Trim trailing NUL if present and decode as UTF-8 to avoid deprecated String(cString:)
            let trimmed: [CChar]
            if let last = buffer.last, last == 0 {
                trimmed = Array(buffer.dropLast())
            } else {
                trimmed = buffer
            }
            return String(decoding: trimmed.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
        func sysctlUInt64(_ name: String) -> UInt64? {
            var value: UInt64 = 0
            var size = MemoryLayout<UInt64>.size
            let result = withUnsafeMutablePointer(to: &value) { ptr -> Int32 in
                return sysctlbyname(name, ptr, &size, nil, 0)
            }
            return (result == 0) ? value : nil
        }
        func sysctlInt32(_ name: String) -> Int32? {
            var value: Int32 = 0
            var size = MemoryLayout<Int32>.size
            let result = withUnsafeMutablePointer(to: &value) { ptr -> Int32 in
                return sysctlbyname(name, ptr, &size, nil, 0)
            }
            return (result == 0) ? value : nil
        }

        let model = sysctlString("hw.model")
        let machine = sysctlString("hw.machine")
        let cpuBrand = sysctlString("machdep.cpu.brand_string")  // may be nil on Apple Silicon
        let cpuType = sysctlInt32("hw.cputype")
        let cpuSubtype = sysctlInt32("hw.cpusubtype")
        let ncpu = sysctlInt32("hw.ncpu")
        let memBytes = sysctlUInt64("hw.memsize")
        let freqHz = sysctlUInt64("hw.cpufrequency")

        func bytesToGB(_ bytes: UInt64?) -> String {
            guard let bytes else { return "n/a" }
            let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
            return String(format: "%.1f GB", gb)
        }
        func hzToGHz(_ hz: UInt64?) -> String {
            guard let hz else { return "n/a" }
            let ghz = Double(hz) / 1_000_000_000.0
            return String(format: "%.2f GHz", ghz)
        }

        var terminatedModelString = "unknown"
        if #available(macOS 12.0, *) {
            let mainEntry = IORegistryEntryFromPath(
                kIOMainPortDefault,
                "IOService:/AppleARMPE/product"
            )
            let property = IORegistryEntryCreateCFProperty(
                mainEntry, "product-description" as CFString, kCFAllocatorDefault, 0)
            if let bytes = property?.takeRetainedValue() as? Data {
                var array = [UInt8](bytes)
                // Truncate any trailing NUL terminator before decoding, per deprecation guidance
                if let last = array.last, last == 0 {
                    array.removeLast()
                }
                terminatedModelString = String(decoding: array, as: UTF8.self)
            }
            IOObjectRelease(mainEntry)
        } else {
            // Fallback on earlier versions
        }

        var lines: [String] = []
        lines.append("- Model: \(model ?? "unknown")")
        if #available(macOS 12.0, *) {
            lines.append("- Readable Model: \(terminatedModelString)")
        }
        lines.append("- Machine: \(machine ?? "unknown")")
        if let brand = cpuBrand, !brand.isEmpty {
            lines.append("- CPU: \(brand)")
        } else {
            lines.append("- CPU: type=\(cpuType ?? -1) subtype=\(cpuSubtype ?? -1)")
        }
        lines.append("- Cores: \(ncpu ?? 0)")
        lines.append("- Memory: \(bytesToGB(memBytes))")
        lines.append("- CPU Frequency: \(hzToGHz(freqHz))")

        callback(.success(lines.joined(separator: "\n")))
    }
}
