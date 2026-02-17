import XCTest
import DeviceActivity
@testable import SurahFocus

@MainActor
final class AppLimitServiceTests: XCTestCase {
    var mockAppLimitRepository: MockAppLimitRepositoryForService!
    var mockScreenTimeRepository: MockScreenTimeRepositoryForAppLimit!
    var service: AppLimitServiceImpl!

    override func setUp() {
        super.setUp()
        mockAppLimitRepository = MockAppLimitRepositoryForService()
        mockScreenTimeRepository = MockScreenTimeRepositoryForAppLimit()
        service = AppLimitServiceImpl(
            repository: mockAppLimitRepository,
            screenTimeRepository: mockScreenTimeRepository
        )
    }

    override func tearDown() {
        mockAppLimitRepository = nil
        mockScreenTimeRepository = nil
        service = nil
        super.tearDown()
    }

    func testCreateAppLimit_SavesToRepository() async throws {
        let userId = UUID()
        let appTokens = [Data("test".utf8)]
        let activeDays = [0, 1, 2]

        try await service.createAppLimit(
            userId: userId,
            name: "Test Limit",
            appTokens: appTokens,
            dailyLimitMinutes: 60,
            activeDays: activeDays,
            isAllDay: false
        )

        XCTAssertTrue(mockAppLimitRepository.didCallCreate)
        XCTAssertNotNil(mockAppLimitRepository.lastCreatedLimit)
        XCTAssertEqual(mockAppLimitRepository.lastCreatedLimit?.name, "Test Limit")
        XCTAssertEqual(mockAppLimitRepository.lastCreatedLimit?.dailyLimitMinutes, 60)
    }

    func testCreateAppLimit_StartsActivityMonitoring() async throws {
        let userId = UUID()
        let appTokens = [Data("test".utf8)]
        let activeDays = [0, 1, 2]

        try await service.createAppLimit(
            userId: userId,
            name: "Test Limit",
            appTokens: appTokens,
            dailyLimitMinutes: 60,
            activeDays: activeDays,
            isAllDay: false
        )

        XCTAssertTrue(mockScreenTimeRepository.didCallStartMonitoring)
        XCTAssertNotNil(mockScreenTimeRepository.lastActivityName)
    }

    func testGetAppLimits_ReturnsLimitsFromRepository() async throws {
        let userId = UUID()
        let expectedLimits = [
            AppLimit(
                userId: userId,
                name: "Limit 1",
                appTokens: [],
                dailyLimitMinutes: 30,
                activeDays: [],
                isAllDay: false
            )
        ]
        mockAppLimitRepository.limitsToReturn = expectedLimits

        let result = try await service.getAppLimits(userId: userId)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Limit 1")
    }

    func testUpdateAppLimit_UpdatesRepository() async throws {
        let limit = AppLimit(
            userId: UUID(),
            name: "Updated Limit",
            appTokens: [],
            dailyLimitMinutes: 90,
            activeDays: [0, 1],
            isAllDay: false
        )

        try await service.updateAppLimit(limit)

        XCTAssertTrue(mockAppLimitRepository.didCallUpdate)
    }

    func testUpdateAppLimit_StopsOldMonitoring() async throws {
        let limit = AppLimit(
            userId: UUID(),
            name: "Updated Limit",
            appTokens: [],
            dailyLimitMinutes: 90,
            activeDays: [0, 1],
            isAllDay: false
        )

        try await service.updateAppLimit(limit)

        XCTAssertTrue(mockScreenTimeRepository.didCallStopMonitoring)
        XCTAssertEqual(mockScreenTimeRepository.stoppedActivities.count, 1)
    }

    func testUpdateAppLimit_RestartsMonitoring() async throws {
        let limit = AppLimit(
            userId: UUID(),
            name: "Updated Limit",
            appTokens: [],
            dailyLimitMinutes: 90,
            activeDays: [0, 1],
            isAllDay: false
        )

        try await service.updateAppLimit(limit)

        XCTAssertTrue(mockScreenTimeRepository.didCallStartMonitoring)
    }

    func testDeleteAppLimit_DeletesFromRepository() async throws {
        let limit = AppLimit(
            userId: UUID(),
            name: "To Delete",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [],
            isAllDay: false
        )

        try await service.deleteAppLimit(limit)

        XCTAssertTrue(mockAppLimitRepository.didCallDelete)
    }

    func testDeleteAppLimit_StopsMonitoring() async throws {
        let limit = AppLimit(
            userId: UUID(),
            name: "To Delete",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [],
            isAllDay: false
        )

        try await service.deleteAppLimit(limit)

        XCTAssertTrue(mockScreenTimeRepository.didCallStopMonitoring)
        XCTAssertGreaterThan(mockScreenTimeRepository.stoppedActivities.count, 0)
    }

    func testCreateAppLimit_WithDefaultName() async throws {
        let userId = UUID()
        let appTokens = [Data("test".utf8)]
        let activeDays = [0, 1, 2]

        try await service.createAppLimit(
            userId: userId,
            name: "",
            appTokens: appTokens,
            dailyLimitMinutes: 60,
            activeDays: activeDays,
            isAllDay: false
        )

        // Empty name should be saved as-is (ViewModel handles default naming)
        XCTAssertEqual(mockAppLimitRepository.lastCreatedLimit?.name, "")
    }
}

// MARK: - Mocks

class MockAppLimitRepositoryForService: AppLimitRepository {
    var didCallCreate = false
    var didCallUpdate = false
    var didCallDelete = false
    var lastCreatedLimit: AppLimit?
    var limitsToReturn: [AppLimit] = []

    func create(_ limit: AppLimit) async throws {
        didCallCreate = true
        lastCreatedLimit = limit
    }

    func getAll(for userId: UUID) async throws -> [AppLimit] {
        return limitsToReturn
    }

    func get(id: UUID) async throws -> AppLimit? {
        return limitsToReturn.first
    }

    func update(_ limit: AppLimit) async throws {
        didCallUpdate = true
    }

    func delete(_ limit: AppLimit) async throws {
        didCallDelete = true
    }
}

class MockScreenTimeRepositoryForAppLimit: ScreenTimeRepository {
    var didCallStartMonitoring = false
    var didCallStopMonitoring = false
    var lastActivityName: DeviceActivityName?
    var stoppedActivities: Set<DeviceActivityName> = []

    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws {}
    func loadAppSelection() async throws -> FamilyActivitySelection { FamilyActivitySelection() }
    func clearAppSelection() async throws {}
    func saveActiveSession(_ session: Session) async throws {}
    func loadActiveSession() async throws -> Session? { nil }
    func clearActiveSession() async throws {}
    func getBlockedApps(for userId: UUID) async throws -> [BlockedApp] { [] }
    func deleteBlockedApp(_ app: BlockedApp) async throws {}

    func startActivityMonitoring(
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws {
        didCallStartMonitoring = true
        lastActivityName = name
    }

    func stopActivityMonitoring(_ names: Set<DeviceActivityName>) async throws {
        didCallStopMonitoring = true
        stoppedActivities = names
    }
}
