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

func osStatusToString(_ status: OSStatus) -> String {
    let bigEndianValue = status.bigEndian
    let data = withUnsafeBytes(of: bigEndianValue) { Data($0) }

    if let fourCharString = String(data: data, encoding: .ascii) {
        return fourCharString
    } else {
        return "(\(String(format: "%08X", status)))"
    }
}

func numberToHex<T: FixedWidthInteger>(_ number: T, withPrefix prefix: Bool = true) -> String {
    let width = MemoryLayout<T>.size * 2
    let formatString = prefix ? "%#0\(width + 2)X" : "%0\(width)X"
    return String(format: formatString, number as! CVarArg)
}
