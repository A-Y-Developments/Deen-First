import XCTest
@testable import surahfocus

@MainActor
final class DowntimeSetupViewModelTests: XCTestCase {
    var sut: DowntimeSetupViewModel!
    var mockTimeLimitService: MockTimeLimitService!
    var mockUserRepository: MockUserRepository!
    var mockScreenTimeService: MockScreenTimeService!

    override func setUp() {
        super.setUp()
        mockTimeLimitService = MockTimeLimitService()
        mockUserRepository = MockUserRepository()
        mockScreenTimeService = MockScreenTimeService()

        sut = DowntimeSetupViewModel(
            timeLimitService: mockTimeLimitService,
            userRepository: mockUserRepository,
            screenTimeService: mockScreenTimeService
        )
    }

    override func tearDown() {
        sut = nil
        mockTimeLimitService = nil
        mockUserRepository = nil
        mockScreenTimeService = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(sut.selectedPrayers.isEmpty)
        XCTAssertTrue(sut.prayerTimes.isEmpty)
        XCTAssertTrue(sut.selectedApps.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.hasSetupCompleted)
    }

    // MARK: - Toggle Prayer

    func testTogglePrayer_AddsPrayer() {
        // Given
        let prayer = DowntimeSchedule.PrayerTime.fajr

        // When
        sut.togglePrayer(prayer)

        // Then
        XCTAssertTrue(sut.isSelected(prayer))
        XCTAssertTrue(sut.selectedPrayers.contains(prayer))
    }

    func testTogglePrayer_RemovesPrayer() {
        // Given
        let prayer = DowntimeSchedule.PrayerTime.fajr
        sut.togglePrayer(prayer)

        // When
        sut.togglePrayer(prayer)

        // Then
        XCTAssertFalse(sut.isSelected(prayer))
        XCTAssertFalse(sut.selectedPrayers.contains(prayer))
    }

    func testTogglePrayer_SetsDefaultTimeRange() {
        // Given
        let prayer = DowntimeSchedule.PrayerTime.fajr

        // When
        sut.togglePrayer(prayer)

        // Then
        let range = sut.getTimeRange(for: prayer)
        XCTAssertEqual(range.start, prayer.defaultTimeRange.start)
        XCTAssertEqual(range.end, prayer.defaultTimeRange.end)
    }

    // MARK: - Save

    func testSave_WithNoUser_ShowsError() async {
        // Given
        mockUserRepository.currentUser = nil
        sut.selectedApps = [Data()]
        sut.togglePrayer(.fajr)

        // When
        await sut.save()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "User not found")
        XCTAssertFalse(sut.hasSetupCompleted)
        XCTAssertFalse(mockScreenTimeService.applyShieldsCalled)
    }

    func testSave_WithPrayers_CreatesTimeLimitsAndAppliesShields() async {
        // Given
        mockUserRepository.currentUser = MockUser()
        sut.selectedApps = [Data()]
        sut.togglePrayer(.fajr)

        // When
        await sut.save()

        // Then
        XCTAssertTrue(mockTimeLimitService.createCalled)
        XCTAssertTrue(mockScreenTimeService.applyShieldsCalled)
        XCTAssertTrue(sut.hasSetupCompleted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testSave_WithMultiplePrayers_CreatesTimeLimitForEach() async {
        // Given
        mockUserRepository.currentUser = MockUser()
        sut.selectedApps = [Data()]
        sut.togglePrayer(.fajr)
        sut.togglePrayer(.zuhr)

        // When
        await sut.save()

        // Then
        XCTAssertEqual(mockTimeLimitService.createCallCount, 2)
        XCTAssertTrue(mockScreenTimeService.applyShieldsCalled)
    }

    // MARK: - Skip

    func testSkip_SetsDowntimeDisabled() {
        // When
        sut.skip()

        // Then
        let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        XCTAssertFalse(sharedDefaults?.bool(forKey: "downtimeEnabled") ?? true)
    }
}

// MARK: - Mocks

final class MockTimeLimitService: TimeLimitService {
    var createCalled = false
    var createCallCount = 0

    func createTimeLimit(userId: UUID, name: String, appTokens: [Data], startTime: String, endTime: String, activeDays: [Int], isAllDay: Bool, prayerTimes: [String]) async throws {
        createCalled = true
        createCallCount += 1
    }

    func getTimeLimits(userId: UUID) async throws -> [TimeLimitSettings] {
        []
    }

    func updateTimeLimit(_ limit: TimeLimitSettings) async throws {
    }

    func deleteTimeLimit(_ limit: TimeLimitSettings) async throws {
    }

    func validateTimeRange(start: String, end: String) -> Bool {
        true
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

final class MockScreenTimeService: ScreenTimeService {
    var applyShieldsCalled = false

    func requestAuthorization() async throws {
    }

    func checkAuthorizationStatus() -> Bool {
        true
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

final class MockUser: User {
    var id: UUID = UUID()
    var hasCompletedOnboarding: Bool = false
    var hasCompletedAppSelection: Bool = false
    var hasCompletedDowntimeSetup: Bool = false
    var hasCompletedPayment: Bool = false
}
