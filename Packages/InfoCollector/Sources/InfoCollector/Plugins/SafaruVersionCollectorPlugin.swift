import AppKit

struct SafaruVersionCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Safari version collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Try standard install location first
        let safariPath = "/Applications/Safari.app"
        if let bundle = Bundle(path: safariPath) ?? Bundle(url: URL(fileURLWithPath: safariPath)) {
            let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = bundle.infoDictionary?["CFBundleVersion"] as? String
            if let short, let build {
                callback(.success("- Safari \(short) (\(build))"))
                return
            } else if let short {
                callback(.success("- Safari \(short)"))
                return
            } else if let build {
                callback(.success("- Safari build \(build)"))
                return
            }
        }

        // Fallback: search common locations in case Safari is relocated
        let candidateDirs = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
        ]
        for dir in candidateDirs {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                if let safariApp = contents.first(where: {
                    $0.caseInsensitiveCompare("Safari.app") == .orderedSame
                }) {
                    let full = (dir as NSString).appendingPathComponent(safariApp)
                    if let bundle = Bundle(path: full) ?? Bundle(url: URL(fileURLWithPath: full)) {
                        let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
                        let build = bundle.infoDictionary?["CFBundleVersion"] as? String
                        if let short, let build {
                            callback(.success("- Safari \(short) (\(build))"))
                            return
                        } else if let short {
                            callback(.success("- Safari \(short)"))
                            return
                        } else if let build {
                            callback(.success("- Safari build \(build)"))
                            return
                        }
                    }
                }
            }
        }

        // If we reach here, we couldn't determine the version
        struct SafariNotFoundError: LocalizedError {
            var errorDescription: String? { "Safari.app not found or no version info available" }
        }
        callback(.failure(SafariNotFoundError()))
    }
}
