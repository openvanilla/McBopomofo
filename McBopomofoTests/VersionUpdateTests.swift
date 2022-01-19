import XCTest
@testable import McBopomofo

class VersionUpdateApiTests: XCTestCase {
    func testFetchVersionUpdateInfo() {
        let exp = self.expectation(description: "wait for 3 seconds")
        _ = VersionUpdateApi.check(forced: true) { result in
            exp.fulfill()
            switch result {
            case .success(_):
                break
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        self.wait(for: [exp], timeout: 20.0)
    }
}


