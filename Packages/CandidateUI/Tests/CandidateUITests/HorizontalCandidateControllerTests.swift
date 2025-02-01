import Cocoa
import Testing

@testable import CandidateUI

@MainActor
@Suite("Test the Horizontal Candidate Controller")
final class HorizontalCandidateControllerTests {

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

    @Test("Test if candidate controller can be positioned correctly when the input position is below the bottom of screen")
    func testPositioning1() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.delegate = mock
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.reloadData()
        controller.visible = true
        controller.set(windowTopLeftPoint: NSPoint(x: -100, y: 0), bottomOutOfScreenAdjustmentHeight: 10)
        Thread.sleep(forTimeInterval: 0.2)
        #expect(controller.window?.frame.minX ?? -1 >= 0)
    }

    @Test("Test if candidate controller can be positioned correctly when the input position is over the top of screen")
    func testPositioning2() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.delegate = mock
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.reloadData()
        controller.visible = true
        let screenRect = NSScreen.main?.frame ?? NSRect.zero
        controller.set(windowTopLeftPoint: NSPoint(x: screenRect.maxX + 100, y: screenRect.maxY + 100), bottomOutOfScreenAdjustmentHeight: 10)
        Thread.sleep(forTimeInterval: 0.2)
        #expect(controller.window?.frame.maxX ?? CGFloat.greatestFiniteMagnitude <= screenRect.maxX)
        #expect(controller.window?.frame.maxY ?? CGFloat.greatestFiniteMagnitude <= screenRect.maxY)
    }

    @Test("Test if the first candidate is selected after reloading data")
    func testReloadData() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.delegate = mock
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.reloadData()
        #expect(controller.selectedCandidateIndex == 0)
    }

    @Test("Test if highlightNextCandidate works correctly")
    func testHighlightNextCandidate() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.delegate = mock
        var result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 1)
        result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 2)
        result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 3)
        result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 4)
        result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 5)
        result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 6)
        result = controller.highlightNextCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 7)
        result = controller.highlightNextCandidate()
        #expect(result == false)
        #expect(controller.selectedCandidateIndex == 7)
    }

    @Test("Test if highlightPreviousCandidate works correctly")
    func testHighlightPreviousCandidate() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.delegate = mock
        _ = controller.showNextPage()
        #expect(controller.selectedCandidateIndex == 4)
        var result = controller.highlightPreviousCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 3)
        result = controller.highlightPreviousCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 2)
        result = controller.highlightPreviousCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 1)
        result = controller.highlightPreviousCandidate()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 0)
        result = controller.highlightPreviousCandidate()
        #expect(result == false)
        #expect(controller.selectedCandidateIndex == 0)
    }

    @Test("Test if showNextPage works correctly")
    func testShowNextPage() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        _ = controller.delegate = mock
        var result = controller.showNextPage()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 4)
        result = controller.showNextPage()
        #expect(result == false)
        #expect(controller.selectedCandidateIndex == 4)
    }

    @Test("Test if showPreviousPage works correctly")
    func testShowPreviousPage() {
        let controller = HorizontalCandidateController()
        let mock = Mock()
        controller.keyLabels = ["1", "2", "3", "4"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.delegate = mock
        _ = controller.showNextPage()
        var result = controller.showPreviousPage()
        #expect(result == true)
        #expect(controller.selectedCandidateIndex == 0)
        result = controller.showPreviousPage()
        #expect(result == false)
        #expect(controller.selectedCandidateIndex == 0)
    }

}
