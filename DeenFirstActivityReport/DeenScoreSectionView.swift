import SwiftUI

/// Deen Score section rendered inside the `DeenFirstActivityReport` extension.
/// Shows a circular progress ring with the 0–100 score and a contextual message,
/// or a loading fallback when data is not yet available.
struct DeenScoreSectionView: View {
    let report: DeenScoreReport

    var body: some View {
        VStack(spacing: 16) {
            Text("Deen Score")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let score = report.score {
                DeenScoreRing(score: score)
                Text(report.message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
            } else {
                LoadingPlaceholder(message: report.message)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ring

private struct DeenScoreRing: View {
    let score: Int

    private var progress: Double {
        max(0, min(1, Double(score) / 100.0))
    }

    private var ringColor: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .mint
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 160, height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Deen Score")
        .accessibilityValue("\(score) out of 100")
    }
}

// MARK: - Loading fallback

private struct LoadingPlaceholder: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                .frame(width: 160, height: 160)
                .overlay(
                    ProgressView()
                        .controlSize(.large)
                )
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Deen Score loading")
    }
}
