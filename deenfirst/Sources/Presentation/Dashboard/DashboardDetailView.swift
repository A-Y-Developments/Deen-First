import DeviceActivity
import SwiftUI

/// Full-screen dashboard detail pushed from the Home summary card.
///
/// Flat (no inner `NavigationStack`) — pushed into the outer stack owned by
/// `RootView`. Renders one `DeviceActivityReport` per registered scene;
/// `WeeklyTrend` is driven by a dedicated 7-day daily-segmented filter
/// independent of the date-range picker to avoid silent data collapse.
struct DashboardDetailView: View {
    @StateObject private var viewModel = DashboardDetailViewModel()

    private let deenScoreContext = DeviceActivityReport.Context(rawValue: "DeenScore")
    private let screenTimeOverviewContext = DeviceActivityReport.Context(rawValue: "ScreenTimeOverview")
    private let quranEngagementContext = DeviceActivityReport.Context(rawValue: "QuranEngagementToday")
    private let quranVsScreenTimeContext = DeviceActivityReport.Context(rawValue: "QuranVsScreenTime")
    private let weeklyTrendContext = DeviceActivityReport.Context(rawValue: "WeeklyTrend")

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Range", selection: $viewModel.dateRange) {
                    ForEach(DashboardDetailViewModel.DateRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                section(context: deenScoreContext, filter: viewModel.filter, minHeight: 200)
                section(context: screenTimeOverviewContext, filter: viewModel.filter, minHeight: 260)
                section(context: quranEngagementContext, filter: viewModel.filter, minHeight: 200)
                section(context: quranVsScreenTimeContext, filter: viewModel.filter, minHeight: 220)
                section(context: weeklyTrendContext, filter: viewModel.weeklyTrendFilter, minHeight: 260)
            }
            .padding(.vertical, 24)
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            viewModel.refresh()
        }
        .navigationTitle("Dashboard")
        .mainBackground()
    }

    private func section(
        context: DeviceActivityReport.Context,
        filter: DeviceActivityFilter,
        minHeight: CGFloat
    ) -> some View {
        DashboardReportSection(
            context: context,
            filter: filter,
            refreshNonce: viewModel.refreshNonce,
            minHeight: minHeight,
            fallback: fallbackPlaceholder
        )
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
}

/// Shows `fallback` until the `DeviceActivityReport` host has had time to
/// mount the extension UI, then swaps in the report. Avoids the ZStack
/// occlusion bug where an opaque-but-empty report would hide the fallback.
private struct DashboardReportSection<Fallback: View>: View {
    let context: DeviceActivityReport.Context
    let filter: DeviceActivityFilter
    let refreshNonce: Int
    let minHeight: CGFloat
    let fallback: Fallback

    @State private var reportReady = false

    var body: some View {
        Group {
            if reportReady {
                DeviceActivityReport(context, filter: filter)
                    .id(refreshNonce)
            } else {
                fallback
            }
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal)
        .task {
            // DeviceActivityReport exposes no load/error callback. A brief
            // pause lets the extension register before swapping in the report
            // so the placeholder is the baseline, not an afterthought.
            try? await Task.sleep(nanoseconds: 400_000_000)
            reportReady = true
        }
    }
}
