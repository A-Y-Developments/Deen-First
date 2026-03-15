import Foundation

// MARK: - Time of Day Helper

enum TimeLimitHelper {
    static func isMorning() -> Bool {
        hour >= 6 && hour < 12
    }

    static func isAfternoon() -> Bool {
        hour >= 12 && hour < 17
    }

    static func isEvening() -> Bool {
        hour >= 17 && hour < 21
    }

    static func isNight() -> Bool {
        hour >= 21 || hour < 6
    }

    static var hour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    static func secondsUntilMidnight() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return 0 }
        guard let midnight = calendar.startOfDay(for: tomorrow) as Date? else { return 0 }
        return midnight.timeIntervalSince(now)
    }

    static func startOfToday() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    static func endOfToday() -> Date? {
        let calendar = Calendar.current
        let today = startOfToday()
        return calendar.date(byAdding: .day, value: 1, to: today)
    }
}
