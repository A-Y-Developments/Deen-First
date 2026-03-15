import Foundation
import DeviceActivity

// MARK: - Device Activity Schedule Helper

enum DeviceActivityScheduleHelper {

    /// Creates a daily schedule that resets at midnight.
    ///
    /// FIX: Changed intervalEnd from `hour: 23, minute: 59` (ends at 23:59:00, leaving a
    /// 60-second gap before the next day starts at 00:00:00) to `hour: 23, minute: 59, second: 59`.
    /// This minimizes the unshielded gap to ~1 second — the smallest the DeviceActivity API allows.
    static func createDailySchedule() -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59), // ← FIX: was minute: 59
            repeats: true
        )
    }

    /// Creates a schedule with a custom time window (used by Time Limit / schedule-based rules).
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

    /// Creates a full-day schedule (00:00:00 - 23:59:59).
    static func createFullDaySchedule(repeats: Bool = true) -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: repeats
        )
    }
}