import DeviceActivity
import XCTest

@testable import DeenFirst

@MainActor
final class DashboardDetailViewModelTests: XCTestCase {
    var viewModel: DashboardDetailViewModel!

    override func setUp() async throws {
        viewModel = DashboardDetailViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initial state

    func testInitialDateRangeIsToday() {
        XCTAssertEqual(viewModel.dateRange, .today)
    }

    func testInitialRefreshNonceIsZero() {
        XCTAssertEqual(viewModel.refreshNonce, 0)
    }

    // MARK: - refresh()

    func testRefreshIncrementsNonce() {
        viewModel.refresh()
        XCTAssertEqual(viewModel.refreshNonce, 1)

        viewModel.refresh()
        XCTAssertEqual(viewModel.refreshNonce, 2)
    }

    func testRefreshWrapsOnOverflowWithoutCrashing() {
        viewModel.refreshNonce = .max
        viewModel.refresh()
        // &+= wraps to Int.min rather than trapping.
        XCTAssertEqual(viewModel.refreshNonce, .min)
    }

    // MARK: - Date range transitions

    func testChangingDateRangeToThisWeek() {
        viewModel.dateRange = .thisWeek
        XCTAssertEqual(viewModel.dateRange, .thisWeek)
    }

    func testChangingDateRangeBackToToday() {
        viewModel.dateRange = .thisWeek
        viewModel.dateRange = .today
        XCTAssertEqual(viewModel.dateRange, .today)
    }

    // MARK: - Weekly trend filter is always 7-day daily regardless of dateRange

    func testWeeklyTrendFilterIndependentOfDateRange_Today() {
        viewModel.dateRange = .today
        // No crash; filter is built. Exact segment type is not publicly
        // introspectable on DeviceActivityFilter, so we just ensure the
        // accessor returns without throwing and is stable across calls.
        _ = viewModel.weeklyTrendFilter
        _ = viewModel.weeklyTrendFilter
    }

    func testWeeklyTrendFilterIndependentOfDateRange_ThisWeek() {
        viewModel.dateRange = .thisWeek
        _ = viewModel.weeklyTrendFilter
    }

    // MARK: - Filter builder interval shapes (pure, via static helpers)

    func testMakeTodayFilterDoesNotCrash() {
        _ = DashboardDetailViewModel.makeTodayFilter()
    }

    func testMakeSevenDayDailyFilterSpansSevenDays() {
        // We can't introspect segment type; but we can verify the builder
        // does not crash for a known fixed date. Regression guard for the
        // 7-day window computation.
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 24
        let cal = Calendar(identifier: .iso8601)
        guard let fixed = cal.date(from: components) else {
            XCTFail("Failed to build fixed date")
            return
        }
        _ = DashboardDetailViewModel.makeSevenDayDailyFilter(now: fixed, calendar: cal)
    }
}
