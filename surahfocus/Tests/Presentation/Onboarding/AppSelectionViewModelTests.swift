import XCTest
import XCTestFailReporter
@testable import surahfocus

@MainActor
final class AppSelectionViewModelTests: XCTestCase {
    var sut: AppSelectionViewModel!
    var mockAppLimitService: MockAppLimitService!
    var mockScreenTimeService: MockScreenTimeService!
    var mockUserRepository: MockUserRepository!

    override func setUp() {
        super.setUp()
        mockAppLimitService = MockAppLimitService()
        mockScreenTimeService = MockScreenTimeService()
        mockUserRepository = MockUserRepository()

        sut = AppSelectionViewModel(
            appLimitService: mockAppLimitService,
            screenTimeService: mockScreenTimeService,
            userRepository: mockUserRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockAppLimitService = nil
        mockScreenTimeService = nil
        mockUserRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(sut.selection.applicationTokens.isEmpty)
        XCTAssertTrue(sut.selection.categoryTokens.isEmpty)
        XCTAssertEqual(sut.selectedAppsCount, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.hasSetupCompleted)
    }

    // MARK: - Save and Apply

    func testSaveAndApply_WithNoApps_ShowsError() async {
        // Given
        mockUserRepository.currentUser = MockUser()

        // When
        await sut.saveAndApply()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Please select at least one app")
        XCTAssertFalse(sut.hasSetupCompleted)
        XCTAssertFalse(sut.isLoading)
    }

    func testSaveAndApply_WithApps_CreatesAppLimitAndAppliesShields() async {
        // Given
        let mockToken = MockApplicationToken()
        sut.selection.applicationTokens.insert(mockToken)
        sut.selectedAppsCount = 1
        mockUserRepository.currentUser = MockUser()

        // When
        await sut.saveAndApply()

        // Then
        XCTAssertTrue(mockAppLimitService.createCalled)
        XCTAssertTrue(mockScreenTimeService.applyShieldsCalled)
        XCTAssertTrue(sut.hasSetupCompleted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testSaveAndApply_WhenUserNotFound_ShowsError() async {
        // Given
        let mockToken = MockApplicationToken()
        sut.selection.applicationTokens.insert(mockToken)
        sut.selectedAppsCount = 1
        mockUserRepository.currentUser = nil

        // When
        await sut.saveAndApply()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "User not found")
        XCTAssertFalse(sut.hasSetupCompleted)
        XCTAssertFalse(mockAppLimitService.createCalled)
        XCTAssertFalse(mockScreenTimeService.applyShieldsCalled)
    }

    // MARK: - Time Limits

    func testSetTimeLimit_SavesCorrectLimit() {
        // Given
        let tokenHash = "12345"

        // When
        sut.setTimeLimit(.thirty, tokenHash: tokenHash)

        // Then
        XCTAssertEqual(sut.getTimeLimit(tokenHash: tokenHash), .thirty)
    }

    func testGetTimeLimit_DefaultReturnsSixty() {
        // Given
        let tokenHash = "nonexistent"

        // When
        let limit = sut.getTimeLimit(tokenHash: tokenHash)

        // Then
        XCTAssertEqual(limit, .sixty)
    }
}

// MARK: - Mocks

final class MockAppLimitService: AppLimitService {
    var createCalled = false
    var createAppLimitCalled = false

    func createAppLimit(userId: UUID, name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int], isAllDay: Bool) async throws {
        createAppLimitCalled = true
    }

    func getAppLimits(userId: UUID) async throws -> [AppLimit] {
        []
    }

    func updateAppLimit(_ limit: AppLimit) async throws {
        createCalled = true
    }

    func deleteAppLimit(_ limit: AppLimit) async throws {
    }
}

final class MockScreenTimeService: ScreenTimeService {
    var applyShieldsCalled = false
    var authorizationStatus: Bool = true

    func requestAuthorization() async throws {
    }

    func checkAuthorizationStatus() -> Bool {
        authorizationStatus
    }

    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws {
    }

    func loadAppSelection() async throws -> FamilyActivitySelection {
        FamilyActivitySelection()
    }

    func clearAppSelection() async throws {
    }

    func applyShields() async throws {
        applyShieldsCalled = true
    }

    func removeShields() async throws {
    }

    func isShieldsActive() async throws -> Bool {
        false
    }

    func startQuranSession(surahId: Int) async throws {
    }

    func endQuranSession() async throws {
    }

    func getBlockedAppsInfo(userId: UUID) async throws -> [BlockedAppInfo] {
        []
    }

    func removeAppFromBlocking(tokenData: Data, userId: UUID) async throws {
    }

    func updateAppTimeLimit(tokenData: Data, limit: TimeLimit) async throws {
    }
}

final class MockUserRepository: UserRepository {
    var currentUser: User?

    func getCurrentUser() async throws -> User? {
        currentUser
    }

    func createUser(_ user: User) async throws {
    }

    func updateUser(_ user: User) async throws {
    }

    func deleteUser(_ user: User) async throws {
    }
}

final class MockUser: User {
    var id: UUID = UUID()
    var hasCompletedOnboarding: Bool = false
    var hasCompletedAppSelection: Bool = false
    var hasCompletedDowntimeSetup: Bool = false
    var hasCompletedPayment: Bool = false
}

final class MockApplicationToken: ApplicationToken {
    // Mock implementation for testing
}
