import Foundation
import Cocoa

protocol DictionaryService {
    var name: String { get }
    func lookUp(phrase: String) -> Bool
    func textForMenu(selectedString: String) -> String
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

fileprivate struct HttpBasedDictionary: DictionaryService, Codable {
    private (set) var name: String
    private (set) var urlTemplate: String

    init(name: String, urlTemplate: String) {
        self.name = name
        self.urlTemplate = urlTemplate
    }

    func lookUp(phrase: String) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: urlTemplate.replacingOccurrences(of: "(encoded)", with: encoded)) {
            return NSWorkspace.shared.open(url)
        }
        return false
    }

    private enum CodingKeys : String, CodingKey {
        case name, urlTemplate = "url_template"
    }

    func textForMenu(selectedString: String) -> String {
        String(format: NSLocalizedString("Look up \"%1$@\" in %2$@", comment: ""),
               selectedString, name)
    }

}


class DictionaryServices: NSObject {

    private struct ServiceWrapper: Codable {
        var services: [HttpBasedDictionary]
    }

    @objc static var shared = DictionaryServices()

    var services: [DictionaryService]

    override init() {
        var services: [DictionaryService] = []
        services.append(Speak())

        let bundle = Bundle(for: DictionaryServices.self)
        if let jsonPath = bundle.url(forResource: "dictionary_service", withExtension: "json"),
           let data = try? Data(contentsOf: jsonPath) {
            let decoder = JSONDecoder()
            if let httpServices = try? decoder.decode(ServiceWrapper.self, from: data) {
                services.append(contentsOf: httpServices.services)
            }
        }

        self.services = services
    }


    func lookUp(phrase: String, withServiceAtIndex index: Int) -> Bool {
        if index >= services.count {
            return false
        }
        let service = services[index]
        return service.lookUp(phrase: phrase)
    }
}
