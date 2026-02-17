import Foundation
import DeviceActivity

// MARK: - Device Activity Schedule Helper

enum DeviceActivityScheduleHelper {
    /// Creates a daily schedule that resets at midnight
    static func createDailySchedule() -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }

    /// Creates a schedule with custom time window
    static func createCustomSchedule(
        startTime: DateComponents,
        endTime: DateComponents,
        repeats: Bool = true
    ) -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: startTime,
            intervalEnd: endTime,
            repeats: repeats
        )
    }

    /// Creates a full-day schedule (00:00 - 23:59)
    static func createFullDaySchedule(repeats: Bool = true) -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: repeats
        )
    }
}
