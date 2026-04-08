import XCTest

@testable import DeenFirst

final class ScreenTimeOverviewFormatterTests: XCTestCase {

    // MARK: - formatDuration

    func test_formatDuration_hours_and_minutes() {
        XCTAssertEqual(
            ScreenTimeOverviewFormatter.formatDuration(seconds: 2 * 3600 + 34 * 60),
            "2h 34m"
        )
    }

    func test_formatDuration_minutes_only() {
        XCTAssertEqual(ScreenTimeOverviewFormatter.formatDuration(seconds: 45 * 60), "45m")
    }

    func test_formatDuration_hours_with_zero_minutes() {
        XCTAssertEqual(ScreenTimeOverviewFormatter.formatDuration(seconds: 3 * 3600), "3h 0m")
    }

    func test_formatDuration_seconds_for_sub_minute() {
        XCTAssertEqual(ScreenTimeOverviewFormatter.formatDuration(seconds: 30), "30s")
    }

    func test_formatDuration_zero() {
        XCTAssertEqual(ScreenTimeOverviewFormatter.formatDuration(seconds: 0), "0s")
    }

    func test_formatDuration_negative_clamped_to_zero() {
        XCTAssertEqual(ScreenTimeOverviewFormatter.formatDuration(seconds: -10), "0s")
    }

    // MARK: - formatPickupInterval

    func test_formatPickupInterval_normal() {
        // 30 pickups in 3.5h = 210 min → 7 min interval
        XCTAssertEqual(
            ScreenTimeOverviewFormatter.formatPickupInterval(pickupCount: 30, hoursSinceMidnight: 3.5),
            "every 7 min"
        )
    }

    func test_formatPickupInterval_zero_pickups_returns_nil() {
        XCTAssertNil(
            ScreenTimeOverviewFormatter.formatPickupInterval(pickupCount: 0, hoursSinceMidnight: 5)
        )
    }

    func test_formatPickupInterval_zero_hours_returns_nil() {
        XCTAssertNil(
            ScreenTimeOverviewFormatter.formatPickupInterval(pickupCount: 10, hoursSinceMidnight: 0)
        )
    }

    func test_formatPickupInterval_under_one_minute_returns_nil() {
        // 1000 pickups in 1h = 0.06 min/pickup → rounds to 0 → nil
        XCTAssertNil(
            ScreenTimeOverviewFormatter.formatPickupInterval(pickupCount: 1000, hoursSinceMidnight: 1)
        )
    }
}

final class TopAppsAggregatorTests: XCTestCase {
    private func usage(
        bundleId: String? = nil,
        name: String?,
        seconds: Int
    ) -> TopAppsAggregator.AppUsage {
        TopAppsAggregator.AppUsage(bundleId: bundleId, displayName: name, durationSeconds: seconds)
    }

    func test_drops_apps_without_display_name() {
        let result = TopAppsAggregator.topApps(from: [
            usage(bundleId: "a", name: nil, seconds: 1000),
            usage(bundleId: "b", name: "Safari", seconds: 500),
        ])
        XCTAssertEqual(result.map(\.displayName), ["Safari"])
    }

    func test_drops_zero_duration_apps() {
        let result = TopAppsAggregator.topApps(from: [
            usage(name: "Mail", seconds: 0),
            usage(name: "Notes", seconds: 60),
        ])
        XCTAssertEqual(result.map(\.displayName), ["Notes"])
    }

    func test_sorts_descending_by_duration() {
        let result = TopAppsAggregator.topApps(from: [
            usage(bundleId: "a", name: "Safari", seconds: 100),
            usage(bundleId: "b", name: "Mail", seconds: 500),
            usage(bundleId: "c", name: "Notes", seconds: 300),
        ])
        XCTAssertEqual(result.map(\.displayName), ["Mail", "Notes", "Safari"])
    }

    func test_aggregates_same_bundle_id() {
        let result = TopAppsAggregator.topApps(from: [
            usage(bundleId: "com.app", name: "App", seconds: 100),
            usage(bundleId: "com.app", name: "App", seconds: 200),
        ])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.durationSeconds, 300)
    }

    func test_limits_to_five_by_default() {
        let usages = (0..<10).map { usage(bundleId: "id\($0)", name: "App\($0)", seconds: ($0 + 1) * 60) }
        let result = TopAppsAggregator.topApps(from: usages)
        XCTAssertEqual(result.count, 5)
        // Top 5 are App9..App5
        XCTAssertEqual(result.map(\.displayName), ["App9", "App8", "App7", "App6", "App5"])
    }

    func test_handles_fewer_than_three_apps_without_crash() {
        let result = TopAppsAggregator.topApps(from: [
            usage(name: "Solo", seconds: 60),
        ])
        XCTAssertEqual(result.count, 1)
    }

    func test_empty_input_returns_empty() {
        XCTAssertTrue(TopAppsAggregator.topApps(from: []).isEmpty)
    }
}

final class ScreenTimeOverviewReportTests: XCTestCase {
    func test_isEmpty_when_zero_data() {
        XCTAssertTrue(ScreenTimeOverviewReport.empty.isEmpty)
    }

    func test_isNotEmpty_when_has_screen_time() {
        let report = ScreenTimeOverviewReport(
            totalScreenTimeSeconds: 60,
            pickupCount: 0,
            hoursSinceMidnight: 1,
            topApps: []
        )
        XCTAssertFalse(report.isEmpty)
    }

    func test_isNotEmpty_when_has_pickups() {
        let report = ScreenTimeOverviewReport(
            totalScreenTimeSeconds: 0,
            pickupCount: 5,
            hoursSinceMidnight: 1,
            topApps: []
        )
        XCTAssertFalse(report.isEmpty)
    }
}
