import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

// MARK: - App Group Constants

enum AppGroupConstants {
    static let suiteName = "group.com.aydev.surahfocus"
    static let tokenMappingKey = "tokenMapping"
    static let categoryTokensKey = "categoryTokens"
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let managedSettingsStore = ManagedSettingsStore()
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    // MARK: - Interval Lifecycle

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // For time-limit schedules we name them as "daily_<ruleId>"
        if activity.rawValue.hasPrefix("daily_") {
            let store = ManagedSettingsStore()
            store.clearAllSettings()
            print("Reset limits for new day interval: \(activity.rawValue)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let store = ManagedSettingsStore()
        store.clearAllSettings()
    }

    // MARK: - Event Thresholds

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("🚦 THRESHOLD REACHED: \(event.rawValue) for activity: \(activity.rawValue)")

        // User exceeded their time limit - apply shield
        applyShieldForEvent(event)
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)

        // User is approaching their limit - could trigger notification
        // (Not accessible from extension, but main app could listen for this)
    }

    // MARK: - Interval Warnings

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Interval about to start
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Interval about to end
    }

    // MARK: - Private Helpers

    private func applyShieldForEvent(_ event: DeviceActivityEvent.Name) {
        guard let sharedDefaults = sharedDefaults else { return }
        let raw = event.rawValue

        print("🛡️ Applying shield for event: \(raw)")

        // Helper closures
        func applyApp(by uuidString: String) {
            print("🔍 Looking up app token: \(uuidString)")
            guard
                let dict = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data],
                let data = dict[uuidString],
                let token = try? JSONDecoder().decode(ApplicationToken.self, from: data)
            else {
                print("❌ Failed to find app token: \(uuidString)")
                return
            }
            print("✅ Found app token, applying shield")
            managedSettingsStore.shield.applications = (managedSettingsStore.shield.applications ?? []).union([token])
        }

        func applyCategory(by uuidString: String) {
            guard
                let dict = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data],
                let data = dict[uuidString],
                let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
            else { return }

            if let existing = managedSettingsStore.shield.applicationCategories {
                switch existing {
                case .all:
                    managedSettingsStore.shield.applicationCategories = .all()
                case .specific(let categories, let exceptApps):
                    var newCategories = categories
                    newCategories.insert(token)
                    managedSettingsStore.shield.applicationCategories = .specific(newCategories, except: exceptApps)
                case .none:
                    break
                @unknown default:
                    break
                }
            } else {
                managedSettingsStore.shield.applicationCategories = .specific([token], except: [])
            }
        }

        // Time limit events (App Limit)
        if raw.hasPrefix("limitReached_app_") {
            applyApp(by: raw.replacingOccurrences(of: "limitReached_app_", with: ""))
            return
        }
        if raw.hasPrefix("limitReached_category_") {
            applyCategory(by: raw.replacingOccurrences(of: "limitReached_category_", with: ""))
            return
        }

        // Time-of-day events (Prayer Times/Downtime)
        if raw.hasPrefix("timeOfDay_app_") {
            applyApp(by: raw.replacingOccurrences(of: "timeOfDay_app_", with: ""))
            return
        }
        if raw.hasPrefix("timeOfDay_category_") {
            applyCategory(by: raw.replacingOccurrences(of: "timeOfDay_category_", with: ""))
            return
        }

        // All-day events
        if raw.hasPrefix("allDay_app_") {
            applyApp(by: raw.replacingOccurrences(of: "allDay_app_", with: ""))
            return
        }
        if raw.hasPrefix("allDay_category_") {
            applyCategory(by: raw.replacingOccurrences(of: "allDay_category_", with: ""))
            return
        }
    }
}
