import XCTest
import FamilyControls
@testable import SurahFocus

@MainActor
final class TimeLimitViewModelTests: XCTestCase {
    var viewModel: TimeLimitViewModel!
    var mockService: MockTimeLimitServiceForViewModel!
    var mockUserRepository: MockUserRepositoryForTimeLimitViewModel!

    override func setUp() async throws {
        mockService = MockTimeLimitServiceForViewModel()
        mockUserRepository = MockUserRepositoryForTimeLimitViewModel()
        viewModel = TimeLimitViewModel(
            timeLimitService: mockService,
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
        XCTAssertFalse(viewModel.isAllDay)
        XCTAssertTrue(viewModel.activeDays.isEmpty)
        XCTAssertTrue(viewModel.selectedPrayers.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testToggleAllDay_SetsAllDays() {
        viewModel.toggleAllDay()

        XCTAssertTrue(viewModel.isAllDay)
        XCTAssertEqual(viewModel.activeDays.count, 7)
    }

    func testToggleDay_AddsAndRemovesDay() {
        viewModel.toggleDay(0)
        XCTAssertTrue(viewModel.activeDays.contains(0))

        viewModel.toggleDay(0)
        XCTAssertFalse(viewModel.activeDays.contains(0))
    }

    func testTogglePrayer_AddsAndRemoves() {
        viewModel.togglePrayer("subuh")
        XCTAssertTrue(viewModel.selectedPrayers.contains("subuh"))

        viewModel.togglePrayer("subuh")
        XCTAssertFalse(viewModel.selectedPrayers.contains("subuh"))
    }

    func testGetPrayerTimeRange_ReturnsCorrectRanges() {
        let subuh = viewModel.getPrayerTimeRange("subuh")
        XCTAssertEqual(subuh.start, "04:30")
        XCTAssertEqual(subuh.end, "06:00")

        let maghrib = viewModel.getPrayerTimeRange("maghrib")
        XCTAssertEqual(maghrib.start, "18:15")
        XCTAssertEqual(maghrib.end, "19:15")
    }

    func testValidateTimeRange_ValidRange() {
        viewModel.startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        viewModel.endTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

        XCTAssertTrue(viewModel.validateTimeRange())
    }

    func testValidateTimeRange_InvalidRange() {
        viewModel.startTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
        viewModel.endTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

        XCTAssertFalse(viewModel.validateTimeRange())
    }

    func testDaysText_WithAllDay() {
        viewModel.isAllDay = true

        XCTAssertEqual(viewModel.daysText, "Every day")
    }

    func testDaysText_WithSpecificDays() {
        viewModel.activeDays = [0, 1, 2, 3, 4]

        XCTAssertEqual(viewModel.daysText, "Sun, Mon, Tue, Wed, Thu")
    }

    func testTimeRangeText() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let expectedStart = formatter.string(from: viewModel.startTime)
        let expectedEnd = formatter.string(from: viewModel.endTime)

        XCTAssertTrue(viewModel.timeRangeText.contains(expectedStart))
        XCTAssertTrue(viewModel.timeRangeText.contains(expectedEnd))
    }

    func testPrayersText_WithSelectedPrayers() {
        viewModel.selectedPrayers = ["subuh", "maghrib"]

        XCTAssertTrue(viewModel.prayersText.contains("Fajr"))
        XCTAssertTrue(viewModel.prayersText.contains("Maghrib"))
        XCTAssertTrue(viewModel.prayersText.contains("/"))
    }

    func testPrayersText_WithNoPrayers() {
        XCTAssertEqual(viewModel.prayersText, "None")
    }

    func testSaveSettings_WithValidData() async throws {
        mockUserRepository.userToReturn = User(appleUserId: "test")
        viewModel.selectedApps = [Data("test".utf8)]
        viewModel.activeDays = [0, 1, 2]
        viewModel.startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        viewModel.endTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

        await viewModel.saveSettings()

        XCTAssertTrue(mockService.didCallCreate)
        XCTAssertTrue(viewModel.hasSetupCompleted)
    }

    func testSaveSettings_WithInvalidTimeRange_ShowsError() async throws {
        mockUserRepository.userToReturn = User(appleUserId: "test")
        viewModel.selectedApps = [Data("test".utf8)]
        viewModel.activeDays = [0, 1, 2]
        viewModel.startTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
        viewModel.endTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

        await viewModel.saveSettings()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("End time must be later") ?? false)
        XCTAssertFalse(viewModel.hasSetupCompleted)
    }

    func testSaveSettings_WithEmptyApps_ShowsError() async throws {
        mockUserRepository.userToReturn = User(appleUserId: "test")
        viewModel.activeDays = [0, 1, 2]

        await viewModel.saveSettings()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("at least one app") ?? false)
    }
}

// MARK: - Mocks

class MockTimeLimitServiceForViewModel: TimeLimitService {
    var didCallCreate = false
    var limitsToReturn: [TimeLimitSettings] = []

    func createTimeLimit(userId: UUID, name: String, appTokens: [Data], startTime: String, endTime: String, activeDays: [Int], isAllDay: Bool, prayerTimes: [String]) async throws {
        didCallCreate = true
    }

    func getTimeLimits(userId: UUID) async throws -> [TimeLimitSettings] {
        limitsToReturn
    }

    func updateTimeLimit(_ limit: TimeLimitSettings) async throws {}
    func deleteTimeLimit(_ limit: TimeLimitSettings) async throws {}
    func validateTimeRange(start: String, end: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let s = formatter.date(from: start), let e = formatter.date(from: end) else { return false }
        return e > s
    }
}

class MockUserRepositoryForTimeLimitViewModel: UserRepository {
    var userToReturn: User?

    func createUser(_ user: User) async throws {}
    func getUser(byAppleUserId appleUserId: String) async throws -> User? { userToReturn }
    func getCurrentUser() async throws -> User? { userToReturn }
    func updateUser(_ user: User) async throws {}
    func deleteCurrentUser() async throws {}
}

