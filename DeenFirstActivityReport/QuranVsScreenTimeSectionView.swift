import SwiftUI

/// "Quran vs Screen Time" comparison section rendered inside
/// `DeenFirstActivityReport`. Two side-by-side bars — Quran minutes vs total
/// screen time minutes — give the user an immediate sense of where their day
/// went. Heights are scaled against the larger of the two values so the
/// dominant column always reaches the top of the chart frame.
struct QuranVsScreenTimeSectionView: View {
    let report: QuranVsScreenTimeReport

    private static let chartHeight: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(icon: "scalemass", title: "Quran vs Screen Time")

            if report.isEmpty {
                EmptyState()
            } else {
                chart
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chart: some View {
        let quranMinutes = Self.minutes(seconds: report.quranSeconds)
        let screenMinutes = Self.minutes(seconds: report.screenTimeSeconds)
        let maxMinutes = max(quranMinutes, screenMinutes, 1)

        return HStack(alignment: .bottom, spacing: 32) {
            ComparisonBar(
                title: "Quran",
                minutes: quranMinutes,
                fraction: Double(quranMinutes) / Double(maxMinutes),
                color: DashboardTheme.accent
            )
            ComparisonBar(
                title: "Screen Time",
                minutes: screenMinutes,
                fraction: Double(screenMinutes) / Double(maxMinutes),
                color: DashboardTheme.mutedBar
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.chartHeight + 36) // chart + label/value rows
    }

    private static func minutes(seconds: Int) -> Int {
        max(0, seconds) / 60
    }
}

// MARK: - Bar

private struct ComparisonBar: View {
    let title: String
    let minutes: Int
    let fraction: Double
    let color: Color

    private static let barWidth: CGFloat = 56
    private static let barHeight: CGFloat = 140

    var body: some View {
        VStack(spacing: 8) {
            Text("\(minutes)m")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(DashboardTheme.textPrimary)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(DashboardTheme.track)
                    .frame(width: Self.barWidth, height: Self.barHeight)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                    .frame(
                        width: Self.barWidth,
                        height: max(4, Self.barHeight * CGFloat(max(0, min(1, fraction))))
                    )
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(DashboardTheme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(minutes) minutes")
    }
}

// MARK: - Empty state

private struct EmptyState: View {
    var body: some View {
        HStack {
            Spacer()
            Text("No activity yet")
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 24)
        .accessibilityLabel("Quran vs Screen Time: no activity yet")
    }
}
