import Foundation
import Cocoa

protocol DictionaryService {
    var name: String { get }
    func lookUp(phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> ()) -> Bool
    func textForMenu(selectedString: String) -> String
    var shouldSkipTest: Bool { get }
}

extension DictionaryService {
    var shouldSkipTest: Bool { false }
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
        NSLocalizedString("Speak", comment: "")
    }

    func lookUp(phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> ()) -> Bool {
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

    var shouldSkipTest: Bool {
        // Note: the test machine may be without Chinese TTS installed and
        // it causes tests to fail.
        true
    }
}

fileprivate struct CharacterInfo: DictionaryService {
    var name: String {
        NSLocalizedString("Character Information", comment: "")
    }

    func lookUp(phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> ()) -> Bool {
        guard let state = state as? InputState.SelectingDictionary else {
            return false
        }
        let newState = InputState.ShowingCharInfo(previousState: state, selectedString: state.selectedPhrase, selectedIndex: serviceIndex)
        stateCallback(newState)
        return false
    }

    func textForMenu(selectedString: String) -> String {
        NSLocalizedString("Character Information", comment: "")
    }

}

fileprivate struct HttpBasedDictionary: DictionaryService, Codable {
    private(set) var name: String
    private(set) var urlTemplate: String

    init(name: String, urlTemplate: String) {
        self.name = name
        self.urlTemplate = urlTemplate
    }

    func lookUp(phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> ()) -> Bool {
        guard let encoded = phrase.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return false
        }
        if let url = URL(string: urlTemplate.replacingOccurrences(of: "(encoded)", with: encoded)) {
            return NSWorkspace.shared.open(url)
        }
        return false
    }

    private enum CodingKeys: String, CodingKey {
        case name, urlTemplate = "url_template"
    }

    func textForMenu(selectedString: String) -> String {
        String(format: NSLocalizedString("Look up \"%1$@\" in %2$@", comment: ""),
                selectedString, name)
    }

    var shouldSkipTest: Bool {
        // Note: Opening URLs appear to be flaky on CI instances
        true
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
        services.append(CharacterInfo())

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

    func lookUp(phrase: String, withServiceAtIndex index: Int, state: InputState, stateCallback: (InputState) -> ()) -> Bool {
        if index >= services.count {
            return false
        }
        let service = services[index]
        return service.lookUp(phrase: phrase, state: state, serviceIndex: index, stateCallback: stateCallback)
    }

    func shouldSkipTest(withServiceAtIndex index: Int ) -> Bool {
        if index >= services.count {
            return false
        }
        let service = services[index]
        return service.shouldSkipTest
    }

}
