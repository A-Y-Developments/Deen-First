import DeviceActivity
import XCTest

@testable import DeenFirst

final class DeviceActivityScheduleHelperTests: XCTestCase {

    func testCreateDailySchedule_CreatesScheduleWithCorrectInterval() {
        let schedule = DeviceActivityScheduleHelper.createDailySchedule()

        // Verify the schedule starts at midnight
        XCTAssertEqual(schedule.intervalStart.hour, 0)
        XCTAssertEqual(schedule.intervalStart.minute, 0)

        // Verify the schedule ends at 23:59
        XCTAssertEqual(schedule.intervalEnd.hour, 23)
        XCTAssertEqual(schedule.intervalEnd.minute, 59)

        // Verify it repeats
        XCTAssertTrue(schedule.repeats)
    }

    func testCreateFullDaySchedule_CreatesScheduleWithCorrectInterval() {
        let schedule = DeviceActivityScheduleHelper.createFullDaySchedule()

        // Verify the schedule starts at midnight
        XCTAssertEqual(schedule.intervalStart.hour, 0)
        XCTAssertEqual(schedule.intervalStart.minute, 0)

        // Verify the schedule ends at 23:59
        XCTAssertEqual(schedule.intervalEnd.hour, 23)
        XCTAssertEqual(schedule.intervalEnd.minute, 59)

        // Verify it repeats by default
        XCTAssertTrue(schedule.repeats)
    }

    func testCreateFullDaySchedule_WithNoRepeat() {
        let schedule = DeviceActivityScheduleHelper.createFullDaySchedule(repeats: false)

        XCTAssertFalse(schedule.repeats)
    }

    func testCreateCustomSchedule_CreatesScheduleWithCustomInterval() {
        let startTime = DateComponents(hour: 9, minute: 0)
        let endTime = DateComponents(hour: 17, minute: 30)

        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: startTime,
            endTime: endTime
        )

        // Verify custom start time
        XCTAssertEqual(schedule.intervalStart.hour, 9)
        XCTAssertEqual(schedule.intervalStart.minute, 0)

        // Verify custom end time
        XCTAssertEqual(schedule.intervalEnd.hour, 17)
        XCTAssertEqual(schedule.intervalEnd.minute, 30)

        // Verify it repeats by default
        XCTAssertTrue(schedule.repeats)
    }

    func testCreateCustomSchedule_WithNoRepeat() {
        let startTime = DateComponents(hour: 10, minute: 0)
        let endTime = DateComponents(hour: 12, minute: 0)

        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: startTime,
            endTime: endTime,
            repeats: false
        )

        XCTAssertFalse(schedule.repeats)
    }
}
