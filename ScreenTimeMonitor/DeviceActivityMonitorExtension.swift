import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import os

private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "ScreenTimeMonitor")

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
            logger.info("Reset daily quota for rule: \(ruleId, privacy: .private)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity.rawValue.hasPrefix("daily_") {
            let ruleId = activity.rawValue.replacingOccurrences(of: "daily_", with: "")
            guard UUID(uuidString: ruleId) != nil else { return }

            removeShieldsForRule(ruleId: ruleId)
            logger.info("Removed shields at interval end for rule: \(ruleId, privacy: .private)")

        } else if activity.rawValue.hasPrefix("timeLimit_") {
            let ruleId = activity.rawValue.replacingOccurrences(of: "timeLimit_", with: "")
            guard UUID(uuidString: ruleId) != nil else { return }
            removeShieldsForRule(ruleId: ruleId)
            logger.info("Removed TimeLimit shields at interval end for rule: \(ruleId, privacy: .private)")

        } else if activity.rawValue.hasPrefix(AppGroupConstants.tempUnblockActivityPrefix) {
            let ruleIdString = activity.rawValue.replacingOccurrences(
                of: AppGroupConstants.tempUnblockActivityPrefix,
                with: ""
            )
            handleTempUnblockExpired(ruleId: ruleIdString)
        }
    }

    // MARK: - Threshold Reached

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.info("Threshold reached: \(event.rawValue, privacy: .private)")

        let raw = event.rawValue
        let ruleIdString: String
        if raw.hasPrefix("limitReached_") {
            ruleIdString = raw.replacingOccurrences(of: "limitReached_", with: "")
        } else if raw.hasPrefix("timeLimit_") {
            ruleIdString = raw.replacingOccurrences(of: "timeLimit_", with: "")
        } else { return }

        guard isRuleActiveToday(ruleId: ruleIdString) else {
            logger.notice("Skipping shield — rule not active today: \(ruleIdString, privacy: .private)")
            return
        }

        applyShieldForEvent(event)

        if raw.hasPrefix("limitReached_") {
            if let ruleId = UUID(uuidString: ruleIdString) {
                ScreenTimeEvents.markRuleAsTriggered(ruleId: ruleId)
                logger.info("Marked rule as triggered: \(ruleIdString, privacy: .private)")
            }
        }
    }

    private func isRuleActiveToday(ruleId: String) -> Bool {
        guard let defaults = sharedDefaults,
              let allRules = defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey),
              let ruleData = allRules[ruleId] as? [String: Any]
        else { return true }

        guard let daysActive = ruleData["daysActive"] as? [String], !daysActive.isEmpty else {
            return true
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        return daysActive.contains(formatter.string(from: Date()))
    }

    // MARK: - Temp Unblock Expiry (per-rule)

    private func handleTempUnblockExpired(ruleId: String) {
        logger.info("TempUnblock window expired for rule: \(ruleId, privacy: .private) — re-applying shields")

        // Clear the per-rule expiry key
        guard let uuid = UUID(uuidString: ruleId) else { return }
        sharedDefaults?.removeObject(forKey: AppGroupConstants.unblockExpiryKey(for: uuid))
        sharedDefaults?.synchronize()

        // Re-apply shields for this specific rule only.
        // Check AppLimit first (quota was reached today), then TimeLimit (in active window).
        let triggeredIds = ScreenTimeEvents.getTriggeredRuleIds()
        if triggeredIds.contains(ruleId) {
            // AppLimit rule — re-shield its tokens
            applyShieldsFromStorage(ruleId: ruleId)
            logger.info("TempUnblock AppLimit shields restored for rule: \(ruleId, privacy: .private)")
        } else {
            // TimeLimit rule — only re-shield if currently inside the active window
            reapplyTimeLimitShieldForRule(ruleId: ruleId)
        }
    }

    // MARK: - Re-apply Single TimeLimit Rule

    private func reapplyTimeLimitShieldForRule(ruleId: String) {
        guard let defaults = sharedDefaults,
              let allRules = defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey),
              let ruleData = allRules[ruleId] as? [String: Any],
              let type = ruleData["type"] as? String, type == "timeLimit",
              let startHour = ruleData["startHour"] as? Int,
              let startMinute = ruleData["startMinute"] as? Int,
              let endHour = ruleData["endHour"] as? Int,
              let endMinute = ruleData["endMinute"] as? Int
        else { return }

        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        // Check active days
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        let todayName = formatter.string(from: now)

        if let daysActive = ruleData["daysActive"] as? [String], !daysActive.isEmpty {
            guard daysActive.contains(todayName) else { return }
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

        guard inWindow else {
            logger.info("TempUnblock TimeLimit rule outside its window — no shield needed: \(ruleId, privacy: .private)")
            return
        }

        applyShieldsFromStorage(ruleId: ruleId)
        logger.info("TempUnblock TimeLimit shields restored for rule: \(ruleId, privacy: .private)")
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

        for (ruleId, _) in allRules {
            reapplyTimeLimitShieldForRule(ruleId: ruleId)
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
            logger.error("Unknown event prefix: \(raw, privacy: .public)")
            return
        }

        guard UUID(uuidString: ruleIdString) != nil else {
            logger.error("Invalid ruleId: \(ruleIdString, privacy: .private)")
            return
        }

        let (appTokens, categoryTokens) = loadRuleTokens(ruleIdString: ruleIdString)

        guard !appTokens.isEmpty || !categoryTokens.isEmpty else {
            logger.warning("No tokens found for rule: \(ruleIdString, privacy: .private)")
            return
        }

        if !appTokens.isEmpty {
            let existing = store.shield.applications ?? []
            store.shield.applications = existing.union(appTokens)
            logger.info("Shielded \(appTokens.count) apps for rule: \(ruleIdString, privacy: .private)")
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
            logger.info("Shielded \(categoryTokens.count) categories for rule: \(ruleIdString, privacy: .private)")
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
