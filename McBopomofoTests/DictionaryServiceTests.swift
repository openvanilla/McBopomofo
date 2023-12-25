import XCTest
@testable import McBopomofo

final class DictionaryServiceTests: XCTestCase {

    func testDictionaryService() {
        let count = DictionaryServices.shared.services.count
        for index in 0..<count {
            let result = DictionaryServices.shared.lookUp(phrase: "你", serviceIndex: index)
            XCTAssertTrue(result)
        }
    }

}
