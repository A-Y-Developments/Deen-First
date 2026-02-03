import SwiftUI

@MainActor
final class DowntimeSetupViewModel: ObservableObject {
    @Published var selectedPrayers: Set<DowntimeSchedule.PrayerTime> = []
    @Published var prayerTimes: [DowntimeSchedule.PrayerTime: TimeRange] = [:]
    @Published var selectedApps: [Data] = []  // Encoded ApplicationTokens

    func loadApps(_ appTokens: [Data]) {
        selectedApps = appTokens
    }

    struct TimeRange {
        let start: String  // "HH:mm"
        let end: String
    }

    func togglePrayer(_ prayer: DowntimeSchedule.PrayerTime) {
        if selectedPrayers.contains(prayer) {
            selectedPrayers.remove(prayer)
        } else {
            selectedPrayers.insert(prayer)
            let defaultRange = prayer.defaultTimeRange
            prayerTimes[prayer] = TimeRange(start: defaultRange.start, end: defaultRange.end)
        }
    }

    func isSelected(_ prayer: DowntimeSchedule.PrayerTime) -> Bool {
        selectedPrayers.contains(prayer)
    }

    func getTimeRange(for prayer: DowntimeSchedule.PrayerTime) -> (start: String, end: String) {
        if let range = prayerTimes[prayer] {
            return (range.start, range.end)
        }
        return prayer.defaultTimeRange
    }

    func save() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }

        // Save if downtime is enabled
        sharedDefaults.set(!selectedPrayers.isEmpty, forKey: "downtimeEnabled")

        // Save selected prayer names
        let prayerNames = selectedPrayers.map { $0.rawValue }
        sharedDefaults.set(prayerNames, forKey: "selectedPrayers")

        // Save each prayer's time range
        for (prayer, range) in prayerTimes {
            let key = "prayer_\(prayer.rawValue)_time"
            sharedDefaults.set([range.start, range.end], forKey: key)
        }
    }

    func skip() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }
        sharedDefaults.set(false, forKey: "downtimeEnabled")
    }
}
