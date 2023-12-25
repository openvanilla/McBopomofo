import Foundation
import Cocoa

protocol DictionaryService {
    var name: String { get }
    func lookUp(phrase: String) -> Bool
    func textForMenu(selectedString: String) -> String
}

extension DictionaryService {
    func textForMenu(selectedString: String) -> String {
        String(format: NSLocalizedString("Look up \"%1$@\" in %2$@", comment: ""),
                selectedString, name)
    }
}

fileprivate struct Speak: DictionaryService {
    let speechSynthesizer: NSSpeechSynthesizer? = {
        let voices = NSSpeechSynthesizer.availableVoices
        let firstZhTWVoice = voices.first { voice in
            voice.rawValue.contains("zh-TW")
        }
        guard let firstZhTWVoice else {
            return nil
        }
        return NSSpeechSynthesizer.init(voice: firstZhTWVoice)
    }()

    var name: String {
        return NSLocalizedString("Speak", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let speechSynthesizer else {
            return false
        }
        speechSynthesizer.stopSpeaking()
        speechSynthesizer.startSpeaking(phrase)
        return true
    }

    func textForMenu(selectedString: String) -> String {
        String(format: NSLocalizedString("Speak \"%@\"…", comment: ""), selectedString)
    }
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
        return NSLocalizedString("MOE Dict", comment: "")
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

fileprivate struct MoeDicHoloDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("MOE Dict (Holo)", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://www.moedict.tw/'\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct MoeDicHakkaDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("MOE Dict (Hakka)", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://www.moedict.tw/:\(encoded)") {
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
        return NSLocalizedString("教育部國語詞典簡編本", comment: "")
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

fileprivate struct MoeVariantsDictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("教育部異體字字典", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://dict.variants.moe.edu.tw/variants/rbt/query_result.do?from=standard&search_text=\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct KangXiictionary: DictionaryService {
    var name: String {
        return NSLocalizedString("康熙字典網上版", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://www.kangxizidian.com/search/index.php?stype=Word&sword=\(encoded)&detail=n") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}

fileprivate struct UnihanDatabase: DictionaryService {
    var name: String {
        return NSLocalizedString("Unihan Database", comment: "")
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: "https://www.unicode.org/cgi-bin/GetUnihanData.pl?codepoint=\(encoded)") {
            return NSWorkspace.shared.open(url)
        }
        return false
    }
}


class DictionaryServices: NSObject {
    @objc static var shared = DictionaryServices()
    var services: [DictionaryService] = [
        Speak(),
        MacOSBuiltInDictionary(),
        MoeDictionary(),
        MoeDicHoloDictionary(),
        MoeDicHakkaDictionary(),
        GoogleSearch(),
        MoeRevisedDictionary(),
        MoeConcisedDictionary(),
        MoeIdiomsDictionary(),
        MoeVariantsDictionary(),
        KangXiictionary(),
        UnihanDatabase(),
    ]

    func lookUp(phrase: String, serviceIndex: Int) -> Bool {
        if serviceIndex >= services.count {
            return false
        }
        let service = services[serviceIndex]
        return service.lookUp(phrase: phrase)
    }
}
