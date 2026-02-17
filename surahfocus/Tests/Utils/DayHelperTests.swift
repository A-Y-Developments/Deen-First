import XCTest
@testable import SurahFocus

final class DayHelperTests: XCTestCase {

    func testGetCurrentDayName_ReturnsValidDayName() {
        let dayName = DayHelper.getCurrentDayName()

        XCTAssertTrue(DayHelper.allDayNames.contains(dayName), "Day name should be one of the valid day names")
    }

    func testAllDayNames_ContainsAllDays() {
        XCTAssertEqual(DayHelper.allDayNames.count, 7, "Should have 7 days")
        XCTAssertEqual(DayHelper.allDayNames[0], "Sunday")
        XCTAssertEqual(DayHelper.allDayNames[1], "Monday")
        XCTAssertEqual(DayHelper.allDayNames[2], "Tuesday")
        XCTAssertEqual(DayHelper.allDayNames[3], "Wednesday")
        XCTAssertEqual(DayHelper.allDayNames[4], "Thursday")
        XCTAssertEqual(DayHelper.allDayNames[5], "Friday")
        XCTAssertEqual(DayHelper.allDayNames[6], "Saturday")
    }

    func testMapSelectedDaysToNames_WithValidIndices() {
        let selectedDays: Set<Int> = [0, 2, 4]
        let result = DayHelper.mapSelectedDaysToNames(selectedDays)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("Sunday"))
        XCTAssertTrue(result.contains("Tuesday"))
        XCTAssertTrue(result.contains("Thursday"))
    }

    func testMapSelectedDaysToNames_WithAllDays() {
        let selectedDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6]
        let result = DayHelper.mapSelectedDaysToNames(selectedDays)

        XCTAssertEqual(result.count, 7)
        XCTAssertEqual(result, Set(DayHelper.allDayNames))
    }

    func testMapSelectedDaysToNames_WithEmptySet() {
        let selectedDays: Set<Int> = []
        let result = DayHelper.mapSelectedDaysToNames(selectedDays)

        XCTAssertTrue(result.isEmpty)
    }

    func testMapSelectedDaysToNames_WithInvalidIndices() {
        let selectedDays: Set<Int> = [-1, 7, 10]
        let result = DayHelper.mapSelectedDaysToNames(selectedDays)

        XCTAssertTrue(result.isEmpty, "Invalid indices should be filtered out")
    }

    func testMapSelectedDaysToNames_WithMixedValidAndInvalid() {
        let selectedDays: Set<Int> = [0, 1, -1, 7, 3]
        let result = DayHelper.mapSelectedDaysToNames(selectedDays)

        XCTAssertEqual(result.count, 3, "Only valid indices should be mapped")
        XCTAssertTrue(result.contains("Sunday"))
        XCTAssertTrue(result.contains("Monday"))
        XCTAssertTrue(result.contains("Wednesday"))
    }

    func testGetCurrentDayIndex_ReturnsValidIndex() {
        let index = DayHelper.getCurrentDayIndex()

        XCTAssertTrue(index >= 0 && index < 7, "Day index should be between 0 and 6")
    }

    func testGetCurrentDayIndex_MatchesCurrentDayName() {
        let index = DayHelper.getCurrentDayIndex()
        let dayName = DayHelper.getCurrentDayName()

        XCTAssertEqual(DayHelper.allDayNames[index], dayName, "Index should match the current day name")
    }
}
