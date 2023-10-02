// Copyright (c) 2021 and onwards The McBopomofo Authors.
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

import Foundation
import OpenCC

/// A bridge to let Objctive-C code to access SwiftyOpenCC.
///
/// Since SwiftyOpenCC only provide Swift classes, we create an NSObject subclass
/// in Swift in order to bridge the Swift classes into our Objective-C++ project.
public class OpenCCBridge: NSObject {

    @objc(sharedInstance) public static let shared = OpenCCBridge()

    private var converter: ChineseConverter?

    private override init() {
        try? converter = ChineseConverter(options: .simplify)
        super.init()
    }

    /// Converts to Simplified Chinese.
    ///
    /// - Parameter string: Text in Traditional Chinese.
    /// - Returns: Text in Simplified Chinese.
    @objc public func convertToSimplified(_ string: String) -> String? {
        converter?.convert(string)
    }
}
