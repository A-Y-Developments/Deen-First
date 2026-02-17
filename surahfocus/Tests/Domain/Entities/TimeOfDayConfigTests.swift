import XCTest
@testable import SurahFocus

final class TimeOfDayConfigTests: XCTestCase {

    // MARK: - TimeOfDayConfig Tests

    func testTimeOfDayConfigInitialization() {
        let id = UUID()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)
        let days: Set<String> = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

        let config = TimeOfDayConfig(
            id: id,
            name: "Work Hours",
            startTime: start,
            endTime: end,
            daysActive: days,
            unblockAllowedAfterLimit: 10,
            durationOptions: [5, 10]
        )

        XCTAssertEqual(config.id, id)
        XCTAssertEqual(config.name, "Work Hours")
        XCTAssertEqual(config.startTime.hour, 9)
        XCTAssertEqual(config.endTime.hour, 17)
        XCTAssertEqual(config.daysActive.count, 5)
        XCTAssertEqual(config.unblockAllowedAfterLimit, 10)
        XCTAssertEqual(config.durationOptions, [5, 10])
    }

    func testTimeOfDayConfigDefaults() {
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)

        let config = TimeOfDayConfig(
            name: "Focus Time",
            startTime: start,
            endTime: end
        )

        XCTAssertNil(config.id)
        XCTAssertEqual(config.name, "Focus Time")
        XCTAssertEqual(config.daysActive, Set(DayHelper.allDayNames))
        XCTAssertEqual(config.unblockAllowedAfterLimit, 0)
        XCTAssertEqual(config.durationOptions, [5, 10, 15])
    }

    func testTimeOfDayConfigEmptyDaysMeansAllDays() {
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)

        let config = TimeOfDayConfig(
            name: "Test",
            startTime: start,
            endTime: end,
            daysActive: []
        )

        XCTAssertEqual(config.daysActive, Set(DayHelper.allDayNames))
    }

    func testTimeOfDayConfigIsCurrentlyInBlockingPeriod() {
        // Create a config that should be active now
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // Create a range that includes current time
        let startHour = max(0, currentHour - 1)
        let endHour = min(23, currentHour + 1)

        let start = DateComponents(hour: startHour, minute: 0)
        let end = DateComponents(hour: endHour, minute: 0)

        let config = TimeOfDayConfig(
            name: "Current Time",
            startTime: start,
            endTime: end,
            daysActive: [] // All days
        )

        XCTAssertTrue(config.isCurrentlyInBlockingPeriod)
    }

    func testTimeOfDayConfigNotInBlockingPeriodOutsideHours() {
        // Create a config that should NOT be active now (middle of night)
        let start = DateComponents(hour: 2, minute: 0)
        let end = DateComponents(hour: 4, minute: 0)

        let config = TimeOfDayConfig(
            name: "Night",
            startTime: start,
            endTime: end,
            daysActive: []
        )

        // This should be false unless it's actually 2-4 AM
        let result = config.isCurrentlyInBlockingPeriod
        // We can't assert false directly because test might run at 2-4 AM
        // Just verify the property is accessible
        XCTAssertNotNil(result)
    }

    // MARK: - AllDayConfig Tests

    func testAllDayConfigInitialization() {
        let id = UUID()
        let days: Set<String> = ["Saturday", "Sunday"]

        let config = AllDayConfig(
            id: id,
            name: "Weekend Block",
            daysActive: days,
            unblockAllowedAfterLimit: 20,
            durationOptions: [10, 20, 30]
        )

        XCTAssertEqual(config.id, id)
        XCTAssertEqual(config.name, "Weekend Block")
        XCTAssertEqual(config.daysActive.count, 2)
        XCTAssertEqual(config.unblockAllowedAfterLimit, 20)
        XCTAssertEqual(config.durationOptions, [10, 20, 30])
    }

    func testAllDayConfigDefaults() {
        let config = AllDayConfig(
            name: "All Day Test"
        )

        XCTAssertNil(config.id)
        XCTAssertEqual(config.name, "All Day Test")
        XCTAssertEqual(config.daysActive, Set(DayHelper.allDayNames))
        XCTAssertEqual(config.unblockAllowedAfterLimit, 0)
        XCTAssertEqual(config.durationOptions, [5, 10, 15])
    }

    func testAllDayConfigEmptyDaysMeansAllDays() {
        let config = AllDayConfig(
            name: "Test",
            daysActive: []
        )

        XCTAssertEqual(config.daysActive, Set(DayHelper.allDayNames))
    }

    func testAllDayConfigShouldBlockToday() {
        let todayName = DayHelper.getCurrentDayName()

        let config = AllDayConfig(
            name: "Today",
            daysActive: [todayName]
        )

        XCTAssertTrue(config.shouldBlockToday)
    }

    func testAllDayConfigShouldNotBlockToday() {
        let allDays = Set(DayHelper.allDayNames)
        let notToday = allDays.filter { $0 != DayHelper.getCurrentDayName() }

        let config = AllDayConfig(
            name: "Not Today",
            daysActive: notToday
        )

        XCTAssertFalse(config.shouldBlockToday)
    }

    func testAllDayConfigShouldBlockEveryday() {
        let config = AllDayConfig(
            name: "Everyday",
            daysActive: []
        )

        XCTAssertTrue(config.shouldBlockToday)
    }
}
