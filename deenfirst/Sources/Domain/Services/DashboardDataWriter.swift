import Foundation

/// Writes daily/weekly Quran engagement metrics to the shared App Group container
/// so the `DeenFirstActivityReport` extension can render the Deen Score dashboard.
///
/// All counter writes are **additive** (accumulate across the day/week) except
/// `updateStreak` which sets values directly. Every write also stamps
/// `dataLastUpdatedAtKey` for staleness checks in the extension.
protocol DashboardDataWriter {
    func recordFocusSession(duration: TimeInterval)
    func recordQuranReading(duration: TimeInterval)
    func recordRecitationPassed()
    func recordRecitationAttempt()
    func recordEmergencyUnblock()
    func updateStreak(current: Int, longest: Int)
    /// Safety sync — call on every app foreground to ensure streak + timestamp
    /// are in the shared container even if no other event fired recently.
    func flush()
}

final class DashboardDataWriterImpl: DashboardDataWriter {
    private let defaults: UserDefaults?
    private let now: () -> Date

    init(
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.now = now
    }

    // MARK: - Recording API

    func recordFocusSession(duration: TimeInterval) {
        guard duration > 0 else { return }
        let date = currentDateString()
        let seconds = Int(duration.rounded())
        addInt(key: AppGroupConstants.focusSessionsKey(date), by: 1)
        addInt(key: AppGroupConstants.focusSecondsKey(date), by: seconds)
        addInt(key: AppGroupConstants.quranSecondsKey(date), by: seconds)
        stampUpdatedAt()
    }

    func recordQuranReading(duration: TimeInterval) {
        guard duration > 0 else { return }
        addInt(
            key: AppGroupConstants.quranSecondsKey(currentDateString()),
            by: Int(duration.rounded())
        )
        stampUpdatedAt()
    }

    func recordRecitationPassed() {
        addInt(key: AppGroupConstants.recitationsPassedKey(currentDateString()), by: 1)
        stampUpdatedAt()
    }

    func recordRecitationAttempt() {
        addInt(key: AppGroupConstants.recitationsAttemptsKey(currentDateString()), by: 1)
        stampUpdatedAt()
    }

    func recordEmergencyUnblock() {
        addInt(key: AppGroupConstants.emergencyUnblocksKey(currentWeekString()), by: 1)
        stampUpdatedAt()
    }

    func updateStreak(current: Int, longest: Int) {
        defaults?.set(current, forKey: AppGroupConstants.streakCurrentKey)
        defaults?.set(longest, forKey: AppGroupConstants.streakLongestKey)
        stampUpdatedAt()
    }

    func flush() {
        // Re-stamp the last-updated timestamp so the extension's staleness check
        // always sees a fresh foreground. Streak values are preserved as-is.
        stampUpdatedAt()
    }

    // MARK: - Helpers

    private func addInt(key: String, by delta: Int) {
        guard let defaults else { return }
        let current = defaults.integer(forKey: key)
        defaults.set(current + delta, forKey: key)
    }

    private func stampUpdatedAt() {
        defaults?.set(
            Self.iso8601Formatter.string(from: now()),
            forKey: AppGroupConstants.dataLastUpdatedAtKey
        )
    }

    private func currentDateString() -> String {
        DashboardDateKeys.dayKey(for: now())
    }

    private func currentWeekString() -> String {
        DashboardDateKeys.weekKey(for: now())
    }

    // MARK: - Formatters (reused; DateFormatter is expensive to construct)

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
