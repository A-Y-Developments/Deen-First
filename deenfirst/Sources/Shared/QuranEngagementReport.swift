import Foundation
import os

/// Configuration model produced by `QuranEngagementReportScene.makeConfiguration`
/// and consumed by `QuranEngagementSectionView`.
///
/// `metrics == nil` signals that no engagement data has ever been written to the
/// App Group (no `dataLastUpdatedAt` stamp), and the view should render its
/// "No data yet" fallback. Zero counters are valid data and rendered as "0".
struct QuranEngagementReport {
    struct Metrics {
        let readingSeconds: Int
        let focusListeningSeconds: Int
        let focusSessionCount: Int
        let recitationsPassed: Int
        let recitationAttempts: Int
        let streakDays: Int
    }

    let metrics: Metrics?

    static let empty = QuranEngagementReport(metrics: nil)
}

/// Reads today's Quran engagement counters from the App Group and packages them
/// for `QuranEngagementSectionView`. Pure aside from defaults reads.
///
/// Reading time is derived as `quranSeconds - focusSeconds` because the writer
/// stores both reading and focus listening into `quranSeconds` for total-Quran
/// scoring; subtracting the focus portion isolates pure reading.
enum QuranEngagementReportBuilder {
    private static let logger = Logger(
        subsystem: "com.aydev.deenfirst",
        category: "ActivityReport"
    )

    static func build(
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults,
        now: Date = Date()
    ) -> QuranEngagementReport {
        guard let defaults else {
            logger.error("App Group defaults unavailable — returning empty engagement report")
            return .empty
        }

        // Absent timestamp = nothing has been written yet → "No data yet"
        guard defaults.string(forKey: AppGroupConstants.dataLastUpdatedAtKey) != nil else {
            return .empty
        }

        let dayKey = DashboardDateKeys.dayKey(for: now)
        let totalQuranSeconds = defaults.integer(forKey: AppGroupConstants.quranSecondsKey(dayKey))
        let focusSeconds = defaults.integer(forKey: AppGroupConstants.focusSecondsKey(dayKey))
        let readingSeconds = max(0, totalQuranSeconds - focusSeconds)

        let metrics = QuranEngagementReport.Metrics(
            readingSeconds: readingSeconds,
            focusListeningSeconds: focusSeconds,
            focusSessionCount: defaults.integer(forKey: AppGroupConstants.focusSessionsKey(dayKey)),
            recitationsPassed: defaults.integer(forKey: AppGroupConstants.recitationsPassedKey(dayKey)),
            recitationAttempts: defaults.integer(forKey: AppGroupConstants.recitationsAttemptsKey(dayKey)),
            streakDays: defaults.integer(forKey: AppGroupConstants.streakCurrentKey)
        )

        return QuranEngagementReport(metrics: metrics)
    }
}
