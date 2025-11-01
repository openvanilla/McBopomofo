import AppKit

struct SystemLanguageSettingsCollectorPlugin: InfoCollectorPlugin {
    var name: String { "System language settings collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Gather preferred languages and current locale information
        let preferred = Locale.preferredLanguages
        let current = Locale.current

        var lines: [String] = []
        if preferred.isEmpty == false {
            // Show top 5 preferred languages to keep output concise
            let list = preferred.prefix(5).joined(separator: ", ")
            lines.append("- Preferred Languages: \(list)")
        } else {
            lines.append("- Preferred Languages: (none)")
        }

        // Locale identifier and some common components
        lines.append("- Current Locale: \(current.identifier)")

        // Language code
        if #available(iOS 16, macOS 13, *) {
            if let languageCode = current.language.languageCode?.identifier {
                lines.append("- Language Code: \(languageCode)")
            }
        } else {
            if let languageCode = current.languageCode {
                lines.append("- Language Code: \(languageCode)")
            }
        }

        // Region code
        if #available(iOS 16, macOS 13, *) {
            if let regionCode = current.region?.identifier {
                lines.append("- Region Code: \(regionCode)")
            }
        } else {
            if let regionCode = current.regionCode {
                lines.append("- Region Code: \(regionCode)")
            }
        }

        // Currency
        if #available(iOS 16, macOS 13, *) {
            if let currency = current.currency?.identifier {
                lines.append("- Currency: \(currency)")
            }
        } else {
            if let currency = current.currencyCode {
                lines.append("- Currency: \(currency)")
            }
        }

        callback(.success(lines.joined(separator: "\n")))
    }
}
