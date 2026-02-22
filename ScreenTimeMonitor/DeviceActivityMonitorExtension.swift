import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

private enum AppGroupConstants {
    static let suiteName = "group.com.aydev.surahfocus"
    static let tokenMappingKey = "tokenMapping"
    static let categoryTokensKey = "categoryTokens"
    static let ruleTokensKey = "ruleTokens"
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    // MARK: - Interval Lifecycle

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        if activity.rawValue.hasPrefix("daily_") {
            store.clearAllSettings()
            print("✅ Reset limits for new day: \(activity.rawValue)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity.rawValue.hasPrefix("daily_") {
            store.clearAllSettings()
            print("✅ App limit shields cleared at interval end: \(activity.rawValue)")
        }
    }

    // MARK: - Threshold Reached

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name, activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        print("🚦 THRESHOLD REACHED: \(event.rawValue)")
        applyShieldForEvent(event)
    }

    // MARK: - Shield Application

    private func applyShieldForEvent(_ event: DeviceActivityEvent.Name) {
        let raw = event.rawValue

        // Extract ruleId from event name
        let ruleIdString: String
        if raw.hasPrefix("limitReached_") {
            ruleIdString = raw.replacingOccurrences(of: "limitReached_", with: "")
        } else if raw.hasPrefix("timeLimit_") {
            ruleIdString = raw.replacingOccurrences(of: "timeLimit_", with: "")
        } else {
            print("❌ Unknown event prefix: \(raw)")
            return
        }

        guard UUID(uuidString: ruleIdString) != nil else {
            print("❌ Invalid ruleId: \(ruleIdString)")
            return
        }

        // Load all tokens for this rule
        let (appTokens, categoryTokens) = loadRuleTokens(ruleIdString: ruleIdString)

        guard !appTokens.isEmpty || !categoryTokens.isEmpty else {
            print("❌ No tokens found for rule: \(ruleIdString)")
            return
        }

        // Shield all apps in this rule
        if !appTokens.isEmpty {
            let existing = store.shield.applications ?? []
            store.shield.applications = existing.union(appTokens)
            print("✅ Shielded \(appTokens.count) apps for rule: \(ruleIdString)")
        }

        if !categoryTokens.isEmpty {
            switch store.shield.applicationCategories {
            case .specific(let existing, let except):
                store.shield.applicationCategories = .specific(
                    existing.union(categoryTokens), except: except)
            case .all:
                store.shield.applicationCategories = .all()
            default:
                store.shield.applicationCategories = .specific(categoryTokens, except: [])
            }
            print("✅ Shielded \(categoryTokens.count) categories for rule: \(ruleIdString)")
        }
    }

    // MARK: - Token Loading

    private func loadRuleTokens(
        ruleIdString: String
    ) -> (Set<ApplicationToken>, Set<ActivityCategoryToken>) {
        guard let defaults = sharedDefaults,
            let allRules = defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey),
            let ruleData = allRules[ruleIdString] as? [String: Any]
        else {
            return ([], [])
        }

        var appTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        if let appDataList = ruleData["apps"] as? [Data] {
            for data in appDataList {
                if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                    appTokens.insert(token)
                }
            }
        }

        if let categoryDataList = ruleData["categories"] as? [Data] {
            for data in categoryDataList {
                if let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                    categoryTokens.insert(token)
                }
            }
        }

        return (appTokens, categoryTokens)
    }
}
