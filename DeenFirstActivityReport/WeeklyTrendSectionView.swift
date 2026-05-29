import SwiftUI

/// "Weekly Trend" section rendered inside `DeenFirstActivityReport`. Renders
/// the last 7 days of Deen Score as a bar chart. Today's bar uses the accent
/// color so the in-progress state is visually distinct from completed days.
/// Days with no recorded data render as a thin, dim 0-bar (no crash).
///
/// A header chip compares today's score with the average of the other recorded
/// days in the window — computed entirely from the points already in `report`,
/// so it needs no extra data plumbing.
struct WeeklyTrendSectionView: View {
    let report: WeeklyTrendReport

    private static let chartHeight: CGFloat = 120

    /// Today's score minus the average of the other days that have data.
    /// `nil` when today has no data or there aren't enough prior days to compare.
    private var deltaVsAverage: Int? {
        guard let today = report.days.first(where: { $0.isToday }), today.hasData else {
            return nil
        }
        let priors = report.days.filter { !$0.isToday && $0.hasData }
        guard !priors.isEmpty else { return nil }
        let average = priors.map(\.score).reduce(0, +) / priors.count
        return today.score - average
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(icon: "chart.line.uptrend.xyaxis", title: "Weekly Trend") {
                if let delta = deltaVsAverage {
                    DeltaChip(delta: delta)
                }
            }

            if report.days.isEmpty {
                EmptyState()
            } else {
                chart
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chart: some View {
        // Score is 0...100, so the visual ceiling is fixed — bars are sized
        // against 100 rather than the day-max so heights remain comparable
        // across renders.
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(report.days, id: \.dayKey) { day in
                TrendBar(
                    day: day,
                    chartHeight: Self.chartHeight
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.chartHeight + 36) // chart + label/value rows
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly Deen Score trend")
    }
}

// MARK: - Delta chip

private struct DeltaChip: View {
    let delta: Int

    private var isUp: Bool { delta >= 0 }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text("\(abs(delta)) vs avg")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(isUp ? DashboardTheme.accent : DashboardTheme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DashboardTheme.tileFill, in: Capsule())
        .accessibilityLabel(
            isUp
                ? "Today is \(abs(delta)) above your average"
                : "Today is \(abs(delta)) below your average"
        )
    }
}

// MARK: - Bar

private struct TrendBar: View {
    let day: WeeklyTrendReport.DayPoint
    let chartHeight: CGFloat

    private static let maxScore: Double = 100

    private var fraction: Double {
        max(0, min(1, Double(day.score) / Self.maxScore))
    }

    private var fillColor: Color {
        if !day.hasData { return Color.white.opacity(0.18) }
        if day.isToday { return DashboardTheme.accent }
        return DashboardTheme.ringColor(for: day.score)
    }

    private var weekdayLabel: String {
        WeeklyTrendFormatter.weekdayLabel(for: day.date)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(day.score)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(day.hasData ? DashboardTheme.textPrimary : DashboardTheme.textTertiary)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(DashboardTheme.track)
                    .frame(width: 24, height: chartHeight)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor)
                    .frame(
                        width: 24,
                        height: max(2, chartHeight * CGFloat(fraction))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(day.isToday ? DashboardTheme.accent : .clear, lineWidth: 2)
                    )
            }

            Text(weekdayLabel)
                .font(.caption2)
                .foregroundStyle(day.isToday ? DashboardTheme.textPrimary : DashboardTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.isToday ? "Today" : weekdayLabel)
        .accessibilityValue(
            day.hasData ? "\(day.score) out of 100" : "no data"
        )
    }
}

// MARK: - Empty state

private struct EmptyState: View {
    var body: some View {
        HStack {
            Spacer()
            Text("No trend data yet")
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 24)
        .accessibilityLabel("Weekly trend: no data yet")
    }
}
