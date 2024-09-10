// Copyright (c) 2022 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Cocoa
import Foundation

/// The standard interface for all dictionary services.
///
/// A dictionary service is available in the menu that appears when a user
/// presses the question key while selecting a candidate or a range in the
/// composing buffer. The service facilitates looking up the selected phrase
/// using a local dictionary app or an online dictionary website.
protocol DictionaryService {
    /// Name of the dictionary service.
    var name: String { get }

    /// Look up in the dictionary service.
    /// - Parameters:
    ///   - phrase: The given phrase to look up.
    ///   - state: The current input state.
    ///   - serviceIndex: The index of the dictionary service in the input menu.
    ///   - stateCallback: The state callback which can update the input state.
    /// - Returns: If the phrase exists in the dictionary service.
    func lookUp(
        phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> Void
    ) -> Bool

    /// The text displayed in the input menu.
    func textForMenu(selectedString: String) -> String

    /// If the unit tests should skip the service.
    var shouldSkipTest: Bool { get }
}

extension DictionaryService {
    var shouldSkipTest: Bool { false }
}

/// The dictionary service that helps to speak out the given phrase.
private struct Speak: DictionaryService {
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

    func lookUp(
        phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> Void
    ) -> Bool {
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

/// The dictionary service that helps to display the character information.
private struct CharacterInfo: DictionaryService {
    var name: String {
        NSLocalizedString("Character Information", comment: "")
    }

    func lookUp(
        phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> Void
    ) -> Bool {
        guard let state = state as? InputState.SelectingDictionary else {
            return false
        }
        let newState = InputState.ShowingCharInfo(
            previousState: state, selectedString: state.selectedPhrase, selectedIndex: serviceIndex)
        stateCallback(newState)
        return false
    }

    func textForMenu(selectedString: String) -> String {
        NSLocalizedString("Character Information", comment: "")
    }

}

/// The dictionary service that helps to open a website.
private struct HttpBasedDictionary: DictionaryService, Codable {
    private(set) var name: String
    private(set) var urlTemplate: String

    init(name: String, urlTemplate: String) {
        self.name = name
        self.urlTemplate = urlTemplate
    }

    func lookUp(
        phrase: String, state: InputState, serviceIndex: Int, stateCallback: (InputState) -> Void
    ) -> Bool {
        guard
            let encoded = phrase.addingPercentEncoding(
                withAllowedCharacters: CharacterSet.urlQueryAllowed)
        else {
            return false
        }
        if let url = URL(string: urlTemplate.replacingOccurrences(of: "(encoded)", with: encoded)) {
            return NSWorkspace.shared.open(url)
        }
        return false
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case urlTemplate = "url_template"
    }

    func textForMenu(selectedString: String) -> String {
        String(
            format: NSLocalizedString("Look up \"%1$@\" in %2$@", comment: ""),
            selectedString, name)
    }

    var shouldSkipTest: Bool {
        // Note: Opening URLs appear to be flaky on CI instances
        true
    }
}

/// The facade of the dictionary services.
class DictionaryServices: NSObject {

    private struct ServiceWrapper: Codable {
        var services: [HttpBasedDictionary]
    }

    /// The singleton object.
    @objc static var shared = DictionaryServices()

    var services: [DictionaryService]

    override init() {
        var services: [DictionaryService] = []
        services.append(Speak())
        services.append(CharacterInfo())

        let bundle = Bundle(for: DictionaryServices.self)
        if let jsonPath = bundle.url(forResource: "dictionary_service", withExtension: "json"),
            let data = try? Data(contentsOf: jsonPath)
        {
            let decoder = JSONDecoder()
            if let httpServices = try? decoder.decode(ServiceWrapper.self, from: data) {
                services.append(contentsOf: httpServices.services)
            }
        }

        self.services = services
    }

    func lookUp(
        phrase: String, withServiceAtIndex index: Int, state: InputState,
        stateCallback: (InputState) -> Void
    ) -> Bool {
        if index >= services.count {
            return false
        }
        let service = services[index]
        return service.lookUp(
            phrase: phrase, state: state, serviceIndex: index, stateCallback: stateCallback)
    }

    func shouldSkipTest(withServiceAtIndex index: Int) -> Bool {
        if index >= services.count {
            return false
        }
        let service = services[index]
        return service.shouldSkipTest
    }

}
