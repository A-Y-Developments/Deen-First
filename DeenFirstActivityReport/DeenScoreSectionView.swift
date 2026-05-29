import SwiftUI

/// Deen Score section rendered inside the `DeenFirstActivityReport` extension.
/// Shows a circular progress ring with the 0–100 score, a contextual message,
/// and a streak chip — or a loading fallback when data is not yet available.
struct DeenScoreSectionView: View {
    let report: DeenScoreReport

    var body: some View {
        VStack(spacing: 16) {
            DashboardSectionHeader(icon: "rosette", title: "Deen Score")

            if let score = report.score {
                DeenScoreRing(score: score)
                Text(report.message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .padding(.horizontal)
                if report.streakDays > 0 {
                    StreakChip(days: report.streakDays)
                }
            } else {
                LoadingPlaceholder(message: report.message)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ring

private struct DeenScoreRing: View {
    let score: Int

    private var progress: Double {
        max(0, min(1, Double(score) / 100.0))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DashboardTheme.track, lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DashboardTheme.ringColor(for: score),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(DashboardTheme.textPrimary)
                    .monospacedDigit()
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textTertiary)
            }
        }
        .frame(width: 160, height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Deen Score")
        .accessibilityValue("\(score) out of 100")
    }
}

// MARK: - Streak chip

private struct StreakChip: View {
    let days: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DashboardTheme.accent)
            Text("\(days)-day streak")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DashboardTheme.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DashboardTheme.tileFill, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(days) day streak")
    }
}

// MARK: - Loading fallback

private struct LoadingPlaceholder: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .stroke(DashboardTheme.track, lineWidth: 14)
                .frame(width: 160, height: 160)
                .overlay(
                    ProgressView()
                        .controlSize(.large)
                        .tint(DashboardTheme.accent)
                )
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Deen Score loading")
    }
}
