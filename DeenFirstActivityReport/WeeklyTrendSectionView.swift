import SwiftUI

/// "Weekly Trend" section rendered inside `DeenFirstActivityReport`. Renders
/// the last 7 days of Deen Score as a bar chart. Today's bar uses the accent
/// color so the in-progress state is visually distinct from completed days.
/// Days with no recorded data render as a thin, dim 0-bar (no crash).
struct WeeklyTrendSectionView: View {
    let report: WeeklyTrendReport

    private static let chartHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.headline)
                .foregroundStyle(.secondary)

            if report.days.isEmpty {
                EmptyState()
            } else {
                chart
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
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

// MARK: - Bar

private struct TrendBar: View {
    let day: WeeklyTrendReport.DayPoint
    let chartHeight: CGFloat

    private static let maxScore: Double = 100

    private var fraction: Double {
        max(0, min(1, Double(day.score) / Self.maxScore))
    }

    private var fillColor: Color {
        if !day.hasData { return Color.secondary.opacity(0.25) }
        if day.isToday { return .accentColor }
        switch day.score {
        case 80...: return .green
        case 60..<80: return .mint
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    private var weekdayLabel: String {
        WeeklyTrendFormatter.weekdayLabel(for: day.date)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(day.score)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(day.hasData ? .primary : .secondary)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 24, height: chartHeight)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor)
                    .frame(
                        width: 24,
                        height: max(2, chartHeight * CGFloat(fraction))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(day.isToday ? Color.accentColor : .clear, lineWidth: 2)
                    )
            }

            Text(weekdayLabel)
                .font(.caption2)
                .foregroundStyle(day.isToday ? .primary : .secondary)
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
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 24)
        .accessibilityLabel("Weekly trend: no data yet")
    }
}
