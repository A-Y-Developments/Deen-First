import Foundation
import ManagedSettings
import FamilyControls

// MARK: - Rule Type

enum RuleType: String, Codable, Hashable {
    case timeLimit    // App Limit - time-based quota
    case timeOfDay    // Downtime - schedule-based blocking
    case allDay       // All Day Limit - day-based blocking
}

// MARK: - Codable Date Components

struct CodableDateComponents: Codable, Hashable {
    let hour: Int?
    let minute: Int?
    let second: Int?

    init(from components: DateComponents) {
        self.hour = components.hour
        self.minute = components.minute
        self.second = components.second
    }

    func toDateComponents() -> DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = second
        return components
    }

    init(hour: Int? = nil, minute: Int? = nil, second: Int? = nil) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }
}

// MARK: - Screen Time Rule

struct ScreenTimeRule: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var applicationTokenData: [Data]  // Encoded ApplicationTokens
    var categoryTokenData: [Data]     // Encoded ActivityCategoryTokens
    var type: RuleType

    // Optional fields based on type
    var limitSeconds: Int?                      // For timeLimit
    var startTime: CodableDateComponents?       // For timeOfDay
    var endTime: CodableDateComponents?         // For timeOfDay
    var daysActiveArray: [String]?              // For all types (stored as array)
    var unblockAllowedAfterLimit: Int?
    var durationOptions: [Int]?

    var createdAt: Date

    // Helper property for backwards compatibility
    var daysActive: Set<String>? {
        get { daysActiveArray.map { Set($0) } }
        set { daysActiveArray = newValue.map { Array($0) } }
    }

    init(
        id: UUID = UUID(),
        name: String,
        selection: FamilyActivitySelection,
        type: RuleType,
        limitSeconds: Int? = nil,
        startTime: DateComponents? = nil,
        endTime: DateComponents? = nil,
        daysActive: Set<String>? = nil,
        unblockAllowedAfterLimit: Int? = nil,
        durationOptions: [Int]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.applicationTokenData = selection.applicationTokens.compactMap {
            try? JSONEncoder().encode($0)
        }
        self.categoryTokenData = selection.categoryTokens.compactMap {
            try? JSONEncoder().encode($0)
        }
        self.type = type
        self.limitSeconds = limitSeconds
        self.startTime = startTime.map { CodableDateComponents(from: $0) }
        self.endTime = endTime.map { CodableDateComponents(from: $0) }
        self.daysActiveArray = daysActive.map { Array($0) }
        self.unblockAllowedAfterLimit = unblockAllowedAfterLimit
        self.durationOptions = durationOptions
        self.createdAt = createdAt
    }

    // Helper to get FamilyActivitySelection
    func getFamilyActivitySelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()

        // Decode application tokens
        let applicationTokens = applicationTokenData.compactMap { data -> ApplicationToken? in
            try? JSONDecoder().decode(ApplicationToken.self, from: data)
        }
        selection.applicationTokens = Set(applicationTokens)

        // Decode category tokens
        let categoryTokens = categoryTokenData.compactMap { data -> ActivityCategoryToken? in
            try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
        }
        selection.categoryTokens = Set(categoryTokens)

        return selection
    }

    // Helper to get DateComponents
    func getStartTimeComponents() -> DateComponents? {
        startTime?.toDateComponents()
    }

    func getEndTimeComponents() -> DateComponents? {
        endTime?.toDateComponents()
    }
}

// MARK: - Screen Time Rule Extensions

extension ScreenTimeRule {
    /// Check if rule should be active today
    var isTodayActive: Bool {
        guard let daysActive = daysActive else { return true }
        if daysActive.isEmpty { return true }
        return daysActive.contains(DayHelper.getCurrentDayName())
    }

    /// Check if currently in blocking period (for timeOfDay)
    var isCurrentlyInBlockingPeriod: Bool {
        guard type == .timeOfDay,
              let startTime = getStartTimeComponents(),
              let endTime = getEndTimeComponents(),
              isTodayActive else {
            return false
        }

        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentHour = now.hour ?? 0
        let currentMinute = now.minute ?? 0
        let startHour = startTime.hour ?? 0
        let startMinute = startTime.minute ?? 0
        let endHour = endTime.hour ?? 23
        let endMinute = endTime.minute ?? 59

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }

    /// Check if should block today (for allDay)
    var shouldBlockToday: Bool {
        guard type == .allDay else { return false }
        return isTodayActive
    }

    /// Get display name for limit (for timeLimit type)
    var limitDisplayName: String? {
        guard let limitSeconds = limitSeconds else { return nil }
        let hours = limitSeconds / 3600
        let mins = (limitSeconds % 3600) / 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m/day"
        } else if hours > 0 {
            return "\(hours)h/day"
        } else {
            return "\(mins)m/day"
        }
    }

    /// Get display time range (for timeOfDay type)
    var timeRangeDisplay: String? {
        guard let startTime = getStartTimeComponents(),
              let endTime = getEndTimeComponents() else { return nil }

        let startHour = startTime.hour ?? 0
        let startMin = startTime.minute ?? 0
        let endHour = endTime.hour ?? 23
        let endMin = endTime.minute ?? 59

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let startDate = Calendar.current.date(from: DateComponents(hour: startHour, minute: startMin))
        let endDate = Calendar.current.date(from: DateComponents(hour: endHour, minute: endMin))

        guard let start = startDate, let end = endDate else { return nil }

        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    /// Get days display text
    var daysDisplayText: String {
        guard let daysActive = daysActive, !daysActive.isEmpty else {
            return "Everyday"
        }

        let allDays: Set<String> = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let weekdays: Set<String> = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        let weekend: Set<String> = ["Saturday", "Sunday"]

        if daysActive == allDays {
            return "Everyday"
        }
        if daysActive == weekdays {
            return "Weekdays"
        }
        if daysActive == weekend {
            return "Weekends"
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let fullDayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        let sortedDays = daysActive.sorted().compactMap { fullDay -> String? in
            guard let index = fullDayNames.firstIndex(of: fullDay) else { return nil }
            return dayNames[index]
        }

        return sortedDays.joined(separator: ", ")
    }
}
