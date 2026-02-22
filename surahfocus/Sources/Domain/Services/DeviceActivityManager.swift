import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

protocol DeviceActivityManager {
    func startMonitoring(
        name: DeviceActivityName, schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]) async throws
    func stopMonitoring(names: Set<DeviceActivityName>) async throws
    func applyShield(for selection: FamilyActivitySelection) async
    func removeShield() async
    func removeShield(for selection: FamilyActivitySelection) async
    func reapplyActiveShields(rules: [ScreenTimeRule]) async
}

@MainActor
final class DeviceActivityManagerImpl: DeviceActivityManager {
    private let activityCenter = DeviceActivityCenter()
    private let managedSettings: ManagedSettingsWrapper

    init(managedSettings: ManagedSettingsWrapper) {
        self.managedSettings = managedSettings
    }

    func startMonitoring(
        name: DeviceActivityName, schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws {
        print("🚀 Starting monitoring for: \(name.rawValue) with \(events.count) events")
        for (eventName, event) in events {
            print("  Event: \(eventName.rawValue) threshold: \(event.threshold.second ?? 0)s")
        }
        if !events.isEmpty {
            try activityCenter.startMonitoring(name, during: schedule, events: events)
        } else {
            try activityCenter.startMonitoring(name, during: schedule)
        }
        print("✅ Monitoring started successfully")
    }

    func stopMonitoring(names: Set<DeviceActivityName>) async throws {
        try activityCenter.stopMonitoring(Array(names))
    }

    func applyShield(for selection: FamilyActivitySelection) async {
        managedSettings.applyShields(
            applicationTokens: selection.applicationTokens,
            categoryTokens: selection.categoryTokens
        )
    }

    func removeShield() async {
        managedSettings.removeAllShields()
    }

    func removeShield(for selection: FamilyActivitySelection) async {
        let currentApps = managedSettings.store.shield.applications ?? []
        let newApps = currentApps.subtracting(selection.applicationTokens)
        managedSettings.store.shield.applications = newApps.isEmpty ? [] : newApps
    }

    func reapplyActiveShields(rules: [ScreenTimeRule]) async {
        var applicationTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        let todayName = DayHelper.getCurrentDayName()
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        func isWithin(start: DateComponents?, end: DateComponents?) -> Bool {
            guard let s = start, let e = end else { return false }
            let sMin = (s.hour ?? 0) * 60 + (s.minute ?? 0)
            let eMin = (e.hour ?? 0) * 60 + (e.minute ?? 0)
            if sMin <= eMin {
                return currentMinutes >= sMin && currentMinutes <= eMin
            } else {
                return currentMinutes >= sMin || currentMinutes <= eMin
            }
        }

        for rule in rules {
            guard rule.type == .timeLimit else { continue }

            let days = rule.daysActive ?? []
            let isActiveDay = days.isEmpty || days.contains(todayName)

            if isActiveDay && isWithin(start: rule.getStartTimeComponents(), end: rule.getEndTimeComponents()) {
                let selection = rule.getFamilyActivitySelection()
                applicationTokens.formUnion(selection.applicationTokens)
                categoryTokens.formUnion(selection.categoryTokens)
            }
        }

        if !applicationTokens.isEmpty || !categoryTokens.isEmpty {
            managedSettings.applyShields(applicationTokens: applicationTokens, categoryTokens: categoryTokens)
        } else {
            managedSettings.removeAllShields()
        }
    }
}
