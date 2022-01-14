import Foundation
import OpenCC

/// A bridge to let Objctive-C code to access SwiftyOpenCC.
///
/// Since SwiftyOpenCC only provide Swift classes, we create an NSObject subclass
/// in Swift in order to bridge the Swift classes into our Objective-C++ project.
public class OpenCCBridge: NSObject {
    private static let shared = OpenCCBridge()
    private var converter: ChineseConverter?

    private override init() {
        try? converter = ChineseConverter(options: .simplify)
        super.init()
    }

    /// Converts to Simplified Chinese.
    /// 
    /// - Parameter string: Text in Traditional Chinese.
    /// - Returns: Text in Simplified Chinese.
    @objc public static func convertToSimplified(_ string: String) -> String? {
        shared.converter?.convert(string)
    }
}
