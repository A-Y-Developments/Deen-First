import XCTest

@testable import SurahFocus

final class timeLimitHelperTests: XCTestCase {
    // MARK: - Time Period Tests

    func testIsMorning_ReturnsTrueForMorningHours() {
        // Test based on current time
        let hour = Calendar.current.component(.hour, from: Date())
        let isMorning = (6...11).contains(hour)
        XCTAssertEqual(TimeLimitHelper.isMorning(), isMorning)
    }

    func testIsAfternoon_ReturnsTrueForAfternoonHours() {
        let hour = Calendar.current.component(.hour, from: Date())
        let isAfternoon = (12...16).contains(hour)
        XCTAssertEqual(TimeLimitHelper.isAfternoon(), isAfternoon)
    }

    func testIsEvening_ReturnsTrueForEveningHours() {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = (17...20).contains(hour)
        XCTAssertEqual(TimeLimitHelper.isEvening(), isEvening)
    }

    func testIsNight_ReturnsTrueForNightHours() {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = hour >= 21 || hour < 6
        XCTAssertEqual(TimeLimitHelper.isNight(), isNight)
    }

    // MARK: - Date Calculation Tests

    func testSecondsUntilMidnight_ReturnsPositiveValue() {
        let seconds = TimeLimitHelper.secondsUntilMidnight()

        XCTAssertGreaterThan(seconds, 0)
        XCTAssertLessThan(seconds, 86400)  // Less than 24 hours
    }

    func testStartOfToday_ReturnsMidnight() {
        let startOfDay = TimeLimitHelper.startOfToday()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfToday_ReturnsNextDayMidnight() {
        guard let endOfToday = TimeLimitHelper.endOfToday() else {
            XCTFail("endOfToday should not be nil")
            return
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: endOfToday)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfToday_Is24HoursAfterStart() {
        let startOfDay = TimeLimitHelper.startOfToday()
        guard let endOfToday = TimeLimitHelper.endOfToday() else {
            XCTFail("endOfToday should not be nil")
            return
        }

        // Note: Date's timeIntervalSince returns TimeInterval
        let difference = endOfToday.timeIntervalSince(startOfDay)

        XCTAssertEqual(difference, 86400, accuracy: 1)  // 24 hours in seconds
    }
}
