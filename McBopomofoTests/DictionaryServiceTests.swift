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

import Testing

@testable import McBopomofo

@Suite("Dictionary Service Tests")
final class DictionaryServiceTests {

    @Test
    func testSpeak() {
        let result = DictionaryServices.shared.lookUp(
            phrase: "你", withServiceAtIndex: 0, state: InputState.Empty()
        ) { _ in

        }
        #expect(result)
    }

    @Test
    func testDictionaryService() {
        let count = DictionaryServices.shared.services.count
        for index in 0..<count {
            var callbackCalled = false
            let choosing = InputState.ChoosingCandidate(
                composingBuffer: "hi",
                cursorIndex: 0,
                candidates: [InputState.Candidate(reading: "", value: "", displayText: "", originalValue: "")],
                useVerticalMode: false)
            let selecting = InputState.SelectingDictionary(
                previousState: choosing, selectedString: "你", selectedIndex: 0)

            if DictionaryServices.shared.shouldSkipTest(withServiceAtIndex: index) {
                continue
            }

            let result = DictionaryServices.shared.lookUp(
                phrase: "你", withServiceAtIndex: index, state: selecting
            ) { _ in
                callbackCalled = true
            }
            if !callbackCalled {
                #expect(result)
            }
        }
    }

}
