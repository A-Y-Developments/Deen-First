import SwiftUI

/// Screen Time Overview section rendered inside the `DeenFirstActivityReport`
/// extension. Shows total screen time, pickup count + average interval, and a
/// horizontal bar chart of the top 3–5 token-accessible apps.
struct ScreenTimeOverviewSectionView: View {
    let report: ScreenTimeOverviewReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DashboardSectionHeader(icon: "hourglass", title: "Screen Time")

            if report.isEmpty {
                EmptyState()
            } else {
                summary
                if !report.topApps.isEmpty {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                    TopAppsList(apps: report.topApps)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ScreenTimeOverviewFormatter.formatDuration(seconds: report.totalScreenTimeSeconds))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardTheme.textPrimary)
                .monospacedDigit()
                .accessibilityLabel("Total screen time today")
                .accessibilityValue(
                    ScreenTimeOverviewFormatter.formatDuration(seconds: report.totalScreenTimeSeconds)
                )

            HStack(spacing: 6) {
                Text("\(report.pickupCount) pickups")
                    .font(.subheadline)
                    .foregroundStyle(DashboardTheme.textPrimary)
                if let interval = ScreenTimeOverviewFormatter.formatPickupInterval(
                    pickupCount: report.pickupCount,
                    hoursSinceMidnight: report.hoursSinceMidnight
                ) {
                    Text("· \(interval)")
                        .font(.subheadline)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Top apps list

private struct TopAppsList: View {
    let apps: [TopAppEntry]

    private var maxSeconds: Int {
        max(1, apps.map(\.durationSeconds).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top apps")
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.textSecondary)

            ForEach(apps) { app in
                TopAppRow(
                    app: app,
                    fraction: Double(app.durationSeconds) / Double(maxSeconds)
                )
            }
        }
    }
}

private struct TopAppRow: View {
    let app: TopAppEntry
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(app.displayName)
                    .font(.subheadline)
                    .foregroundStyle(DashboardTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Text(ScreenTimeOverviewFormatter.formatDuration(seconds: app.durationSeconds))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DashboardTheme.track)
                    Capsule()
                        .fill(DashboardTheme.accent)
                        .frame(width: proxy.size.width * max(0, min(1, fraction)))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(app.displayName)
        .accessibilityValue(
            ScreenTimeOverviewFormatter.formatDuration(seconds: app.durationSeconds)
        )
    }
}

// MARK: - Empty state

private struct EmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No screen time data yet", systemImage: "moon.zzz")
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.textSecondary)
            Text("Use your phone for a bit and pull to refresh.")
                .font(.caption)
                .foregroundStyle(DashboardTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
