import Foundation
import FamilyControls

// MARK: - Time of Day Config (Downtime)

struct TimeOfDayConfig: Codable {
    let id: UUID?
    let name: String
    let startTime: DateComponents
    let endTime: DateComponents
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]

    var isCurrentlyInBlockingPeriod: Bool {
        // First check if today is an active day
        let todayName = DayHelper.getCurrentDayName()
        guard daysActive.isEmpty || daysActive.contains(todayName) else {
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

    init(
        id: UUID? = nil,
        name: String,
        startTime: DateComponents,
        endTime: DateComponents,
        daysActive: Set<String> = [],
        unblockAllowedAfterLimit: Int = 0,
        durationOptions: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysActive = daysActive.isEmpty ? Set(DayHelper.allDayNames) : daysActive
        self.unblockAllowedAfterLimit = unblockAllowedAfterLimit
        self.durationOptions = durationOptions.isEmpty ? [5, 10, 15] : durationOptions
    }
}

// MARK: - All Day Config

struct AllDayConfig: Codable {
    let id: UUID?
    let name: String
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]

    var shouldBlockToday: Bool {
        let todayName = DayHelper.getCurrentDayName()
        return daysActive.isEmpty || daysActive.contains(todayName)
    }

    init(
        id: UUID? = nil,
        name: String,
        daysActive: Set<String> = [],
        unblockAllowedAfterLimit: Int = 0,
        durationOptions: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.daysActive = daysActive.isEmpty ? Set(DayHelper.allDayNames) : daysActive
        self.unblockAllowedAfterLimit = unblockAllowedAfterLimit
        self.durationOptions = durationOptions.isEmpty ? [5, 10, 15] : durationOptions
    }
}
