import Foundation

struct DowntimeSchedule: Codable {
    let id: UUID
    let userId: UUID
    let appTokens: [Data]  // All selected apps to block
    let isEnabled: Bool
    let prayerSchedules: [PrayerSchedule]

    struct PrayerSchedule: Codable {
        let prayer: PrayerTime
        let startTime: String  // "04:30" format HH:mm
        let endTime: String    // "06:00" format HH:mm
        let isEnabled: Bool

        init(prayer: PrayerTime, startTime: String, endTime: String, isEnabled: Bool = true) {
            self.prayer = prayer
            self.startTime = startTime
            self.endTime = endTime
            self.isEnabled = isEnabled
        }
    }

    enum PrayerTime: String, Codable, CaseIterable {
        case subuh = "subuh"
        case zuhr = "zuhr"
        case asr = "asr"
        case maghrib = "maghrib"
        case isya = "isya"

        var displayName: String {
            switch self {
            case .subuh: return "Subuh (Fajr)"
            case .zuhr: return "Zuhr (Dhuhr)"
            case .asr: return "Asr"
            case .maghrib: return "Maghrib"
            case .isya: return "Isya (Isha)"
            }
        }

        var emoji: String {
            switch self {
            case .subuh: return "🌅"
            case .zuhr: return "☀️"
            case .asr: return "🌤"
            case .maghrib: return "🌅"
            case .isya: return "🌙"
            }
        }

        var defaultTimeRange: (start: String, end: String) {
            // Fixed defaults - can be enhanced with location-based calculation in V2
            switch self {
            case .subuh: return ("04:30", "06:00")
            case .zuhr: return ("12:15", "13:30")
            case .asr: return ("15:45", "17:00")
            case .maghrib: return ("18:15", "19:15")
            case .isya: return ("19:30", "20:45")
            }
        }
    }

    init(userId: UUID, appTokens: [Data], prayerSchedules: [PrayerSchedule], isEnabled: Bool = true) {
        self.id = UUID()
        self.userId = userId
        self.appTokens = appTokens
        self.prayerSchedules = prayerSchedules
        self.isEnabled = isEnabled
    }
}
