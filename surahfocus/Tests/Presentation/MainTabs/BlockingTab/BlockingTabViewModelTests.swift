import XCTest
import FamilyControls
@testable import SurahFocus

@MainActor
final class BlockingTabViewModelTests: XCTestCase {
    var viewModel: BlockingTabViewModel!
    var mockAppLimitService: MockAppLimitServiceForBlockingTab!
    var mockTimeLimitService: MockTimeLimitServiceForBlockingTab!
    var mockUserRepository: MockUserRepositoryForViewModel!

    override func setUp() async throws {
        mockAppLimitService = MockAppLimitServiceForBlockingTab()
        mockTimeLimitService = MockTimeLimitServiceForBlockingTab()
        mockUserRepository = MockUserRepositoryForViewModel()
        viewModel = BlockingTabViewModel(
            appLimitService: mockAppLimitService,
            timeLimitService: mockTimeLimitService,
            userRepository: mockUserRepository
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockAppLimitService = nil
        mockTimeLimitService = nil
        mockUserRepository = nil
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.appLimits.isEmpty)
        XCTAssertTrue(viewModel.timeLimits.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadBlockedApps_PopulatesLists() async throws {
        let userId = UUID()
        let appLimit = AppLimit(
            userId: userId,
            name: "Test App Limit",
            appTokens: [Data("test".utf8)],
            dailyLimitMinutes: 60,
            activeDays: [0, 1, 2],
            isAllDay: false
        )
        let timeLimit = TimeLimitSettings(
            userId: userId,
            name: "Test Time Limit",
            appTokens: [Data("test".utf8)],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [0, 1, 2],
            isAllDay: false,
            prayerTimes: []
        )

        mockAppLimitService.appLimitsToReturn = [appLimit]
        mockTimeLimitService.timeLimitsToReturn = [timeLimit]
        mockUserRepository.userToReturn = User(appleUserId: "test")

        await viewModel.loadBlockedApps()

        XCTAssertEqual(viewModel.appLimits.count, 1)
        XCTAssertEqual(viewModel.timeLimits.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadBlockedApps_SetsError_WhenServiceFails() async {
        mockAppLimitService.shouldThrowError = true
        mockUserRepository.userToReturn = User(appleUserId: "test")

        await viewModel.loadBlockedApps()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.appLimits.isEmpty)
        XCTAssertTrue(viewModel.timeLimits.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadBlockedApps_SetsError_WhenUserNotFound() async {
        mockUserRepository.userToReturn = nil

        await viewModel.loadBlockedApps()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "User not found")
    }

    func testDeleteAppLimit_CallsService() async throws {
        let userId = UUID()
        let appLimit = AppLimit(
            userId: userId,
            name: "Test",
            appTokens: [],
            dailyLimitMinutes: 60,
            activeDays: [],
            isAllDay: false
        )

        mockAppLimitService.appLimitsToReturn = []
        mockUserRepository.userToReturn = User(appleUserId: "test")

        await viewModel.deleteAppLimit(appLimit)

        XCTAssertTrue(mockAppLimitService.didCallUpdate)
    }

    func testDeleteTimeLimit_CallsService() async throws {
        let userId = UUID()
        let timeLimit = TimeLimitSettings(
            userId: userId,
            name: "Test",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )

        mockTimeLimitService.timeLimitsToReturn = []
        mockUserRepository.userToReturn = User(appleUserId: "test")

        await viewModel.deleteTimeLimit(timeLimit)

        XCTAssertTrue(mockTimeLimitService.didCallUpdate)
    }

    func testBlockedAppsCount_ReturnsCorrectCount() {
        viewModel.appLimits = [
            AppLimit(userId: UUID(), name: "Limit1", appTokens: [], dailyLimitMinutes: 60, activeDays: [], isAllDay: false),
            AppLimit(userId: UUID(), name: "Limit2", appTokens: [], dailyLimitMinutes: 60, activeDays: [], isAllDay: false)
        ]
        viewModel.timeLimits = [
            TimeLimitSettings(userId: UUID(), name: "Limit3", appTokens: [], startTime: "09:00", endTime: "17:00", activeDays: [], isAllDay: false, prayerTimes: [])
        ]

        XCTAssertEqual(viewModel.blockedAppsCount, 3)
    }

    func testHasApps_ReturnsTrue_WhenAppsExist() {
        viewModel.appLimits = [
            AppLimit(userId: UUID(), name: "Limit1", appTokens: [], dailyLimitMinutes: 60, activeDays: [], isAllDay: false)
        ]

        XCTAssertTrue(viewModel.hasApps)
    }

    func testHasApps_ReturnsFalse_WhenNoApps() {
        viewModel.appLimits = []
        viewModel.timeLimits = []

        XCTAssertFalse(viewModel.hasApps)
    }
}

// MARK: - Mocks

class MockAppLimitServiceForBlockingTab: AppLimitService {
    var appLimitsToReturn: [AppLimit] = []
    var shouldThrowError = false
    var didCallUpdate = false

    func createAppLimit(userId: UUID, name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int], isAllDay: Bool) async throws {
    }

    func getAppLimits(userId: UUID) async throws -> [AppLimit] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        return appLimitsToReturn
    }

    func updateAppLimit(_ limit: AppLimit) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        didCallUpdate = true
    }

    func deleteAppLimit(_ limit: AppLimit) async throws {
    }
}

class MockTimeLimitServiceForBlockingTab: TimeLimitService {
    var timeLimitsToReturn: [TimeLimitSettings] = []
    var shouldThrowError = false
    var didCallUpdate = false

    func createTimeLimit(userId: UUID, name: String, appTokens: [Data], startTime: String, endTime: String, activeDays: [Int], isAllDay: Bool, prayerTimes: [String]) async throws {
    }

    func getTimeLimits(userId: UUID) async throws -> [TimeLimitSettings] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        return timeLimitsToReturn
    }

    func updateTimeLimit(_ limit: TimeLimitSettings) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        didCallUpdate = true
    }

    func deleteTimeLimit(_ limit: TimeLimitSettings) async throws {
    }

    func validateTimeRange(start: String, end: String) -> Bool {
        return true
    }
}

class MockUserRepositoryForViewModel: UserRepository {
    var userToReturn: User?

    func createUser(_ user: User) async throws {
    }

    func getUser(byAppleUserId appleUserId: String) async throws -> User? {
        return userToReturn
    }

    func getCurrentUser() async throws -> User? {
        return userToReturn
    }

    func updateUser(_ user: User) async throws {
    }

    func deleteCurrentUser() async throws {
    }
}
