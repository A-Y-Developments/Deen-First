import XCTest
import SwiftData
@testable import SurahFocus

final class AppLimitTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([AppLimit.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    func testAppLimitInitialization() {
        let userId = UUID()
        let appTokens = [Data("test".utf8)]
        let activeDays = [0, 1, 2]

        let limit = AppLimit(
            userId: userId,
            name: "Test Limit",
            appTokens: appTokens,
            dailyLimitMinutes: 60,
            activeDays: activeDays,
            isAllDay: false
        )

        XCTAssertEqual(limit.userId, userId)
        XCTAssertEqual(limit.name, "Test Limit")
        XCTAssertEqual(limit.appTokens, appTokens)
        XCTAssertEqual(limit.dailyLimitMinutes, 60)
        XCTAssertEqual(limit.activeDays, activeDays)
        XCTAssertFalse(limit.isAllDay)
        XCTAssertTrue(limit.isActive)
        XCTAssertNotNil(limit.id)
        XCTAssertNotNil(limit.createdAt)
    }

    func testAppLimitDefaultValues() {
        let limit = AppLimit(
            userId: UUID(),
            name: "Test",
            appTokens: [],
            dailyLimitMinutes: 30,
            activeDays: [],
            isAllDay: true
        )

        XCTAssertTrue(limit.isActive)
        XCTAssertTrue(limit.isAllDay)
    }

    func testAppLimitUniqueID() {
        let limit1 = AppLimit(
            userId: UUID(),
            name: "Limit 1",
            appTokens: [],
            dailyLimitMinutes: 60,
            activeDays: [],
            isAllDay: false
        )

        let limit2 = AppLimit(
            userId: UUID(),
            name: "Limit 2",
            appTokens: [],
            dailyLimitMinutes: 60,
            activeDays: [],
            isAllDay: false
        )

        XCTAssertNotEqual(limit1.id, limit2.id)
    }

    func testAppLimitCreatedAtIsCurrentTime() {
        let before = Date()
        let limit = AppLimit(
            userId: UUID(),
            name: "Test",
            appTokens: [],
            dailyLimitMinutes: 60,
            activeDays: [],
            isAllDay: false
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(limit.createdAt, before)
        XCTAssertLessThanOrEqual(limit.createdAt, after)
    }

    func testAppLimitWithMultipleAppTokens() {
        let appTokens = [
            Data("app1".utf8),
            Data("app2".utf8),
            Data("app3".utf8)
        ]

        let limit = AppLimit(
            userId: UUID(),
            name: "Multi App Limit",
            appTokens: appTokens,
            dailyLimitMinutes: 120,
            activeDays: [0, 1, 2, 3, 4, 5, 6],
            isAllDay: true
        )

        XCTAssertEqual(limit.appTokens.count, 3)
        XCTAssertEqual(limit.activeDays.count, 7)
        XCTAssertTrue(limit.isAllDay)
    }
}
