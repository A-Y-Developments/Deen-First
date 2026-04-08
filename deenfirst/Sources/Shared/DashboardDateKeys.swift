import Foundation

/// Shared date-key formatters used by both `DashboardDataWriter` (main app) and
/// `DeenFirstActivityReport` (extension). Keeping a single source prevents
/// writer/reader key drift — if the format changes here, both sides update.
enum DashboardDateKeys {
    /// `yyyy-MM-dd` in the device's local time zone using the ISO-8601 calendar.
    /// Matches `AppGroupConstants.quranSecondsKey(_:)` and siblings.
    static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// `YYYY-'W'ww` — ISO week-numbering year + week number (e.g. `2026-W14`).
    /// Matches `AppGroupConstants.emergencyUnblocksKey(_:)`.
    static func weekKey(for date: Date) -> String {
        weekFormatter.string(from: date)
    }

    // MARK: - Formatters (reused; DateFormatter is expensive to construct)

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let weekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        // Capital YYYY = ISO week-numbering year (pairs with ww)
        f.dateFormat = "YYYY-'W'ww"
        return f
    }()
}
