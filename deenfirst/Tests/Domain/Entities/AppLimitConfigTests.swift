import XCTest

@testable import DeenFirst

final class AppLimitConfigTests: XCTestCase {

    // MARK: - TimeLimit Enum Tests

    func testTimeLimitSeconds() {
        XCTAssertEqual(TimeLimit.fifteenMin.seconds, 900)
        XCTAssertEqual(TimeLimit.thirtyMin.seconds, 1800)
        XCTAssertEqual(TimeLimit.fortyFiveMin.seconds, 2700)
        XCTAssertEqual(TimeLimit.oneHour.seconds, 3600)
        XCTAssertEqual(TimeLimit.twoHours.seconds, 7200)
        XCTAssertEqual(TimeLimit.threeHours.seconds, 10800)
        XCTAssertEqual(TimeLimit.fourHours.seconds, 14400)
        XCTAssertEqual(TimeLimit.custom(90).seconds, 90)
    }

    func testTimeLimitMinutes() {
        XCTAssertEqual(TimeLimit.fifteenMin.minutes, 15)
        XCTAssertEqual(TimeLimit.thirtyMin.minutes, 30)
        XCTAssertEqual(TimeLimit.oneHour.minutes, 60)
        XCTAssertEqual(TimeLimit.custom(150).minutes, 2)
    }

    func testTimeLimitDisplayName() {
        XCTAssertEqual(TimeLimit.fifteenMin.displayName, "15 min")
        XCTAssertEqual(TimeLimit.thirtyMin.displayName, "30 min")
        XCTAssertEqual(TimeLimit.fortyFiveMin.displayName, "45 min")
        XCTAssertEqual(TimeLimit.oneHour.displayName, "1 hour")
        XCTAssertEqual(TimeLimit.twoHours.displayName, "2 hours")
        XCTAssertEqual(TimeLimit.threeHours.displayName, "3 hours")
        XCTAssertEqual(TimeLimit.fourHours.displayName, "4 hours")
        XCTAssertEqual(TimeLimit.custom(90).displayName, "1h 30m")
        XCTAssertEqual(TimeLimit.custom(150).displayName, "2h 30m")
        XCTAssertEqual(TimeLimit.custom(45).displayName, "45 min")
    }

    func testTimeLimitFromMinutes() {
        XCTAssertEqual(TimeLimit.fromMinutes(15), .fifteenMin)
        XCTAssertEqual(TimeLimit.fromMinutes(30), .thirtyMin)
        XCTAssertEqual(TimeLimit.fromMinutes(45), .fortyFiveMin)
        XCTAssertEqual(TimeLimit.fromMinutes(60), .oneHour)
        XCTAssertEqual(TimeLimit.fromMinutes(90), .custom(90))
        XCTAssertEqual(TimeLimit.fromMinutes(120), .twoHours)
        XCTAssertEqual(TimeLimit.fromMinutes(180), .threeHours)
        XCTAssertEqual(TimeLimit.fromMinutes(240), .fourHours)
    }

    func testTimeLimitAllCases() {
        let allCases = TimeLimit.allCases
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.fifteenMin))
        XCTAssertTrue(allCases.contains(.thirtyMin))
    }

    // MARK: - AppLimitConfig Tests

    func testAppLimitConfigInitialization() {
        let id = UUID()
        let config = AppLimitConfig(
            id: id,
            name: "Social Media Limit",
            timeLimit: .oneHour,
            daysActive: ["Monday", "Tuesday", "Wednesday"],
            unblockAllowedAfterLimit: 15,
            durationOptions: [5, 10, 15]
        )

        XCTAssertEqual(config.id, id)
        XCTAssertEqual(config.name, "Social Media Limit")
        XCTAssertEqual(config.timeLimit, .oneHour)
        XCTAssertEqual(config.daysActive.count, 3)
        XCTAssertEqual(config.unblockAllowedAfterLimit, 15)
        XCTAssertEqual(config.durationOptions, [5, 10, 15])
    }

    func testAppLimitConfigDefaults() {
        let config = AppLimitConfig(
            name: "Test",
            timeLimit: .thirtyMin
        )

        XCTAssertNil(config.id)
        XCTAssertEqual(config.name, "Test")
        XCTAssertEqual(config.timeLimit, .thirtyMin)
        XCTAssertEqual(config.daysActive, Set(DayHelper.allDayNames))
        XCTAssertEqual(config.unblockAllowedAfterLimit, 0)
        XCTAssertEqual(config.durationOptions, [15, 30, 60])
    }

    func testAppLimitConfigLimitSeconds() {
        let config = AppLimitConfig(
            name: "Test",
            timeLimit: .twoHours
        )

        XCTAssertEqual(config.limitSeconds, 7200)
    }

    func testAppLimitConfigEmptyDaysMeansAllDays() {
        let config = AppLimitConfig(
            name: "Test",
            timeLimit: .oneHour,
            daysActive: []
        )

        XCTAssertEqual(config.daysActive, Set(DayHelper.allDayNames))
    }
}
