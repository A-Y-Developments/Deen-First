import XCTest

@testable import DeenFirst

final class WeeklyTrendReportBuilderTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    // 2026-04-08 12:00:00 UTC — Wednesday of ISO week 15.
    private let fixedDate = Date(timeIntervalSince1970: 1_775_995_200)
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    override func setUp() {
        super.setUp()
        suiteName = "WeeklyTrendReportBuilderTests.\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test suite defaults")
            return
        }
        defaults = suite
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func dayKey(offset: Int) -> String {
        guard let date = calendar.date(byAdding: .day, value: offset, to: fixedDate) else {
            return ""
        }
        return DashboardDateKeys.dayKey(for: date)
    }

    func test_nil_defaults_returns_empty() {
        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: [:],
            defaults: nil,
            now: fixedDate,
            calendar: calendar
        )
        XCTAssertTrue(report.days.isEmpty)
    }

    func test_returns_seven_day_points_oldest_first() {
        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: [:],
            defaults: defaults,
            now: fixedDate,
            calendar: calendar
        )
        XCTAssertEqual(report.days.count, 7)
        // Oldest first → today last.
        XCTAssertEqual(report.days.last?.dayKey, dayKey(offset: 0))
        XCTAssertEqual(report.days.first?.dayKey, dayKey(offset: -6))
        XCTAssertEqual(report.days.last?.isToday, true)
        XCTAssertEqual(report.days.first?.isToday, false)
    }

    func test_missing_data_days_have_zero_score() {
        // Empty defaults + no screen time → every day is missing data → 0.
        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: [:],
            defaults: defaults,
            now: fixedDate,
            calendar: calendar
        )
        for point in report.days {
            XCTAssertFalse(point.hasData, "\(point.dayKey) should have no data")
            XCTAssertEqual(point.score, 0)
        }
    }

    func test_today_uses_app_group_counters_and_screen_time() {
        let todayKey = dayKey(offset: 0)
        defaults.set(35 * 60, forKey: AppGroupConstants.quranSecondsKey(todayKey)) // +20
        defaults.set(2, forKey: AppGroupConstants.focusSessionsKey(todayKey))      // +15
        defaults.set(3, forKey: AppGroupConstants.recitationsPassedKey(todayKey))  // +10
        defaults.set(10, forKey: AppGroupConstants.streakCurrentKey)                // +5+5

        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: [todayKey: 60 * 60], // 1h, under 2h limit → no penalty
            defaults: defaults,
            now: fixedDate,
            calendar: calendar
        )
        guard let today = report.days.last else {
            XCTFail("Expected today entry")
            return
        }
        XCTAssertTrue(today.isToday)
        XCTAssertTrue(today.hasData)
        // 50 + 20 + 15 + 10 + 5 + 5 = 105 → clamped to 100
        XCTAssertEqual(today.score, 100)
    }

    func test_screen_time_only_day_still_counts_as_data() {
        let yesterday = dayKey(offset: -1)
        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: [yesterday: 4 * 60 * 60], // 4h, well over limit
            defaults: defaults,
            now: fixedDate,
            calendar: calendar
        )
        let point = report.days.first { $0.dayKey == yesterday }
        XCTAssertNotNil(point)
        XCTAssertEqual(point?.hasData, true)
        // 50 + overLimit penalty (4h - 2h = 2h over → tier3 -30) = 20
        XCTAssertEqual(point?.score, 20)
    }

    func test_unknown_days_default_to_zero_screen_time() {
        // Provide screen time for an unrelated day; today should still have 0 ST.
        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: ["1999-01-01": 99_999],
            defaults: defaults,
            now: fixedDate,
            calendar: calendar
        )
        XCTAssertEqual(report.days.count, 7)
        for point in report.days {
            XCTAssertEqual(point.score, 0)
        }
    }

    func test_today_flagged_correctly() {
        let report = WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: [:],
            defaults: defaults,
            now: fixedDate,
            calendar: calendar
        )
        let todayPoints = report.days.filter { $0.isToday }
        XCTAssertEqual(todayPoints.count, 1)
        XCTAssertEqual(todayPoints.first?.dayKey, DashboardDateKeys.dayKey(for: fixedDate))
    }
}
