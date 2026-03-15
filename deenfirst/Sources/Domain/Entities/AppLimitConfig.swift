import Foundation

// MARK: - Time Limit Config (App Limit)

struct AppLimitConfig: Codable {
    let id: UUID?
    let name: String
    let timeLimit: TimeLimit
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]

    var limitSeconds: Int {
        timeLimit.seconds
    }

    init(
        id: UUID? = nil,
        name: String,
        timeLimit: TimeLimit,
        daysActive: Set<String> = [],
        unblockAllowedAfterLimit: Int = 0,
        durationOptions: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.timeLimit = timeLimit
        self.daysActive = daysActive.isEmpty ? Set(DayHelper.allDayNames) : daysActive
        self.unblockAllowedAfterLimit = unblockAllowedAfterLimit
        self.durationOptions = durationOptions.isEmpty ? [15, 30, 60] : durationOptions
    }
}

// MARK: - Time Limit Enum

enum TimeLimit: Equatable, Hashable, Codable {
    case oneMin
    case fifteenMin
    case thirtyMin
    case fortyFiveMin
    case oneHour
    case twoHours
    case threeHours
    case fourHours
    case custom(Int)

    var displayName: String {
        switch self {
        case .oneMin: return "1 min"
        case .fifteenMin: return "15 min"
        case .thirtyMin: return "30 min"
        case .fortyFiveMin: return "45 min"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .threeHours: return "3 hours"
        case .fourHours: return "4 hours"
        case .custom(let value):
            if value < 60 {
                return "\(value) min"
            }
            let hours = value / 60
            let mins = value % 60
            if mins == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
            return "\(hours)h \(mins)m"
        }
    }

    var seconds: Int {
        switch self {
        case .oneMin: return 1 * 60
        case .fifteenMin: return 15 * 60
        case .thirtyMin: return 30 * 60
        case .fortyFiveMin: return 45 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .threeHours: return 3 * 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .custom(let value): return value
        }
    }

    var minutes: Int {
        return seconds / 60
    }

    static var allCases: [TimeLimit] {
        return [
            .oneMin, .fifteenMin, .thirtyMin, .fortyFiveMin, .oneHour, .twoHours, .threeHours,
            .fourHours,
        ]
    }
}

// MARK: - Time Limit Collection

extension TimeLimit {
    static var standardOptions: [TimeLimit] {
        return [
            .oneMin, .fifteenMin, .thirtyMin, .fortyFiveMin, .oneHour, .twoHours, .threeHours,
            .fourHours,
        ]
    }

    // Create TimeLimit from minutes (for backward compatibility)
    static func fromMinutes(_ minutes: Int) -> TimeLimit {
        switch minutes {
        case 1: return .oneMin
        case 15: return .fifteenMin
        case 30: return .thirtyMin
        case 45: return .fortyFiveMin
        case 60: return .oneHour
        case 90: return .custom(90)
        case 120: return .twoHours
        case 180: return .threeHours
        case 240: return .fourHours
        default: return .custom(minutes * 60)
        }
    }
}
