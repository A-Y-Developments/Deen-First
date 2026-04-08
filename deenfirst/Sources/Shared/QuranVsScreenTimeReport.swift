import Foundation
import os

/// Configuration model produced by `QuranVsScreenTimeReportScene.makeConfiguration`
/// and consumed by `QuranVsScreenTimeSectionView`.
///
/// Pairs today's Quran engagement seconds (from the App Group, written by
/// `DashboardDataWriter`) with today's total screen-time seconds (aggregated
/// from `DeviceActivityResults` by the scene). The view renders the two as
/// side-by-side bars to make the contrast visually obvious.
struct QuranVsScreenTimeReport {
    let quranSeconds: Int
    let screenTimeSeconds: Int

    /// True when neither side has any usage to render — view shows an empty
    /// state instead of two zero-height bars.
    var isEmpty: Bool {
        quranSeconds <= 0 && screenTimeSeconds <= 0
    }

    static let empty = QuranVsScreenTimeReport(quranSeconds: 0, screenTimeSeconds: 0)
}

/// Builds a `QuranVsScreenTimeReport` for the current day. Pure aside from the
/// App Group read; the screen-time total is supplied by the caller after it has
/// drained the `DeviceActivityResults` stream.
enum QuranVsScreenTimeReportBuilder {
    private static let logger = Logger(
        subsystem: "com.aydev.deenfirst",
        category: "ActivityReport"
    )

    static func build(
        totalScreenTimeSeconds: Int,
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults,
        now: Date = Date()
    ) -> QuranVsScreenTimeReport {
        guard let defaults else {
            logger.error("App Group defaults unavailable — returning empty Quran vs Screen Time report")
            return .empty
        }

        let dayKey = DashboardDateKeys.dayKey(for: now)
        let quranSeconds = defaults.integer(forKey: AppGroupConstants.quranSecondsKey(dayKey))

        return QuranVsScreenTimeReport(
            quranSeconds: max(0, quranSeconds),
            screenTimeSeconds: max(0, totalScreenTimeSeconds)
        )
    }
}
