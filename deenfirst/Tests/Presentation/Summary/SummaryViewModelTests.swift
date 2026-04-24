import XCTest

@testable import DeenFirst

@MainActor
final class SummaryViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = SummaryViewModel()

        XCTAssertTrue(viewModel.isCalculating)
        XCTAssertEqual(viewModel.percentage, 0)
        XCTAssertEqual(viewModel.progress, 0)
    }

    func testStartCalculation_completes_flipsIsCalculatingFalse() async {
        let viewModel = SummaryViewModel()

        await viewModel.startCalculation(screenWidth: 400)

        XCTAssertFalse(viewModel.isCalculating, "isCalculating must be false once the animation completes")
    }

    func testStartCalculation_completes_percentageReaches100() async {
        let viewModel = SummaryViewModel()

        await viewModel.startCalculation(screenWidth: 400)

        XCTAssertEqual(viewModel.percentage, 100)
    }

    func testStartCalculation_setsProgressToScreenWidthMinus144() async {
        let viewModel = SummaryViewModel()

        await viewModel.startCalculation(screenWidth: 400)

        XCTAssertEqual(viewModel.progress, 256)
    }

    func testStartCalculation_isCalculatingTrueMidFlight() async {
        let viewModel = SummaryViewModel()

        let task = Task { await viewModel.startCalculation(screenWidth: 400) }
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(viewModel.isCalculating)

        await task.value
    }
}
