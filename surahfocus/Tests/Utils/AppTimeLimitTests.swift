import XCTest
@testable import SurahFocus

final class AppTimeLimitTests: XCTestCase {
    // MARK: - Display Name Tests

    func testDisplayName_FifteenMinutes() {
        XCTAssertEqual(TimeLimit.fifteen.displayName, "15 min")
    }

    func testDisplayName_ThirtyMinutes() {
        XCTAssertEqual(TimeLimit.thirty.displayName, "30 min")
    }

    func testDisplayName_FortyFiveMinutes() {
        XCTAssertEqual(TimeLimit.fortyFive.displayName, "45 min")
    }

    func testDisplayName_SixtyMinutes() {
        XCTAssertEqual(TimeLimit.sixty.displayName, "1 hour")
    }

    func testDisplayName_NinetyMinutes() {
        XCTAssertEqual(TimeLimit.ninety.displayName, "1.5 hours")
    }

    func testDisplayName_OneHundredTwentyMinutes() {
        XCTAssertEqual(TimeLimit.oneHundredTwenty.displayName, "2 hours")
    }

    // MARK: - Minutes Value Tests

    func testMinutes_Fifteen() {
        XCTAssertEqual(TimeLimit.fifteen.minutes, 15)
    }

    func testMinutes_Thirty() {
        XCTAssertEqual(TimeLimit.thirty.minutes, 30)
    }

    func testMinutes_FortyFive() {
        XCTAssertEqual(TimeLimit.fortyFive.minutes, 45)
    }

    func testMinutes_Sixty() {
        XCTAssertEqual(TimeLimit.sixty.minutes, 60)
    }

    func testMinutes_Ninety() {
        XCTAssertEqual(TimeLimit.ninety.minutes, 90)
    }

    func testMinutes_OneHundredTwenty() {
        XCTAssertEqual(TimeLimit.oneHundredTwenty.minutes, 120)
    }

    // MARK: - Case Iterable Tests

    func testCaseIterable_ProducesAllCases() {
        let allCases = Array(TimeLimit.allCases)

        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.fifteen))
        XCTAssertTrue(allCases.contains(.thirty))
        XCTAssertTrue(allCases.contains(.fortyFive))
        XCTAssertTrue(allCases.contains(.sixty))
        XCTAssertTrue(allCases.contains(.ninety))
        XCTAssertTrue(allCases.contains(.oneHundredTwenty))
    }
}
