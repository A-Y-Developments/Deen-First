import XCTest

@testable import DeenFirst

final class DeenScoreReportBuilderTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    // 2026-04-08 12:00:00 UTC — Wednesday of ISO week 15
    private let fixedDate = Date(timeIntervalSince1970: 1_775_995_200)

    override func setUp() {
        super.setUp()
        suiteName = "DeenScoreReportBuilderTests.\(UUID().uuidString)"
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
    private func weekKey() -> String { DashboardDateKeys.weekKey(for: fixedDate) }

    func test_nil_defaults_returns_loading() {
        let report = DeenScoreReportBuilder.build(
            totalScreenTimeSeconds: 0,
            defaults: nil,
            now: fixedDate
        )
        XCTAssertNil(report.score)
        XCTAssertEqual(report.message, "Score loading…")
    }

    func test_empty_defaults_returns_base_score() {
        // All zeros → base 50, no penalties → "Average day" range
        let report = DeenScoreReportBuilder.build(
            totalScreenTimeSeconds: 0,
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertEqual(report.score, 50)
        XCTAssertEqual(report.message, "Average day. More Quran or less screen time.")
    }

    func test_high_engagement_boosts_score() {
        defaults.set(35 * 60, forKey: AppGroupConstants.quranSecondsKey(dayKey())) // +20
        defaults.set(2, forKey: AppGroupConstants.focusSessionsKey(dayKey()))      // +15
        defaults.set(3, forKey: AppGroupConstants.recitationsPassedKey(dayKey()))  // +10
        defaults.set(10, forKey: AppGroupConstants.streakCurrentKey)                // +5+5

        let report = DeenScoreReportBuilder.build(
            totalScreenTimeSeconds: 0,
            defaults: defaults,
            now: fixedDate
        )
        // 50 + 20 + 15 + 10 + 10 = 105 → clamped to 100
        XCTAssertEqual(report.score, 100)
        XCTAssertEqual(report.message, "Excellent day. Masha'Allah, keep this up.")
    }

    func test_over_limit_screen_time_penalises() {
        // default daily limit = 2h; total = 2.5h → 30min over → tier1 penalty -10
        let report = DeenScoreReportBuilder.build(
            totalScreenTimeSeconds: Int(2.5 * 60 * 60),
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertEqual(report.score, 40) // 50 - 10
    }

    func test_emergency_unblocks_penalise() {
        defaults.set(2, forKey: AppGroupConstants.emergencyUnblocksKey(weekKey())) // -10
        let report = DeenScoreReportBuilder.build(
            totalScreenTimeSeconds: 0,
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertEqual(report.score, 40)
    }

    func test_screen_time_under_limit_no_penalty() {
        // 1h screen time, limit 2h → overLimit = 0 → no penalty
        let report = DeenScoreReportBuilder.build(
            totalScreenTimeSeconds: 60 * 60,
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertEqual(report.score, 50)
    }
}
