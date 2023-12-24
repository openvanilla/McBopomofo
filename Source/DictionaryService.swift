import Foundation
import Cocoa

protocol DictionaryService {
    var name: String { get }
    func lookup(phrase: String)
}

fileprivate struct MacOSBuiltInDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("Dictionary app", comment: "")
    }
    func lookup(phrase: String) {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return
        }
        if let url = URL(string: "dict://\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}

fileprivate struct MoeDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("MOE Dictionary", comment: "")
    }
    func lookup(phrase: String) {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return
        }
        if let url = URL(string: "https://www.moedict.tw/\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}

fileprivate struct GoogleSearch: DictionaryService {
    var name: String {
        return NSLocalizedString("Google", comment: "")
    }
    func lookup(phrase: String) {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return
        }
        if let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}

fileprivate struct MoeRevisedDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部重編國語詞典修訂本", comment: "")
    }
    func lookup(phrase: String) {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return
        }
        if let url = URL(string: "https://dict.revised.moe.edu.tw/search.jsp?md=1&word=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}

fileprivate struct MoeConcisedDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部國語詞典簡邊本", comment: "")
    }
    func lookup(phrase: String) {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return
        }
        if let url = URL(string: "https://dict.concised.moe.edu.tw/search.jsp?md=1&word=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}

fileprivate struct MoeIdionmDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部成語典", comment: "")
    }
    func lookup(phrase: String) {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return
        }
        if let url = URL(string: "https://dict.idioms.moe.edu.tw/idiomList.jsp?idiom=\(encoded)&qMd=0&qTp=1&qTp=2") {
            NSWorkspace.shared.open(url)
        }
    }
}



class DictionaryServices: NSObject {
    @objc static var shared = DictionaryServices()
    var services:[DictionaryService] = [
        MacOSBuiltInDictionary(),
        MoeDictionary(),
        GoogleSearch(),
        MoeRevisedDictionary(),
        MoeConcisedDictionary(),
        MoeIdionmDictionary(),
    ]

    func lookup(phrase: String, serviceIndex: Int) {
        if serviceIndex >= services.count {
            return
        }
        let service = services[serviceIndex]
        service.lookup(phrase: phrase)
    }
}
