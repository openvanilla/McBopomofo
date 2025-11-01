import AppKit

struct DefaultWebBrowserCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Default web browser collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Prefer https; fall back to http if needed
        if let appURL = LSCopyDefaultApplicationURLForURL(
            URL(string: "https://apple.com")! as CFURL, .all, nil)?.takeRetainedValue() as URL?
        {
            let bundle = Bundle(url: appURL)
            let displayName =
                bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
                ?? (appURL.deletingPathExtension().lastPathComponent)
            let bundleID = bundle?.bundleIdentifier ?? "unknown.bundle.id"
            callback(.success("- Default Browser: \(displayName) (\(bundleID))"))
            return
        }

        // Fallback to Launch Services by role handler for http if the URL lookup fails
        if let handlerCF = LSCopyDefaultHandlerForURLScheme("http" as CFString) {
            let handler = handlerCF.takeRetainedValue() as String
            let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: handler)
            let displayName = path?.deletingPathExtension().lastPathComponent ?? handler
            callback(.success("- Default Browser: \(displayName) (\(handler))"))
            return
        }

        struct NoDefaultBrowserError: LocalizedError {
            var errorDescription: String? { "No default browser configured" }
        }
        callback(.failure(NoDefaultBrowserError()))
    }
}
