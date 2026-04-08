import FamilyControls
import Foundation

struct TimeLimitConfig: Codable {
    let id: UUID?
    let name: String
    let startTime: DateComponents
    let endTime: DateComponents
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]
    let isHardMode: Bool
    let isLockEditingEnabled: Bool

    var isCurrentlyInBlockingPeriod: Bool {
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
        durationOptions: [Int] = [],
        isHardMode: Bool = false,
        isLockEditingEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysActive = daysActive.isEmpty ? Set(DayHelper.allDayNames) : daysActive
        self.unblockAllowedAfterLimit = unblockAllowedAfterLimit
        self.durationOptions = durationOptions.isEmpty ? [5, 10, 15] : durationOptions
        self.isHardMode = isHardMode
        self.isLockEditingEnabled = isHardMode ? true : isLockEditingEnabled
    }
}
