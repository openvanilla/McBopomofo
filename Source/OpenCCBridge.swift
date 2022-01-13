import Foundation
import OpenCC

// Since SwiftyOpenCC only provide Swift classes, we create an NSObject subclass
// in Swift in order to bridge the Swift classes into our Objective-C++ project.
public class OpenCCBridge: NSObject {
    private static let shared = OpenCCBridge()
    private var converter: ChineseConverter?

    override init() {
        try? converter = ChineseConverter(options: .simplify)
        super.init()
    }

    @objc public static func convert(_ string: String) -> String? {
        shared.converter?.convert(string)
    }
}
