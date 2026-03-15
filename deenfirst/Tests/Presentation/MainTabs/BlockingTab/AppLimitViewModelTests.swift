import FamilyControls
import XCTest

@testable import DeenFirst

@MainActor
final class AppLimitViewModelTests: XCTestCase {
    var viewModel: AppLimitViewModel!
    var mockService: MockAppLimitServiceForViewModel!
    var mockUserRepository: MockUserRepositoryForAppLimitViewModel!

    override func setUp() async throws {
        mockService = MockAppLimitServiceForViewModel()
        mockUserRepository = MockUserRepositoryForAppLimitViewModel()
        viewModel = AppLimitViewModel(
            appLimitService: mockService,
            userRepository: mockUserRepository,
            skipAuthCheck: true
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
        mockUserRepository = nil
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.settingsName, "")
        XCTAssertTrue(viewModel.selectedApps.isEmpty)
        XCTAssertEqual(viewModel.dailyLimitMinutes, 60)
        XCTAssertTrue(viewModel.activeDays.isEmpty)
        XCTAssertFalse(viewModel.isAllDay)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testToggleAllDay_SetsAllDays() {
        viewModel.toggleAllDay()

        XCTAssertTrue(viewModel.isAllDay)
        XCTAssertEqual(viewModel.activeDays.count, 7)
    }

    func testToggleAllDay_SetsAllDaysWhenToggledOn() {
        viewModel.activeDays = [0, 1, 2]

        viewModel.toggleAllDay()

        XCTAssertTrue(viewModel.isAllDay)
        XCTAssertEqual(viewModel.activeDays.count, 7)
    }

    func testToggleDay_AddsDay() {
        viewModel.toggleDay(0)

        XCTAssertTrue(viewModel.activeDays.contains(0))
    }

    func testToggleDay_RemovesDay() {
        viewModel.activeDays = [0, 1, 2]
        viewModel.isAllDay = true

        viewModel.toggleDay(1)

        XCTAssertFalse(viewModel.activeDays.contains(1))
        XCTAssertFalse(viewModel.isAllDay)
    }

    func testToggleDay_SetsAllDayWhen7Days() {
        for i in 0...6 {
            viewModel.toggleDay(i)
        }

        XCTAssertTrue(viewModel.isAllDay)
    }

    func testSaveSettings_WithEmptyName_UsesDefaultName() async throws {
        mockUserRepository.userToReturn = User(appleUserId: "test")
        viewModel.selectedApps = [Data("test".utf8)]
        viewModel.activeDays = [0, 1, 2]

        await viewModel.saveSettings()

        XCTAssertTrue(mockService.didCallCreate)
        XCTAssertEqual(mockService.lastCreatedLimit?.name, "My App Limit")
        XCTAssertTrue(viewModel.hasSetupCompleted)
    }

    func testSaveSettings_WithCustomName() async throws {
        mockUserRepository.userToReturn = User(appleUserId: "test")
        viewModel.settingsName = "My Custom Limit"
        viewModel.selectedApps = [Data("test".utf8)]
        viewModel.activeDays = [0, 1, 2]

        await viewModel.saveSettings()

        XCTAssertEqual(mockService.lastCreatedLimit?.name, "My Custom Limit")
    }

    func testSaveSettings_WithAllDay_CreatesLimitWith7Days() async throws {
        mockUserRepository.userToReturn = User(appleUserId: "test")
        viewModel.selectedApps = [Data("test".utf8)]
        viewModel.isAllDay = true

        await viewModel.saveSettings()

        XCTAssertEqual(mockService.lastCreatedLimit?.activeDays.count, 7)
        XCTAssertTrue(mockService.lastCreatedLimit?.isAllDay ?? false)
    }

    func testDaysText_WithAllDay() {
        viewModel.isAllDay = true

        XCTAssertEqual(viewModel.daysText, "Every day")
    }

    func testDaysText_WithSpecificDays() {
        viewModel.activeDays = [0, 1, 2]

        XCTAssertEqual(viewModel.daysText, "Sun, Mon, Tue")
    }

    func testTimeLimitText_WithMinutesOnly() {
        viewModel.dailyLimitMinutes = 45

        XCTAssertEqual(viewModel.timeLimitText, "45 min/day")
    }

    func testTimeLimitText_WithHours() {
        viewModel.dailyLimitMinutes = 120

        XCTAssertEqual(viewModel.timeLimitText, "2 hours/day")
    }

    func testAppsCount() {
        viewModel.selectedApps = [Data("app1".utf8), Data("app2".utf8)]

        XCTAssertEqual(viewModel.appsCount, 2)
    }
}

// MARK: - Mocks

class MockAppLimitServiceForViewModel: AppLimitService {
    var didCallCreate = false
    var lastCreatedLimit:
        (
            name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int],
            isAllDay: Bool
        )?

    func createAppLimit(
        userId: UUID, name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int],
        isAllDay: Bool
    ) async throws {
        didCallCreate = true
        lastCreatedLimit = (name, appTokens, dailyLimitMinutes, activeDays, isAllDay)
    }

    func getAppLimits(userId: UUID) async throws -> [AppLimit] {
        []
    }

    func updateAppLimit(_ limit: AppLimit) async throws {}
    func deleteAppLimit(_ limit: AppLimit) async throws {}
}

class MockUserRepositoryForAppLimitViewModel: UserRepository {
    var userToReturn: User?

    func createUser(_ user: User) async throws {}
    func getUser(byAppleUserId appleUserId: String) async throws -> User? { userToReturn }
    func getCurrentUser() async throws -> User? { userToReturn }
    func updateUser(_ user: User) async throws {}
    func deleteCurrentUser() async throws {}
}
