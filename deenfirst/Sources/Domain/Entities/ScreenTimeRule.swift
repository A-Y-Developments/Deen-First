import FamilyControls
import Foundation
import ManagedSettings

// MARK: - Rule Type

enum RuleType: String, Codable, Hashable {
    case appLimit
    case timeLimit 
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
    var applicationTokenData: [Data]
    var categoryTokenData: [Data]  
    var type: RuleType

    var limitSeconds: Int?
    var startTime: CodableDateComponents?
    var endTime: CodableDateComponents?
    var daysActiveArray: [String]?
    var unblockAllowedAfterLimit: Int?
    var durationOptions: [Int]?

    var isHardMode: Bool = false
    var isLockEditingEnabled: Bool = false

    var createdAt: Date

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
        isHardMode: Bool = false,
        isLockEditingEnabled: Bool = false,
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
        self.isHardMode = isHardMode
        self.isLockEditingEnabled = isLockEditingEnabled
        self.createdAt = createdAt
    }

    // Custom Decodable init: tolerates rules persisted before isHardMode /
    // isLockEditingEnabled were added by defaulting both to false. Encodable
    // synthesis is preserved.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.applicationTokenData = try container.decode([Data].self, forKey: .applicationTokenData)
        self.categoryTokenData = try container.decode([Data].self, forKey: .categoryTokenData)
        self.type = try container.decode(RuleType.self, forKey: .type)
        self.limitSeconds = try container.decodeIfPresent(Int.self, forKey: .limitSeconds)
        self.startTime = try container.decodeIfPresent(CodableDateComponents.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(CodableDateComponents.self, forKey: .endTime)
        self.daysActiveArray = try container.decodeIfPresent([String].self, forKey: .daysActiveArray)
        self.unblockAllowedAfterLimit = try container.decodeIfPresent(Int.self, forKey: .unblockAllowedAfterLimit)
        self.durationOptions = try container.decodeIfPresent([Int].self, forKey: .durationOptions)
        self.isHardMode = try container.decodeIfPresent(Bool.self, forKey: .isHardMode) ?? false
        self.isLockEditingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isLockEditingEnabled) ?? false
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func getFamilyActivitySelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()

        let applicationTokens = applicationTokenData.compactMap { data -> ApplicationToken? in
            try? JSONDecoder().decode(ApplicationToken.self, from: data)
        }
        selection.applicationTokens = Set(applicationTokens)

        let categoryTokens = categoryTokenData.compactMap { data -> ActivityCategoryToken? in
            try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
        }
        selection.categoryTokens = Set(categoryTokens)

        return selection
    }

    func getStartTimeComponents() -> DateComponents? {
        startTime?.toDateComponents()
    }

    func getEndTimeComponents() -> DateComponents? {
        endTime?.toDateComponents()
    }
}

// MARK: - Screen Time Rule Extensions

extension ScreenTimeRule {
    var isTodayActive: Bool {
        guard let daysActive = daysActive else { return true }
        if daysActive.isEmpty { return true }
        return daysActive.contains(DayHelper.getCurrentDayName())
    }

    var isCurrentlyInBlockingPeriod: Bool {
        guard type == .timeLimit,
            let startTime = getStartTimeComponents(),
            let endTime = getEndTimeComponents(),
            isTodayActive
        else {
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

    var timeRangeDisplay: String? {
        guard let startTime = getStartTimeComponents(),
            let endTime = getEndTimeComponents()
        else { return nil }

        let startHour = startTime.hour ?? 0
        let startMin = startTime.minute ?? 0
        let endHour = endTime.hour ?? 23
        let endMin = endTime.minute ?? 59

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let startDate = Calendar.current.date(
            from: DateComponents(hour: startHour, minute: startMin))
        let endDate = Calendar.current.date(from: DateComponents(hour: endHour, minute: endMin))

        guard let start = startDate, let end = endDate else { return nil }

        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    var daysDisplayText: String {
        guard let daysActive = daysActive, !daysActive.isEmpty else {
            return "Everyday"
        }

        let allDays: Set<String> = [
            "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
        ]
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
        let fullDayNames = [
            "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
        ]

        let sortedDays = daysActive.sorted().compactMap { fullDay -> String? in
            guard let index = fullDayNames.firstIndex(of: fullDay) else { return nil }
            return dayNames[index]
        }

        return sortedDays.joined(separator: ", ")
    }
}
