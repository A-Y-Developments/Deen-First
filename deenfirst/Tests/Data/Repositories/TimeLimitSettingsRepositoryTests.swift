import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class TimeLimitRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var repository: TimeLimitRepository!

    override func setUp() async throws {
        let schema = Schema([TimeLimitSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        repository = TimeLimitRepositoryImpl(localDataSource: localDataSource)
    }

    override func tearDown() async throws {
        container = nil
        localDataSource = nil
        repository = nil
    }

    func testCreateTimeLimitSettings() async throws {
        let userId = UUID()
        let limit = TimeLimitSettings(
            userId: userId,
            name: "Test Limit",
            appTokens: [Data("test".utf8)],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [0, 1, 2],
            isAllDay: false,
            prayerTimes: ["subuh"]
        )

        try await repository.create(limit)

        let fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 1)
        XCTAssertEqual(fetchedLimits.first?.name, "Test Limit")
    }

    func testGetAllTimeLimitsForUser() async throws {
        let userId = UUID()
        let limit1 = TimeLimitSettings(
            userId: userId,
            name: "Limit 1",
            appTokens: [],
            startTime: "08:00",
            endTime: "12:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )
        let limit2 = TimeLimitSettings(
            userId: userId,
            name: "Limit 2",
            appTokens: [],
            startTime: "13:00",
            endTime: "20:00",
            activeDays: [],
            isAllDay: true,
            prayerTimes: []
        )

        try await repository.create(limit1)
        try await repository.create(limit2)

        let fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 2)
    }

    func testGetTimeLimitById() async throws {
        let userId = UUID()
        let limit = TimeLimitSettings(
            userId: userId,
            name: "Find Me",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )

        try await repository.create(limit)

        let fetchedLimit = try await repository.get(id: limit.id)
        XCTAssertNotNil(fetchedLimit)
        XCTAssertEqual(fetchedLimit?.name, "Find Me")
    }

    func testUpdateTimeLimitSettings() async throws {
        let userId = UUID()
        let limit = TimeLimitSettings(
            userId: userId,
            name: "Original Name",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [0],
            isAllDay: false,
            prayerTimes: []
        )

        try await repository.create(limit)

        guard let fetchedLimit = try await repository.get(id: limit.id) else {
            XCTFail("Limit not found")
            return
        }

        fetchedLimit.name = "Updated Name"
        fetchedLimit.startTime = "08:00"
        fetchedLimit.endTime = "18:00"
        fetchedLimit.activeDays = [0, 1, 2, 3, 4, 5, 6]

        try await repository.update(fetchedLimit)

        let updatedLimit = try await repository.get(id: limit.id)
        XCTAssertEqual(updatedLimit?.name, "Updated Name")
        XCTAssertEqual(updatedLimit?.startTime, "08:00")
        XCTAssertEqual(updatedLimit?.endTime, "18:00")
        XCTAssertEqual(updatedLimit?.activeDays.count, 7)
    }

    func testDeleteTimeLimitSettings() async throws {
        let userId = UUID()
        let limit = TimeLimitSettings(
            userId: userId,
            name: "To Delete",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )

        try await repository.create(limit)

        var fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 1)

        try await repository.delete(limit)

        fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 0)
    }

    func testGetAllTimeLimitsOnlyReturnsActive() async throws {
        let userId = UUID()
        let activeLimit = TimeLimitSettings(
            userId: userId,
            name: "Active",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )

        try await repository.create(activeLimit)

        guard let fetchedLimit = try await repository.get(id: activeLimit.id) else {
            XCTFail("Limit not found")
            return
        }

        fetchedLimit.isActive = false
        try await repository.update(fetchedLimit)

        let fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 0)
    }
}
