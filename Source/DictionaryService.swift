import Foundation
import Cocoa

protocol DictionaryService {
    var name: String { get }
    func lookUp(phrase: String) -> Bool
}

fileprivate struct MacOSBuiltInDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("Dictionary app", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "dict://\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct MoeDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("MOE Dictionary", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://www.moedict.tw/\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct GoogleSearch: DictionaryService {
    var name: String {
        return NSLocalizedString("Google", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct MoeRevisedDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部重編國語詞典修訂本", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://dict.revised.moe.edu.tw/search.jsp?md=1&word=\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct MoeConcisedDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部國語詞典簡邊本", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://dict.concised.moe.edu.tw/search.jsp?md=1&word=\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct MoeIdiomsDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部成語典", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://dict.idioms.moe.edu.tw/idiomList.jsp?idiom=\(encoded)&qMd=0&qTp=1&qTp=2") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}


class DictionaryServices: NSObject {
    @objc static var shared = DictionaryServices()
    var services: [DictionaryService] = [
        MacOSBuiltInDictionary(),
        MoeDictionary(),
        GoogleSearch(),
        MoeRevisedDictionary(),
        MoeConcisedDictionary(),
        MoeIdiomsDictionary(),
    ]

    func lookUp(phrase: String, serviceIndex: Int) -> Bool {
        if serviceIndex >= services.count {
            return false
        }
        let service = services[serviceIndex]
        return service.lookUp(phrase: phrase)
    }
}
