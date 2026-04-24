import XCTest

@testable import DeenFirst

final class UnblockCountdownCalculatorTests: XCTestCase {

    // MARK: - remaining(expiresAt:now:)

    func testRemaining_futureExpiry_returnsPositiveInterval() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiresAt = now.addingTimeInterval(300)

        let remaining = UnblockCountdownCalculator.remaining(expiresAt: expiresAt, now: now)

        XCTAssertEqual(remaining, 300, accuracy: 0.001)
    }

    func testRemaining_pastExpiry_returnsZero() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiresAt = now.addingTimeInterval(-60)

        let remaining = UnblockCountdownCalculator.remaining(expiresAt: expiresAt, now: now)

        XCTAssertEqual(remaining, 0, accuracy: 0.001)
    }

    func testRemaining_expiryEqualsNow_returnsZero() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        let remaining = UnblockCountdownCalculator.remaining(expiresAt: now, now: now)

        XCTAssertEqual(remaining, 0, accuracy: 0.001)
    }

    // MARK: - formatted(remaining:)

    func testFormatted_thirtySeconds_returnsZeroColonThirty() {
        XCTAssertEqual(UnblockCountdownCalculator.formatted(remaining: 30), "0:30")
    }

    func testFormatted_fiveMinutes_returnsFiveColonZeroZero() {
        XCTAssertEqual(UnblockCountdownCalculator.formatted(remaining: 300), "5:00")
    }

    func testFormatted_oneHour_returnsSixtyColonZeroZero() {
        XCTAssertEqual(UnblockCountdownCalculator.formatted(remaining: 3600), "60:00")
    }

    func testFormatted_mixedMinutesAndSeconds() {
        XCTAssertEqual(UnblockCountdownCalculator.formatted(remaining: 125), "2:05")
    }

    func testFormatted_zero_returnsNil() {
        XCTAssertNil(UnblockCountdownCalculator.formatted(remaining: 0))
    }

    func testFormatted_negative_returnsNil() {
        XCTAssertNil(UnblockCountdownCalculator.formatted(remaining: -10))
    }
}
