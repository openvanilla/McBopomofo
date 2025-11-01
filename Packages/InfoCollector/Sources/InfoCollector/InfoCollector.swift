import Foundation

// MARK: -

@objc
public class InfoCollector: NSObject {
    public static func generate(callback: @escaping (String) -> Void) {
        let plugins: [InfoCollectorPlugin] = [
            MachineModelCollectorPlugin(),
            MacVersionCollectorPlugin(),
            SystemLanguageSettingsCollectorPlugin(),
            KeyboardTypeCollectorPlugin(),
            ActiveInputSourceListCollectorPlugin(),
            DefaultWebBrowserCollectorPlugin(),
            SafaruVersionCollectorPlugin(),
        ]

        let group = DispatchGroup()
        var string = ""
        let lock = NSLock()

        for plugin in plugins {
            group.enter()
            plugin.collect { result in
                if case .success(let info) = result {
                    lock.lock()
                    string.append(info + "\n")
                    lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            callback(string)
        }
    }
}
