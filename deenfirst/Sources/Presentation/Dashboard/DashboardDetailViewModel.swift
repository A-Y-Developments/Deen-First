import DeviceActivity
import Foundation

/// ViewModel for `DashboardDetailView`. Owns the date-range picker state,
/// refresh nonce (pull-to-refresh), and builds the `DeviceActivityFilter`
/// driving the five `DeviceActivityReport` hosts.
@MainActor
final class DashboardDetailViewModel: ObservableObject {
    enum DateRange: String, CaseIterable, Identifiable {
        case today
        case thisWeek

        var id: String { rawValue }

        var label: String {
            switch self {
            case .today: return "Today"
            case .thisWeek: return "This Week"
            }
        }
    }

    @Published var dateRange: DateRange = .today
    @Published var refreshNonce: Int = 0

    /// Filter driving DeenScore / ScreenTimeOverview / QuranEngagement / QuranVsScreenTime.
    /// Follows the user-selected range.
    var filter: DeviceActivityFilter {
        switch dateRange {
        case .today:
            return Self.makeTodayFilter()
        case .thisWeek:
            return Self.makeSevenDayDailyFilter()
        }
    }

    /// WeeklyTrend always needs 7 daily segments — independent of `dateRange`
    /// so the chart cannot silently collapse to 1 bar when user picks Today.
    var weeklyTrendFilter: DeviceActivityFilter {
        Self.makeSevenDayDailyFilter()
    }

    func refresh() {
        refreshNonce &+= 1
    }

    // MARK: - Filter builders (pure, testable)

    static func makeTodayFilter(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> DeviceActivityFilter {
        let interval = calendar.dateInterval(of: .day, for: now)
            ?? DateInterval(start: now, duration: 86_400)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    static func makeSevenDayDailyFilter(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> DeviceActivityFilter {
        let todayStart = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
        let interval = DateInterval(start: sevenDaysAgo, end: now)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone])
        )
    }
}
