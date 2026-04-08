import XCTest

@testable import DeenFirst

final class QuranVsScreenTimeReportBuilderTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    // 2026-04-08 12:00:00 UTC — same anchor used by sibling builder tests.
    private let fixedDate = Date(timeIntervalSince1970: 1_775_995_200)

    override func setUp() {
        super.setUp()
        suiteName = "QuranVsScreenTimeReportBuilderTests.\(UUID().uuidString)"
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

    func test_nil_defaults_returns_empty() {
        let report = QuranVsScreenTimeReportBuilder.build(
            totalScreenTimeSeconds: 1_000,
            defaults: nil,
            now: fixedDate
        )
        XCTAssertEqual(report.quranSeconds, 0)
        XCTAssertEqual(report.screenTimeSeconds, 0)
        XCTAssertTrue(report.isEmpty)
    }

    func test_zero_inputs_are_empty() {
        let report = QuranVsScreenTimeReportBuilder.build(
            totalScreenTimeSeconds: 0,
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertTrue(report.isEmpty)
    }

    func test_pairs_quran_seconds_with_screen_time() {
        defaults.set(15 * 60, forKey: AppGroupConstants.quranSecondsKey(dayKey()))
        let report = QuranVsScreenTimeReportBuilder.build(
            totalScreenTimeSeconds: 90 * 60,
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertEqual(report.quranSeconds, 15 * 60)
        XCTAssertEqual(report.screenTimeSeconds, 90 * 60)
        XCTAssertFalse(report.isEmpty)
    }

    func test_negative_screen_time_clamped_to_zero() {
        let report = QuranVsScreenTimeReportBuilder.build(
            totalScreenTimeSeconds: -500,
            defaults: defaults,
            now: fixedDate
        )
        XCTAssertEqual(report.screenTimeSeconds, 0)
    }
}
