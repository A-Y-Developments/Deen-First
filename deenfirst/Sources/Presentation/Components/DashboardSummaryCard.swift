import SwiftUI

/// Compact dashboard summary surface shown on the Home tab. Displays the user's
/// Deen Score (0–100) and three quick daily stats. Tapping pushes the full
/// `DashboardDetailView`.
///
/// Values are rendered from plain Ints — the caller (typically
/// `HomeTabViewModel`) is responsible for reading them from the App Group and
/// computing `deenScore` via `calculateDeenScore(_:)`.
struct DashboardSummaryCard: View {
    let deenScore: Int
    let focusSessions: Int
    let recitationsPassed: Int
    let streakDays: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    scoreRing
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deen Score")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "AEF29B"))
                            .textCase(.uppercase)
                        Text("\(deenScore)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        Text("out of 100 today")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Divider()
                    .overlay(Color.white.opacity(0.12))

                HStack(spacing: 0) {
                    stat(value: focusSessions, label: "Sessions")
                    statDivider
                    stat(value: recitationsPassed, label: "Recitations")
                    statDivider
                    stat(value: streakDays, label: "Streak")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.primary900)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var scoreRing: some View {
        let fraction = max(0, min(1, Double(deenScore) / 100.0))
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    Color(hex: "AEF29B"),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(deenScore)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .frame(width: 56, height: 56)
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 28)
    }
}
