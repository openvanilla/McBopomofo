import XCTest
@testable import CandidateUI

class HorizontalCandidateControllerTests: XCTestCase {

    class Mock: CandidateControllerDelegate {
        let candidates = ["A", "B", "C", "D", "E", "F", "G", "H"]
        var selected: String?
        func candidateCountForController(_ controller: CandidateController) -> UInt {
            UInt(candidates.count)
        }

        func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt) -> String {
            candidates[Int(index)]
        }

        func candidateController(_ controller: CandidateController, didSelectCandidateAtIndex index: UInt) {
            selected = candidates[Int(index)]
        }
    }

    func testReloadData() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.delegate = mock
        controller.keyLabels = ["1", "2", "3", "4"]
        controller.reloadData()
        XCTAssert(controller.selectedCandidateIndex == 0)
    }

    func testHighlightNextCandidate() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"]
        controller.delegate = mock
        var result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 1)
        result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 2)
        result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 3)
        result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 4)
        result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 5)
        result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 6)
        result = controller.highlightNextCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 7)
        result = controller.highlightNextCandidate()
        XCTAssert(result == false)
        XCTAssert(controller.selectedCandidateIndex == 7)
    }

    func testHighlightPreviousCandidate() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"]
        controller.delegate = mock
        _ = controller.showNextPage()
        XCTAssert(controller.selectedCandidateIndex == 4)
        var result = controller.highlightPreviousCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 3)
        result = controller.highlightPreviousCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 2)
        result = controller.highlightPreviousCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 1)
        result = controller.highlightPreviousCandidate()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 0)
        result = controller.highlightPreviousCandidate()
        XCTAssert(result == false)
        XCTAssert(controller.selectedCandidateIndex == 0)
    }

    func testShowNextPage() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"]
        _ = controller.delegate = mock
        var result = controller.showNextPage()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 4)
        result = controller.showNextPage()
        XCTAssert(result == false)
        XCTAssert(controller.selectedCandidateIndex == 4)
    }

    func testShowPreviousPage() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"]
        controller.delegate = mock
        _ = controller.showNextPage()
        var result = controller.showPreviousPage()
        XCTAssert(result == true)
        XCTAssert(controller.selectedCandidateIndex == 0)
        result = controller.showPreviousPage()
        XCTAssert(result == false)
        XCTAssert(controller.selectedCandidateIndex == 0)
    }

}
