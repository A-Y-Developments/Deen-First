import Foundation
import os

/// Configuration model produced by `DeenScoreReportScene.makeConfiguration`
/// and consumed by `DeenScoreSectionView`.
///
/// `score == nil` signals that required data was not yet available and the
/// view should render its loading fallback instead of a ring.
struct DeenScoreReport {
    let score: Int?
    let message: String

    static let loading = DeenScoreReport(score: nil, message: "Score loading…")
}

/// Reads the day's Deen inputs from the App Group and computes a Deen Score.
/// Returns `.loading` if the shared defaults are unavailable.
///
/// `totalScreenTimeSeconds` comes from `DeviceActivityResults` — passed in by
/// the scene after aggregating the data stream.
enum DeenScoreReportBuilder {
    private static let logger = Logger(
        subsystem: "com.aydev.deenfirst",
        category: "ActivityReport"
    )

    /// Default daily screen-time budget used when the user hasn't set one yet.
    /// Seconds beyond this count as "over limit" for penalty calculation.
    /// TODO(DF-34): replace with user-configured daily limit from App Group.
    private static let defaultDailyLimitSeconds = 2 * 60 * 60

    static func build(
        totalScreenTimeSeconds: Int,
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults,
        now: Date = Date()
    ) -> DeenScoreReport {
        guard let defaults else {
            logger.error("App Group defaults unavailable — returning loading state")
            return .loading
        }

        let dayKey = DashboardDateKeys.dayKey(for: now)
        let weekKey = DashboardDateKeys.weekKey(for: now)

        let quranSeconds = defaults.integer(forKey: AppGroupConstants.quranSecondsKey(dayKey))
        let focusSessions = defaults.integer(forKey: AppGroupConstants.focusSessionsKey(dayKey))
        let recitationsPassed = defaults.integer(forKey: AppGroupConstants.recitationsPassedKey(dayKey))
        let streakDays = defaults.integer(forKey: AppGroupConstants.streakCurrentKey)
        let emergencyUnblocks = defaults.integer(forKey: AppGroupConstants.emergencyUnblocksKey(weekKey))

        let overLimit = max(0, totalScreenTimeSeconds - defaultDailyLimitSeconds)

        let input = DeenScoreInput(
            quranSeconds: quranSeconds,
            focusSessions: focusSessions,
            recitationsPassed: recitationsPassed,
            streakDays: streakDays,
            screenTimeOverLimitSeconds: overLimit,
            emergencyUnblocksThisWeek: emergencyUnblocks
        )

        let score = calculateDeenScore(input)
        return DeenScoreReport(score: score, message: DeenScoreMessage.message(for: score))
    }

}
