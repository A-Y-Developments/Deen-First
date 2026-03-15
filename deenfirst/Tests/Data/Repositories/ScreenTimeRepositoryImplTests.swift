import DeviceActivity
import FamilyControls
import XCTest

@testable import DeenFirst

@MainActor
final class ScreenTimeRepositoryImplTests: XCTestCase {
    var repository: ScreenTimeRepositoryImpl!
    var localDataSource: LocalDataSource!
    var container: ModelContainer!

    override func setUp() async throws {
        let schema = Schema([
            User.self, Session.self, BlockedApp.self, AppLimit.self, TimeLimitSettings.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        repository = ScreenTimeRepositoryImpl(localDataSource: localDataSource)
    }

    override func tearDown() async throws {
        container = nil
        localDataSource = nil
        repository = nil
    }

    func testStartActivityMonitoring_WithEvents_CallsStartMonitoring() async throws {
        let name = DeviceActivityName("test_activity")
        let schedule = DeviceActivityScheduleHelper.createDailySchedule()
        let token = ActivityToken(
            id: UUID(), applicationToken: ApplicationToken(), categoryToken: nil)
        let events = ScreenTimeEvents.createEvents(for: .fifteen, selection: [token])

        try await repository.startActivityMonitoring(name: name, schedule: schedule, events: events)

    }

    func testStartActivityMonitoring_WithoutEvents_CallsStartMonitoring() async throws {
        let name = DeviceActivityName("test_activity")
        let schedule = DeviceActivityScheduleHelper.createDailySchedule()

        try await repository.startActivityMonitoring(name: name, schedule: schedule, events: [:])

        // If no error is thrown, the test passes
    }

    func testStopActivityMonitoring_CallsStopMonitoring() async throws {
        let name = DeviceActivityName("test_activity")
        let names: Set<DeviceActivityName> = [name]

        try await repository.stopActivityMonitoring(names)

        // If no error is thrown, the test passes
    }

    func testStopActivityMonitoring_WithMultipleNames_CallsStopMonitoring() async throws {
        let name1 = DeviceActivityName("test_activity_1")
        let name2 = DeviceActivityName("test_activity_2")
        let names: Set<DeviceActivityName> = [name1, name2]

        try await repository.stopActivityMonitoring(names)

        // If no error is thrown, the test passes
    }

    // MARK: - Existing functionality tests

    func testSaveAppSelection_DoesNotThrow() async throws {
        let selection = FamilyActivitySelection()
        let timeLimits: [String: TimeLimit] = [:]

        try await repository.saveAppSelection(selection, timeLimits: timeLimits)

        // Should complete without error
    }

    func testLoadAppSelection_ReturnsEmptySelection() async throws {
        let selection = try await repository.loadAppSelection()

        XCTAssertNotNil(selection)
    }

    func testClearAppSelection_DoesNotThrow() async throws {
        try await repository.clearAppSelection()

        // Should complete without error
    }

    func testGetBlockedApps_ReturnsEmptyArray_WhenNoApps() async throws {
        let userId = UUID()
        let apps = try await repository.getBlockedApps(for: userId)

        XCTAssertTrue(apps.isEmpty)
    }

    func testSaveActiveSession_SavesSession() async throws {
        let session = Session(
            userId: UUID(),
            surahId: 1,
            startTime: Date(),
            endTime: nil
        )

        try await repository.saveActiveSession(session)

        let loadedSession = try await repository.loadActiveSession()
        XCTAssertNotNil(loadedSession)
        XCTAssertEqual(loadedSession?.surahId, 1)
    }

    func testClearActiveSession_RemovesSession() async throws {
        let session = Session(
            userId: UUID(),
            surahId: 1,
            startTime: Date(),
            endTime: nil
        )

        try await repository.saveActiveSession(session)
        try await repository.clearActiveSession()

        let loadedSession = try await repository.loadActiveSession()
        XCTAssertNil(loadedSession)
    }
}
