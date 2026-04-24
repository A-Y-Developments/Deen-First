import DeviceActivity
import SwiftUI

/// Thin host view for the Dashboard tab.
///
/// Each section is rendered by its own `DeviceActivityReport` host view, one per
/// scene registered by `DeenFirstActivityReportExtension`. A single shared host
/// cannot drive multiple scenes, so sections must be instantiated individually.
/// The fallback placeholder sits behind each report so the user always sees a
/// message instead of an empty frame when the extension is unavailable.
struct DashboardTabView: View {
    private enum DateRange: String, CaseIterable, Identifiable {
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

    private let deenScoreContext = DeviceActivityReport.Context(rawValue: "DeenScore")
    private let screenTimeOverviewContext = DeviceActivityReport.Context(rawValue: "ScreenTimeOverview")
    private let quranEngagementContext = DeviceActivityReport.Context(rawValue: "QuranEngagementToday")
    private let quranVsScreenTimeContext = DeviceActivityReport.Context(rawValue: "QuranVsScreenTime")
    private let weeklyTrendContext = DeviceActivityReport.Context(rawValue: "WeeklyTrend")

    @State private var dateRange: DateRange = .today
    @State private var refreshNonce = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Range", selection: $dateRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    section(
                        context: deenScoreContext,
                        filter: filter,
                        minHeight: 200
                    )
                    section(
                        context: screenTimeOverviewContext,
                        filter: filter,
                        minHeight: 260
                    )
                    section(
                        context: quranEngagementContext,
                        filter: filter,
                        minHeight: 200
                    )
                    section(
                        context: quranVsScreenTimeContext,
                        filter: filter,
                        minHeight: 220
                    )
                    section(
                        context: weeklyTrendContext,
                        filter: weeklyTrendFilter,
                        minHeight: 260
                    )
                }
                .padding(.vertical, 24)
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                refreshNonce &+= 1
            }
            .navigationTitle("Dashboard")
        }
        .mainBackground()
    }

    private func section(
        context: DeviceActivityReport.Context,
        filter: DeviceActivityFilter,
        minHeight: CGFloat
    ) -> some View {
        ZStack {
            fallbackPlaceholder
            DeviceActivityReport(context, filter: filter)
                .id(refreshNonce)
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal)
    }

    private var fallbackPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
            Text("Dashboard unavailable")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("Pull down to refresh.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dashboard unavailable. Pull down to refresh.")
    }

    private var filter: DeviceActivityFilter {
        switch dateRange {
        case .today:
            let interval = Calendar.current.dateInterval(of: .day, for: .now)
                ?? DateInterval(start: .now, duration: 86_400)
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone])
            )
        case .thisWeek:
            return Self.makeSevenDayDailyFilter()
        }
    }

    /// Weekly Trend always needs 7 daily segments so
    /// `WeeklyTrendReportScene` can bucket by day. Driven independently of
    /// `dateRange` to avoid silent data bugs when the user picks "Today".
    private var weeklyTrendFilter: DeviceActivityFilter {
        Self.makeSevenDayDailyFilter()
    }

    private static func makeSevenDayDailyFilter(
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
