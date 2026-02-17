import XCTest
@testable import surahfocus

@MainActor
final class AppLimitSetupViewModelTests: XCTestCase {
    var sut: AppLimitSetupViewModel!
    var mockAppLimitService: MockAppLimitService!
    var mockUserRepository: MockUserRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockAppLimitService = MockAppLimitService()
        mockUserRepository = MockUserRepository()
        sut = AppLimitSetupViewModel(
            appLimitService: mockAppLimitService,
            userRepository: mockUserRepository
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockAppLimitService = nil
        mockUserRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(sut.selectedLimit, .sixty)
        XCTAssertTrue(sut.selectedApps.isEmpty)
        XCTAssertFalse(sut.isSaving)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.hasSetupCompleted)
    }

    // MARK: - Set Limit

    func testSetLimit() {
        sut.setLimit(.thirty)
        XCTAssertEqual(sut.selectedLimit, .thirty)
    }

    // MARK: - Save and Continue

    func testSaveAndContinue_WithNoUser_ShowsError() async {
        // Given
        mockUserRepository.currentUser = nil

        // When
        await sut.saveAndContinue()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "User not found")
        XCTAssertFalse(sut.hasSetupCompleted)
        XCTAssertFalse(mockAppLimitService.createCalled)
    }

    func testSaveAndContinue_WithNoApps_ShowsError() async {
        // Given
        mockUserRepository.currentUser = MockUser()

        // When
        await sut.saveAndContinue()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "No apps selected")
        XCTAssertFalse(sut.hasSetupCompleted)
        XCTAssertFalse(mockAppLimitService.createCalled)
    }

    func testSaveAndContinue_WithValidData_CreatesAppLimit() async {
        // Given
        let mockToken = MockApplicationToken()
        await sut.loadApps([mockToken])
        sut.setLimit(.thirty)
        mockUserRepository.currentUser = MockUser()

        // When
        await sut.saveAndContinue()

        // Then
        XCTAssertTrue(mockAppLimitService.createCalled)
        XCTAssertTrue(sut.hasSetupCompleted)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Skip

    func testSkip_SetsLimitDisabledAndCompletes() {
        // Given
        let mockDefaults = MockUserDefaults(suiteName: AppGroupConstants.suiteName)

        // When
        sut.skip()

        // Then
        XCTAssertEqual(mockDefaults.bool(forKey: "appLimitEnabled"), false)
        XCTAssertTrue(sut.hasSetupCompleted)
    }
}

// MARK: - Mocks

final class MockAppLimitServiceForTest: AppLimitService {
    var createCalled = false
    var createCallCount = 0

    func createAppLimit(userId: UUID, name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int], isAllDay: Bool) async throws {
        createCalled = true
        createCallCount += 1
    }

    func getAppLimits(userId: UUID) async throws -> [AppLimit] {
        []
    }

    func updateAppLimit(_ limit: AppLimit) async throws {
    }

    func deleteAppLimit(_ limit: AppLimit) async throws {
    }
}

final class MockUserRepositoryForTest: UserRepository {
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

final class MockUserForTest: User {
    var id: UUID = UUID()
    var hasCompletedOnboarding: Bool = false
    var hasCompletedAppSelection: Bool = false
    var hasCompletedDowntimeSetup: Bool = false
    var hasCompletedPayment: Bool = false
    var hasCompletedAppLimitSetup: Bool = false
}
