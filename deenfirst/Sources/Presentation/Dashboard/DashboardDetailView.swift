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
            VStack(spacing: 16) {
                DashboardRangeToggle(selection: $viewModel.dateRange)
                    .padding(.horizontal)

                section(context: deenScoreContext, filter: viewModel.filter, minHeight: 320)
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
            loading: loadingPlaceholder
        )
    }

    /// Opaque cover held over a freshly-mounted report to mask the extension's
    /// cold-start blank. Reads as "loading", not as an error. Each extension
    /// section also renders its own in-process empty/loading message, so once the
    /// report renders the user never sees a blank area (DF-37); this cover only
    /// hides the brief window before the extension paints at all.
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(Color(hex: "AEF29B"))
            Text("Score loading…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text("Pull down to refresh.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Score loading. Pull down to refresh.")
    }
}

/// Mounts the `DeviceActivityReport` immediately and holds an opaque `loading`
/// cover on top of it for a short, fixed window, then fades to the live report.
///
/// `DeviceActivityReport` exposes no "rendered" callback, so the cover is timed.
/// Covering the freshly-mounted report — rather than delaying the mount — lets
/// the extension cold-start *behind* the cover, hiding the blank gap the user
/// would otherwise see. The cover is intentionally front-most and opaque, so
/// there is no occlusion ambiguity with an empty report underneath.
private struct DashboardReportSection<Loading: View>: View {
    let context: DeviceActivityReport.Context
    let filter: DeviceActivityFilter
    let refreshNonce: Int
    let minHeight: CGFloat
    let loading: Loading

    /// How long to keep the cover up after each (re)mount. Tuned to outlast a
    /// typical extension cold start; bump it if a blank still flashes on the
    /// very first open after launch.
    private static var coverDuration: Duration { .milliseconds(900) }

    @State private var isLoading = true

    var body: some View {
        ZStack {
            DeviceActivityReport(context, filter: filter)
                .id(refreshNonce)

            if isLoading {
                loading
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.primary900)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            Color.primary900,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal)
        .task(id: refreshNonce) {
            isLoading = true
            try? await Task.sleep(for: Self.coverDuration)
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
}
