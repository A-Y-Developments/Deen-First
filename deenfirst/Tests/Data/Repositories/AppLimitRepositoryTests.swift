import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class AppLimitRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var repository: AppLimitRepository!

    override func setUp() async throws {
        let schema = Schema([AppLimit.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        repository = AppLimitRepositoryImpl(localDataSource: localDataSource)
    }

    override func tearDown() async throws {
        container = nil
        localDataSource = nil
        repository = nil
    }

    func testCreateAppLimit() async throws {
        let userId = UUID()
        let limit = AppLimit(
            userId: userId,
            name: "Test Limit",
            appTokens: [Data("test".utf8)],
            dailyLimitMinutes: 60,
            activeDays: [0, 1, 2],
            isAllDay: false
        )

        try await repository.create(limit)

        let fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 1)
        XCTAssertEqual(fetchedLimits.first?.name, "Test Limit")
    }

    func testGetAllAppLimitsForUser() async throws {
        let userId = UUID()
        let limit1 = AppLimit(
            userId: userId,
            name: "Limit 1",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [],
            isAllDay: false
        )
        let limit2 = AppLimit(
            userId: userId,
            name: "Limit 2",
            appTokens: [],
            dailyLimitMinutes: 60,
            activeDays: [],
            isAllDay: true
        )

        try await repository.create(limit1)
        try await repository.create(limit2)

        let fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 2)
    }

    func testGetAppLimitById() async throws {
        let userId = UUID()
        let limit = AppLimit(
            userId: userId,
            name: "Find Me",
            appTokens: [],
            dailyLimitMinutes: 45,
            activeDays: [],
            isAllDay: false
        )

        try await repository.create(limit)

        let fetchedLimit = try await repository.get(id: limit.id)
        XCTAssertNotNil(fetchedLimit)
        XCTAssertEqual(fetchedLimit?.name, "Find Me")
    }

    func testGetAppLimitByIdReturnsNilWhenNotFound() async throws {
        let randomId = UUID()
        let fetchedLimit = try await repository.get(id: randomId)

        XCTAssertNil(fetchedLimit)
    }

    func testUpdateAppLimit() async throws {
        let userId = UUID()
        let limit = AppLimit(
            userId: userId,
            name: "Original Name",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [0],
            isAllDay: false
        )

        try await repository.create(limit)

        guard let fetchedLimit = try await repository.get(id: limit.id) else {
            XCTFail("Limit not found")
            return
        }

        fetchedLimit.name = "Updated Name"
        fetchedLimit.dailyLimitMinutes = 90
        fetchedLimit.activeDays = [0, 1, 2, 3, 4, 5, 6]

        try await repository.update(fetchedLimit)

        let updatedLimit = try await repository.get(id: limit.id)
        XCTAssertEqual(updatedLimit?.name, "Updated Name")
        XCTAssertEqual(updatedLimit?.dailyLimitMinutes, 90)
        XCTAssertEqual(updatedLimit?.activeDays.count, 7)
    }

    func testDeleteAppLimit() async throws {
        let userId = UUID()
        let limit = AppLimit(
            userId: userId,
            name: "To Delete",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [],
            isAllDay: false
        )

        try await repository.create(limit)

        var fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 1)

        try await repository.delete(limit)

        fetchedLimits = try await repository.getAll(for: userId)
        XCTAssertEqual(fetchedLimits.count, 0)
    }

    func testGetAllAppLimitsOnlyReturnsActive() async throws {
        let userId = UUID()
        let activeLimit = AppLimit(
            userId: userId,
            name: "Active",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [],
            isAllDay: false
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
