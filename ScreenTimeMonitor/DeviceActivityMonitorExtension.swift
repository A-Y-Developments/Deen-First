import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    // MARK: - Interval Lifecycle

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        if activity.rawValue.hasPrefix("daily_") {
            let ruleId = activity.rawValue.replacingOccurrences(of: "daily_", with: "")
            guard let uuid = UUID(uuidString: ruleId) else { return }

            ScreenTimeEvents.removeTriggeredRuleId(ruleId: uuid)
            removeShieldsForRule(ruleId: ruleId)
            print("✅ Reset daily quota for rule: \(ruleId)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity.rawValue.hasPrefix("daily_") {
            let ruleId = activity.rawValue.replacingOccurrences(of: "daily_", with: "")
            guard UUID(uuidString: ruleId) != nil else { return }

            removeShieldsForRule(ruleId: ruleId)
            print("✅ Removed shields at interval end for rule: \(ruleId)")

        } else if activity.rawValue.hasPrefix(AppGroupConstants.tempUnblockActivityPrefix) {
            // The temporary unblock window has expired.
            // This runs in the extension process — fires reliably even if the main app
            // has been backgrounded or killed by the user.
            handleTempUnblockExpired()
        }
    }

    // MARK: - Threshold Reached

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        print("🚦 THRESHOLD REACHED: \(event.rawValue)")

        applyShieldForEvent(event)

        let raw = event.rawValue
        if raw.hasPrefix("limitReached_") {
            let ruleIdString = raw.replacingOccurrences(of: "limitReached_", with: "")
            if let ruleId = UUID(uuidString: ruleIdString) {
                ScreenTimeEvents.markRuleAsTriggered(ruleId: ruleId)
                print("✅ Marked rule as triggered: \(ruleIdString)")
            }
        }
    }

    // MARK: - Temp Unblock Expiry

    private func handleTempUnblockExpired() {
        print("🔒 [TempUnblock] Window expired — re-applying shields")

        // Clear expiry key so isTemporarilyUnblocked returns false in the main app
        sharedDefaults?.removeObject(forKey: AppGroupConstants.unblockExpiryKey)
        sharedDefaults?.synchronize()

        // Re-apply triggered AppLimit rules
        let triggeredIds = ScreenTimeEvents.getTriggeredRuleIds()
        for ruleId in triggeredIds {
            applyShieldsFromStorage(ruleId: ruleId)
        }

        // Re-apply any TimeLimit rules whose window is currently active
        reapplyTimeLimitShields()

        print("✅ [TempUnblock] Shields restored — \(triggeredIds.count) AppLimit rule(s) re-applied")
    }

    private func applyShieldsFromStorage(ruleId: String) {
        let (appTokens, categoryTokens) = loadRuleTokens(ruleIdString: ruleId)

        if !appTokens.isEmpty {
            let existing = store.shield.applications ?? []
            store.shield.applications = existing.union(appTokens)
        }

        if !categoryTokens.isEmpty {
            switch store.shield.applicationCategories {
            case .specific(let existing, let except):
                store.shield.applicationCategories = .specific(
                    existing.union(categoryTokens), except: except)
            case .all:
                break
            default:
                store.shield.applicationCategories = .specific(categoryTokens, except: [])
            }
        }
    }

    private func reapplyTimeLimitShields() {
        guard let defaults = sharedDefaults,
              let allRules = defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey)
        else { return }

        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        let todayName = formatter.string(from: now)

        for (ruleId, ruleData) in allRules {
            guard let ruleDict = ruleData as? [String: Any],
                  let type = ruleDict["type"] as? String, type == "timeLimit",
                  let startHour = ruleDict["startHour"] as? Int,
                  let startMinute = ruleDict["startMinute"] as? Int,
                  let endHour = ruleDict["endHour"] as? Int,
                  let endMinute = ruleDict["endMinute"] as? Int
            else { continue }

            // Check active days
            if let daysActive = ruleDict["daysActive"] as? [String], !daysActive.isEmpty {
                guard daysActive.contains(todayName) else { continue }
            }

            // Check time window (handles overnight wrap)
            let sMin = startHour * 60 + startMinute
            let eMin = endHour * 60 + endMinute
            let inWindow: Bool
            if sMin <= eMin {
                inWindow = currentMinutes >= sMin && currentMinutes <= eMin
            } else {
                inWindow = currentMinutes >= sMin || currentMinutes <= eMin
            }

            guard inWindow else { continue }
            applyShieldsFromStorage(ruleId: ruleId)
        }
    }

    // MARK: - Shield Application

    private func applyShieldForEvent(_ event: DeviceActivityEvent.Name) {
        let raw = event.rawValue

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

        let (appTokens, categoryTokens) = loadRuleTokens(ruleIdString: ruleIdString)

        guard !appTokens.isEmpty || !categoryTokens.isEmpty else {
            print("❌ No tokens found for rule: \(ruleIdString)")
            return
        }

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
                break
            default:
                store.shield.applicationCategories = .specific(categoryTokens, except: [])
            }
            print("✅ Shielded \(categoryTokens.count) categories for rule: \(ruleIdString)")
        }
    }

    // MARK: - Per-Rule Shield Removal

    private func removeShieldsForRule(ruleId: String) {
        let (appTokens, categoryTokens) = loadRuleTokens(ruleIdString: ruleId)

        if !appTokens.isEmpty {
            let existing = store.shield.applications ?? []
            let remaining = existing.subtracting(appTokens)
            store.shield.applications = remaining.isEmpty ? nil : remaining
        }

        if !categoryTokens.isEmpty {
            switch store.shield.applicationCategories {
            case .specific(let existing, let except):
                let remaining = existing.subtracting(categoryTokens)
                store.shield.applicationCategories = remaining.isEmpty
                    ? nil
                    : .specific(remaining, except: except)
            default:
                break
            }
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