import Foundation

/// Configuration model produced by `ScreenTimeOverviewReportScene.makeConfiguration`
/// and consumed by `ScreenTimeOverviewSectionView`.
///
/// `isEmpty == true` signals there is no usage data to render — the section
/// should show an empty state.
struct ScreenTimeOverviewReport {
    let totalScreenTimeSeconds: Int
    let pickupCount: Int
    /// Hours elapsed since local midnight at the time the report was built.
    /// Used to compute the "every X min" pickup interval.
    let hoursSinceMidnight: Double
    let topApps: [TopAppEntry]

    var isEmpty: Bool {
        totalScreenTimeSeconds == 0 && pickupCount == 0 && topApps.isEmpty
    }

    static let empty = ScreenTimeOverviewReport(
        totalScreenTimeSeconds: 0,
        pickupCount: 0,
        hoursSinceMidnight: 0,
        topApps: []
    )
}

/// One row in the top-apps list. `id` is the bundle identifier when available,
/// falling back to the display name so SwiftUI can dedupe rows.
struct TopAppEntry: Identifiable, Hashable {
    let id: String
    let displayName: String
    let durationSeconds: Int
}

// MARK: - Pure helpers

enum ScreenTimeOverviewFormatter {
    /// Renders a duration as `"2h 34m"` / `"34m"` / `"45s"`.
    /// Seconds are only shown when the total is under one minute.
    static func formatDuration(seconds: Int) -> String {
        let safe = max(0, seconds)
        let hours = safe / 3600
        let minutes = (safe % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(safe)s"
    }

    /// Renders the average pickup interval as `"every 7 min"`.
    /// Returns `nil` when there are no pickups or no elapsed time yet.
    static func formatPickupInterval(pickupCount: Int, hoursSinceMidnight: Double) -> String? {
        guard pickupCount > 0, hoursSinceMidnight > 0 else { return nil }
        let minutesElapsed = hoursSinceMidnight * 60
        let avgMinutes = Int((minutesElapsed / Double(pickupCount)).rounded())
        guard avgMinutes > 0 else { return nil }
        return "every \(avgMinutes) min"
    }
}

/// Aggregates per-app usage durations into a sorted top-N list.
/// Apps with `displayName == nil` (no token access) are dropped before sorting,
/// matching the acceptance criterion that only token-accessible apps are shown.
enum TopAppsAggregator {
    /// Raw usage tuple. `bundleId` may be nil for apps without an identifier;
    /// `displayName` is nil when the user hasn't granted token access.
    struct AppUsage {
        let bundleId: String?
        let displayName: String?
        let durationSeconds: Int
    }

    static func topApps(from usages: [AppUsage], limit: Int = 5) -> [TopAppEntry] {
        // Group by stable key (bundleId, falling back to displayName) and sum durations.
        var totals: [String: (displayName: String, seconds: Int)] = [:]
        for usage in usages {
            guard let displayName = usage.displayName, !displayName.isEmpty else { continue }
            guard usage.durationSeconds > 0 else { continue }
            let key = usage.bundleId ?? displayName
            let existing = totals[key]
            totals[key] = (
                displayName: existing?.displayName ?? displayName,
                seconds: (existing?.seconds ?? 0) + usage.durationSeconds
            )
        }

        return totals
            .map { TopAppEntry(id: $0.key, displayName: $0.value.displayName, durationSeconds: $0.value.seconds) }
            .sorted { lhs, rhs in
                if lhs.durationSeconds != rhs.durationSeconds {
                    return lhs.durationSeconds > rhs.durationSeconds
                }
                return lhs.displayName < rhs.displayName
            }
            .prefix(limit)
            .map { $0 }
    }
}
