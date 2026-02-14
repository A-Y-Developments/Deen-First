import XCTest
@testable import SurahFocus

final class DateExtensionTests: XCTestCase {
    // MARK: - Is Same Day Tests

    func testIsSameDay_SameDateReturnsTrue() {
        let date1 = Date()
        let date2 = date1

        XCTAssertTrue(date1.isSameDay(as: date2))
    }

    func testIsSameDay_SameDayDifferentTimesReturnsTrue() {
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 10, minute: 0, second: 0))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 22, minute: 30, second: 45))!

        XCTAssertTrue(date1.isSameDay(as: date2))
    }

    func testIsSameDay_DifferentDaysReturnsFalse() {
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 12))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 16, hour: 12))!

        XCTAssertFalse(date1.isSameDay(as: date2))
    }

    func testIsSameDay_DifferentMonthsReturnsFalse() {
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!

        XCTAssertFalse(date1.isSameDay(as: date2))
    }

    func testIsSameDay_OneSecondApartReturnsFalse() {
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 23, minute: 59, second: 59))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 16, hour: 0, minute: 0, second: 0))!

        XCTAssertFalse(date1.isSameDay(as: date2))
    }

    // MARK: - Start Of Day Tests

    func testStartOfDay_ReturnsMidnight() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 14, minute: 30, second: 45))!
        let startOfDay = date.startOfDay

        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testStartOfDay_SameDaySameDate() {
        let date = Date()
        let startOfDay = date.startOfDay

        XCTAssertTrue(date.isSameDay(as: startOfDay))
    }

    func testStartOfDay_StartOfDayIsIdempotent() {
        let date = Date()
        let startOfDay1 = date.startOfDay
        let startOfDay2 = startOfDay1.startOfDay

        XCTAssertEqual(startOfDay1, startOfDay2)
    }
}
