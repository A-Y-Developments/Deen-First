import SwiftUI

/// "Quran Engagement Today" section rendered inside `DeenFirstActivityReport`.
/// Shows reading time, focus listening + session count, recitation pass/attempts,
/// and current streak — or a "No data yet" placeholder when nothing has been
/// written to the App Group yet.
struct QuranEngagementSectionView: View {
    let report: QuranEngagementReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quran Engagement Today")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let metrics = report.metrics {
                metricsList(metrics)
            } else {
                EmptyPlaceholder()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metricsList(_ m: QuranEngagementReport.Metrics) -> some View {
        VStack(spacing: 10) {
            EngagementRow(
                title: "Reading time",
                value: Self.minutesString(seconds: m.readingSeconds)
            )
            EngagementRow(
                title: "Focus listening",
                value: focusValue(seconds: m.focusListeningSeconds, sessions: m.focusSessionCount)
            )
            EngagementRow(
                title: "Recitations",
                value: "\(m.recitationsPassed) passed / \(m.recitationAttempts) attempts"
            )
            EngagementRow(
                title: "Current streak",
                value: streakString(days: m.streakDays)
            )
        }
    }

    // MARK: - Formatting

    private static func minutesString(seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        return "\(minutes) min"
    }

    private func focusValue(seconds: Int, sessions: Int) -> String {
        let sessionWord = sessions == 1 ? "session" : "sessions"
        return "\(Self.minutesString(seconds: seconds)) · \(sessions) \(sessionWord)"
    }

    private func streakString(days: Int) -> String {
        let dayWord = days == 1 ? "day" : "days"
        return "\(days) \(dayWord)"
    }
}

// MARK: - Row

private struct EngagementRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Empty fallback

private struct EmptyPlaceholder: View {
    var body: some View {
        HStack {
            Spacer()
            Text("No data yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 12)
        .accessibilityLabel("Quran engagement: no data yet")
    }
}
