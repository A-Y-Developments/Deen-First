import Foundation

// MARK: - Day Helper

enum DayHelper {
    static let allDayNames: [String] = [
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    ]

    static func getCurrentDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    static func mapSelectedDaysToNames(_ selectedDays: Set<Int>) -> Set<String> {
        return Set(selectedDays.compactMap { index in
            guard index >= 0 && index < allDayNames.count else { return nil }
            return allDayNames[index]
        })
    }

    static func getCurrentDayIndex() -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Calendar's weekday starts with Sunday = 1
        return weekday - 1
    }

    // MARK: - Day Active Check

    /// Checks if today should be active based on activeDays array
    /// - Parameter activeDays: Array of day indices (0=Sunday, 1=Monday, etc.)
    /// - Returns: true if today is in activeDays or if activeDays is empty (all days)
    static func isDayActive(activeDays: [Int]) -> Bool {
        // Empty array means all days are active
        if activeDays.isEmpty {
            return true
        }
        return activeDays.contains(getCurrentDayIndex())
    }
}
