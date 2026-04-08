import XCTest

@testable import DeenFirst

final class DashboardDateKeysTests: XCTestCase {
    // 2026-04-08 12:00:00 UTC — Wednesday of ISO week 15, 2026
    private let fixedDate = Date(timeIntervalSince1970: 1_775_995_200)

    func test_dayKey_format() {
        let key = DashboardDateKeys.dayKey(for: fixedDate)
        XCTAssertEqual(key.count, 10)
        XCTAssertTrue(key.contains("-"))
        // Full ISO format like "2026-04-08" — 4 digit year, 2 digit month, 2 digit day
        let parts = key.split(separator: "-")
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0].count, 4)
        XCTAssertEqual(parts[1].count, 2)
        XCTAssertEqual(parts[2].count, 2)
    }

    func test_weekKey_format() {
        let key = DashboardDateKeys.weekKey(for: fixedDate)
        // Format "YYYY-Www" e.g. "2026-W15"
        XCTAssertEqual(key.count, 8)
        XCTAssertTrue(key.contains("-W"))
        let parts = key.split(separator: "-")
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[0].count, 4)
        XCTAssertTrue(parts[1].hasPrefix("W"))
        XCTAssertEqual(parts[1].count, 3) // "W" + 2 digits
    }

    func test_dayKey_matches_DashboardDataWriter_format() {
        // Guard against drift — the writer's format must equal the shared helper.
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        XCTAssertEqual(DashboardDateKeys.dayKey(for: fixedDate), f.string(from: fixedDate))
    }

    func test_weekKey_matches_DashboardDataWriter_format() {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "YYYY-'W'ww"
        XCTAssertEqual(DashboardDateKeys.weekKey(for: fixedDate), f.string(from: fixedDate))
    }
}
