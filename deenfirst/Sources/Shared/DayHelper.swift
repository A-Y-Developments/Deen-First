import Foundation

// MARK: - Day Helper

enum DayHelper {
    static let allDayNames: [String] = [
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    ]

    /// Returns the current day name in English, regardless of device locale.
    /// ⚠️ FIX: Added `locale = Locale(identifier: "en_US")` — without this, devices
    /// set to Indonesian (or any non-English locale) return localized day names
    /// (e.g., "Senin" instead of "Monday"), breaking all day-active checks.
    static func getCurrentDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US") // ← CRITICAL FIX
        return formatter.string(from: Date())
    }

    static func getCurrentDayIndex() -> Int {
        // Calendar's weekday: Sunday = 1, so subtract 1 for 0-based index
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday - 1
    }

    static func mapSelectedDaysToNames(_ selectedDays: Set<Int>) -> Set<String> {
        return Set(selectedDays.compactMap { index in
            guard index >= 0 && index < allDayNames.count else { return nil }
            return allDayNames[index]
        })
    }

    // MARK: - Unified Active Day Check

    /// Single source of truth for "is today an active day for this rule?"
    ///
    /// Use this everywhere instead of duplicating day-check logic across
    /// `ScreenTimeRule`, `TimeLimitConfig`, and `DeviceActivityManagerImpl`.
    ///
    /// - Parameter daysActive: A Set of English day name strings (e.g., "Monday").
    ///   Pass `nil` or an empty set to mean "every day".
    static func isActiveToday(daysActive: Set<String>?) -> Bool {
        guard let days = daysActive, !days.isEmpty else {
            return true // nil or empty = active every day
        }
        return days.contains(getCurrentDayName())
    }

    /// Convenience overload accepting an optional array (from `daysActiveArray` on ScreenTimeRule).
    static func isActiveToday(daysActiveArray: [String]?) -> Bool {
        guard let arr = daysActiveArray, !arr.isEmpty else { return true }
        return arr.contains(getCurrentDayName())
    }

    /// Legacy support — checks by day index array.
    static func isDayActive(activeDays: [Int]) -> Bool {
        if activeDays.isEmpty { return true }
        return activeDays.contains(getCurrentDayIndex())
    }
}