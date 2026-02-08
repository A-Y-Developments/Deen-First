import XCTest
@testable import SurahFocus
import FamilyControls

@MainActor
final class AppSelectionViewModelTests: XCTestCase {
    var viewModel: AppSelectionViewModel!

    override func setUp() {
        viewModel = AppSelectionViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.selectedAppsCount, 0)
        XCTAssertFalse(viewModel.isPresented)
        // timeLimits is private, so we test through the public interface
        XCTAssertEqual(viewModel.getTimeLimit(tokenHash: "test_token"), .sixty)
    }

    // MARK: - Picker Tests

    func testOpenPicker() {
        viewModel.openPicker()
        XCTAssertTrue(viewModel.isPresented)
    }

    // MARK: - Selection Tests

    func testUpdateSelectionWithApps() {
        let selection = FamilyActivitySelection()
        // Note: Cannot create actual ApplicationToken in tests
        // This tests the update logic
        viewModel.updateSelection(selection)

        XCTAssertEqual(viewModel.selectedAppsCount, 0)
    }

    // MARK: - Time Limit Tests

    func testSetTimeLimit() {
        let tokenHash = "test_token_123"
        let limit = TimeLimit.thirty

        viewModel.setTimeLimit(limit, tokenHash: tokenHash)

        XCTAssertEqual(viewModel.getTimeLimit(tokenHash: tokenHash), .thirty)
    }

    func testGetTimeLimitReturnsDefault() {
        let unknownToken = "unknown_token"

        XCTAssertEqual(viewModel.getTimeLimit(tokenHash: unknownToken), .sixty)
    }

    func testTimeLimitDefaultsToSixty() {
        XCTAssertEqual(viewModel.getTimeLimit(tokenHash: "any_token"), .sixty)
    }

    // MARK: - Token Hash Tests

    func testTokenHashGeneratesString() {
        // Note: Cannot test with actual token, but verify method exists
        let hash = viewModel.tokenHash(from: "test" as AnyHashable)

        XCTAssertFalse(hash.isEmpty)
    }

    // Note: Full FamilyActivityPicker tests require physical device
    // These are structural tests only
}
