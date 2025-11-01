import AppKit

struct MacVersionCollectorPlugin: InfoCollectorPlugin {
    var name: String { "macOS version collector" }
    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let versionString =
            "- OS Version: macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        callback(.success(versionString))
    }
}
