import XCTest
import SwiftData
@testable import SurahFocus

final class TimeLimitTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([TimeLimitSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    func testTimeLimitInitialization() {
        let userId = UUID()
        let appTokens = [Data("test".utf8)]
        let activeDays = [0, 1, 2]
        let prayerTimes = ["subuh", "maghrib"]

        let limit = TimeLimitSettings(
            userId: userId,
            name: "Test Limit",
            appTokens: appTokens,
            startTime: "09:00",
            endTime: "17:00",
            activeDays: activeDays,
            isAllDay: false,
            prayerTimes: prayerTimes
        )

        XCTAssertEqual(limit.userId, userId)
        XCTAssertEqual(limit.name, "Test Limit")
        XCTAssertEqual(limit.appTokens, appTokens)
        XCTAssertEqual(limit.startTime, "09:00")
        XCTAssertEqual(limit.endTime, "17:00")
        XCTAssertEqual(limit.activeDays, activeDays)
        XCTAssertFalse(limit.isAllDay)
        XCTAssertEqual(limit.prayerTimes, prayerTimes)
        XCTAssertTrue(limit.isActive)
        XCTAssertNotNil(limit.id)
        XCTAssertNotNil(limit.createdAt)
    }

    func testTimeLimitDefaultValues() {
        let limit = TimeLimitSettings(
            userId: UUID(),
            name: "Test",
            appTokens: [],
            startTime: "08:00",
            endTime: "20:00",
            activeDays: [],
            isAllDay: true,
            prayerTimes: []
        )

        XCTAssertTrue(limit.isActive)
        XCTAssertTrue(limit.isAllDay)
    }

    func testTimeLimitUniqueID() {
        let limit1 = TimeLimitSettings(
            userId: UUID(),
            name: "Limit 1",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )

        let limit2 = TimeLimitSettings(
            userId: UUID(),
            name: "Limit 2",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )

        XCTAssertNotEqual(limit1.id, limit2.id)
    }

    func testTimeLimitCreatedAtIsCurrentTime() {
        let before = Date()
        let limit = TimeLimitSettings(
            userId: UUID(),
            name: "Test",
            appTokens: [],
            startTime: "09:00",
            endTime: "17:00",
            activeDays: [],
            isAllDay: false,
            prayerTimes: []
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(limit.createdAt, before)
        XCTAssertLessThanOrEqual(limit.createdAt, after)
    }

    func testTimeLimitWithMultiplePrayerTimes() {
        let prayerTimes = ["subuh", "zuhr", "asr", "maghrib", "isya"]

        let limit = TimeLimitSettings(
            userId: UUID(),
            name: "All Prayers Limit",
            appTokens: [],
            startTime: "00:00",
            endTime: "23:59",
            activeDays: [0, 1, 2, 3, 4, 5, 6],
            isAllDay: true,
            prayerTimes: prayerTimes
        )

        XCTAssertEqual(limit.prayerTimes.count, 5)
        XCTAssertEqual(limit.activeDays.count, 7)
        XCTAssertTrue(limit.isAllDay)
    }
}
