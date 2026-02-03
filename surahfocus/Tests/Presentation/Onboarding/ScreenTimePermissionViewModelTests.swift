import XCTest
@testable import SurahFocus
import FamilyControls

@MainActor
final class ScreenTimePermissionViewModelTests: XCTestCase {
    var viewModel: ScreenTimePermissionViewModel!

    override func setUp() {
        viewModel = ScreenTimePermissionViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isAuthorized)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - Authorization Check Tests

    func testCheckAuthorization() {
        // Note: This will return false in test environment
        // without actual FamilyControls authorization
        viewModel.checkAuthorization()

        // In test environment, authorization status is unknown
        // This test verifies the method doesn't crash
        XCTAssertNotNil(viewModel)
    }

    // MARK: - Skip Tests

    func testSkipDoesNotCrash() {
        // Skip should be a no-op in terms of state
        viewModel.skip()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isAuthorized)
    }

    // Note: Full authorization tests require physical device
    // These are structural tests only
}
