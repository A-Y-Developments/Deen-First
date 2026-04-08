import Foundation
import os

/// Configuration model produced by `WeeklyTrendReportScene.makeConfiguration`
/// and consumed by `WeeklyTrendSectionView`.
///
/// Holds 7 day points (oldest first → today last). Each point carries the
/// computed Deen Score plus flags the view uses to style the bar (today is
/// drawn distinctly; missing-data days are zero).
struct WeeklyTrendReport {
    struct DayPoint: Equatable {
        let dayKey: String
        let date: Date
        let score: Int
        let isToday: Bool
        /// False when the day has no Quran activity, no recitation, AND no
        /// screen time recorded — view should still render a 0 bar without
        /// crashing.
        let hasData: Bool
    }

    let days: [DayPoint]

    static let empty = WeeklyTrendReport(days: [])
}

/// Builds a 7-day Deen Score trend by combining per-day App Group counters
/// with a per-day screen-time map supplied by the scene (which buckets
/// `DeviceActivityResults` segments by their day-of-start).
///
/// Streak is global, not stored historically — current streak is applied to
/// every day in the trend so the score still reflects the user's standing
/// rather than under-counting past days.
enum WeeklyTrendReportBuilder {
    /// Default daily screen-time budget; matches `DeenScoreReportBuilder`.
    /// TODO(DF-34): replace with user-configured daily limit from App Group.
    private static let defaultDailyLimitSeconds = 2 * 60 * 60

    private static let logger = Logger(
        subsystem: "com.aydev.deenfirst",
        category: "ActivityReport"
    )

    static func build(
        screenTimeSecondsByDay: [String: Int],
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WeeklyTrendReport {
        guard let defaults else {
            logger.error("App Group defaults unavailable — returning empty weekly trend")
            return .empty
        }

        let todayStart = calendar.startOfDay(for: now)
        let todayKey = DashboardDateKeys.dayKey(for: now)
        let streak = defaults.integer(forKey: AppGroupConstants.streakCurrentKey)

        var points: [WeeklyTrendReport.DayPoint] = []
        // Iterate oldest → newest so the chart reads left-to-right.
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: todayStart) else {
                continue
            }
            let dayKey = DashboardDateKeys.dayKey(for: date)
            let weekKey = DashboardDateKeys.weekKey(for: date)

            let quranSeconds = defaults.integer(forKey: AppGroupConstants.quranSecondsKey(dayKey))
            let focusSessions = defaults.integer(forKey: AppGroupConstants.focusSessionsKey(dayKey))
            let recitationsPassed = defaults.integer(forKey: AppGroupConstants.recitationsPassedKey(dayKey))
            let recitationAttempts = defaults.integer(forKey: AppGroupConstants.recitationsAttemptsKey(dayKey))
            let emergencyUnblocks = defaults.integer(forKey: AppGroupConstants.emergencyUnblocksKey(weekKey))
            let screenSeconds = max(0, screenTimeSecondsByDay[dayKey] ?? 0)

            let hasData = quranSeconds > 0
                || focusSessions > 0
                || recitationsPassed > 0
                || recitationAttempts > 0
                || screenSeconds > 0

            let score: Int
            if hasData {
                let input = DeenScoreInput(
                    quranSeconds: quranSeconds,
                    focusSessions: focusSessions,
                    recitationsPassed: recitationsPassed,
                    streakDays: streak,
                    screenTimeOverLimitSeconds: max(0, screenSeconds - defaultDailyLimitSeconds),
                    emergencyUnblocksThisWeek: emergencyUnblocks
                )
                score = calculateDeenScore(input)
            } else {
                // Acceptance criterion: missing data days show 0 (not crash).
                score = 0
            }

            points.append(
                WeeklyTrendReport.DayPoint(
                    dayKey: dayKey,
                    date: date,
                    score: score,
                    isToday: dayKey == todayKey,
                    hasData: hasData
                )
            )
        }

        return WeeklyTrendReport(days: points)
    }
}

/// Pure helpers used by `WeeklyTrendSectionView` for axis labels.
enum WeeklyTrendFormatter {
    /// Single-letter weekday label, e.g. "M", "T", "W". Sunday-first per the
    /// device's calendar so it stays locale-aware without pulling Foundation's
    /// full weekday symbols (which would also work but are longer).
    static func weekdayLabel(for date: Date, calendar: Calendar = .current) -> String {
        let symbols = calendar.veryShortWeekdaySymbols
        let weekday = calendar.component(.weekday, from: date) // 1...7
        let index = max(0, min(symbols.count - 1, weekday - 1))
        return symbols[index]
    }
}
