import XCTest

@testable import DeenFirst

final class QuranEngagementReportBuilderTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    // 2026-04-08 12:00:00 UTC — Wednesday of ISO week 15
    private let fixedDate = Date(timeIntervalSince1970: 1_775_995_200)

    override func setUp() {
        super.setUp()
        suiteName = "QuranEngagementReportBuilderTests.\(UUID().uuidString)"
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

    private func dayKey() -> String { DashboardDateKeys.dayKey(for: fixedDate) }

    private func stamp() {
        defaults.set("2026-04-08T12:00:00Z", forKey: AppGroupConstants.dataLastUpdatedAtKey)
    }

    func test_nil_defaults_returns_empty() {
        let report = QuranEngagementReportBuilder.build(defaults: nil, now: fixedDate)
        XCTAssertNil(report.metrics)
    }

    func test_no_lastUpdatedAt_returns_empty() {
        // App Group reachable but nothing has been written yet
        let report = QuranEngagementReportBuilder.build(defaults: defaults, now: fixedDate)
        XCTAssertNil(report.metrics)
    }

    func test_stamped_with_zero_counters_returns_zeroed_metrics() {
        stamp()
        let report = QuranEngagementReportBuilder.build(defaults: defaults, now: fixedDate)
        let metrics = try? XCTUnwrap(report.metrics)
        XCTAssertEqual(metrics?.readingSeconds, 0)
        XCTAssertEqual(metrics?.focusListeningSeconds, 0)
        XCTAssertEqual(metrics?.focusSessionCount, 0)
        XCTAssertEqual(metrics?.recitationsPassed, 0)
        XCTAssertEqual(metrics?.recitationAttempts, 0)
        XCTAssertEqual(metrics?.streakDays, 0)
    }

    func test_reads_all_engagement_counters() {
        stamp()
        let day = dayKey()
        // quranSeconds includes both reading + focus listening
        defaults.set(20 * 60, forKey: AppGroupConstants.quranSecondsKey(day))
        defaults.set(8 * 60, forKey: AppGroupConstants.focusSecondsKey(day))
        defaults.set(2, forKey: AppGroupConstants.focusSessionsKey(day))
        defaults.set(3, forKey: AppGroupConstants.recitationsPassedKey(day))
        defaults.set(4, forKey: AppGroupConstants.recitationsAttemptsKey(day))
        defaults.set(5, forKey: AppGroupConstants.streakCurrentKey)

        let report = QuranEngagementReportBuilder.build(defaults: defaults, now: fixedDate)
        let metrics = try? XCTUnwrap(report.metrics)
        // reading = total - focus listening
        XCTAssertEqual(metrics?.readingSeconds, 12 * 60)
        XCTAssertEqual(metrics?.focusListeningSeconds, 8 * 60)
        XCTAssertEqual(metrics?.focusSessionCount, 2)
        XCTAssertEqual(metrics?.recitationsPassed, 3)
        XCTAssertEqual(metrics?.recitationAttempts, 4)
        XCTAssertEqual(metrics?.streakDays, 5)
    }

    func test_focus_exceeds_quranSeconds_clamps_reading_to_zero() {
        // Defensive: if focus accidentally > total (drift), reading must not go negative
        stamp()
        let day = dayKey()
        defaults.set(5 * 60, forKey: AppGroupConstants.quranSecondsKey(day))
        defaults.set(10 * 60, forKey: AppGroupConstants.focusSecondsKey(day))

        let report = QuranEngagementReportBuilder.build(defaults: defaults, now: fixedDate)
        XCTAssertEqual(report.metrics?.readingSeconds, 0)
    }
}
