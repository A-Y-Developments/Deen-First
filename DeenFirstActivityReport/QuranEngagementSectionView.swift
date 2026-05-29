import SwiftUI

/// "Quran Engagement Today" section rendered inside `DeenFirstActivityReport`.
/// Shows reading time, focus listening + session count, recitation pass/attempts,
/// and current streak as a 2×2 stat-tile grid — or a "No data yet" placeholder
/// when nothing has been written to the App Group yet.
struct QuranEngagementSectionView: View {
    let report: QuranEngagementReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(icon: "book.fill", title: "Quran Engagement Today")

            if let metrics = report.metrics {
                grid(metrics)
            } else {
                EmptyPlaceholder()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func grid(_ m: QuranEngagementReport.Metrics) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(
                    value: Self.minutesString(seconds: m.readingSeconds),
                    label: "Reading"
                )
                StatTile(
                    value: Self.minutesString(seconds: m.focusListeningSeconds),
                    label: focusLabel(sessions: m.focusSessionCount)
                )
            }
            HStack(spacing: 10) {
                StatTile(
                    value: "\(m.recitationsPassed)/\(m.recitationAttempts)",
                    label: "Recitations"
                )
                StatTile(
                    value: streakString(days: m.streakDays),
                    label: bestStreakLabel(best: m.bestStreakDays)
                )
            }
        }
    }

    // MARK: - Formatting

    private static func minutesString(seconds: Int) -> String {
        "\(max(0, seconds) / 60)m"
    }

    private func focusLabel(sessions: Int) -> String {
        let word = sessions == 1 ? "session" : "sessions"
        return "Focus · \(sessions) \(word)"
    }

    private func streakString(days: Int) -> String {
        let word = days == 1 ? "day" : "days"
        return "\(days) \(word)"
    }

    private func bestStreakLabel(best: Int) -> String {
        best > 0 ? "Streak · best \(best)" : "Streak"
    }
}

// MARK: - Tile

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardTheme.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DashboardTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            DashboardTheme.tileFill,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Empty fallback

private struct EmptyPlaceholder: View {
    var body: some View {
        HStack {
            Spacer()
            Label("No data yet", systemImage: "book.closed")
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 12)
        .accessibilityLabel("Quran engagement: no data yet")
    }
}
