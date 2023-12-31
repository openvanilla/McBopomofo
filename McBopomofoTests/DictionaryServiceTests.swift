import XCTest
@testable import McBopomofo

final class DictionaryServiceTests: XCTestCase {

    func testSpeak() {
        let result = DictionaryServices.shared.lookUp(phrase: "你", withServiceAtIndex: 0, state: InputState.Empty()) { _ in

        }
        XCTAssertTrue(result)
    }

    func testDictionaryService() {
        let count = DictionaryServices.shared.services.count
        for index in 0..<count {
            var callbackCalled = false
            let choosing = InputState.ChoosingCandidate(composingBuffer: "hi", cursorIndex: 0, candidates: [InputState.Candidate(reading: "", value: "", displayText: "")], useVerticalMode: false)
            let selecting =  InputState.SelectingDictionary(previousState: choosing, selectedString: "你", selectedIndex: 0)
            let result = DictionaryServices.shared.lookUp(phrase: "你", withServiceAtIndex: index, state: selecting) { _ in
                callbackCalled = true
            }
            if !callbackCalled {
                XCTAssertTrue(result)
            }
        }
    }

}
