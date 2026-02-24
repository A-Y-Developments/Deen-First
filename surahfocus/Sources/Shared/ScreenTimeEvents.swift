import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

public enum ScreenTimeEvents {

    // MARK: - Create Events

    /// FIX: Changed `TimeLimit` parameter to `limitSeconds: Int` so this file can live
    /// in the Shared folder and compile in the ScreenTimeMonitor extension target.
    /// `TimeLimit` is a main-app-only type — callers just pass `timeLimit.seconds` instead.
    static func createEvents(
        limitSeconds: Int,
        ruleId: UUID,
        selection: [ActivityToken]
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {

        var appTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        for app in selection {
            if let token = app.applicationToken { appTokens.insert(token) }
            if let token = app.categoryToken { categoryTokens.insert(token) }
        }

        saveRuleTokens(ruleId: ruleId, selection: selection)

        let eventName = DeviceActivityEvent.Name("limitReached_\(ruleId.uuidString)")
        let event = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            webDomains: [],
            threshold: DateComponents(second: limitSeconds)
        )

        return [eventName: event]
    }

    static func createTimeLimitEvents(
        for ruleId: UUID,
        selection: [ActivityToken],
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        daysActive: [String]
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {

        var appTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        for app in selection {
            if let token = app.applicationToken { appTokens.insert(token) }
            if let token = app.categoryToken { categoryTokens.insert(token) }
        }

        // Save tokens + schedule metadata so the extension can restore shields
        // after a temporary unblock expires — without needing the main app process.
        saveRuleTokens(
            ruleId: ruleId,
            selection: selection,
            type: "timeLimit",
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            daysActive: daysActive
        )

        let eventName = DeviceActivityEvent.Name("timeLimit_\(ruleId.uuidString)")
        let event = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            webDomains: [],
            threshold: DateComponents(hour: 0, minute: 0)
        )

        return [eventName: event]
    }

    // MARK: - Rule Token Persistence

    /// Saves app/category tokens for a rule.
    /// AppLimit rules only need tokens — no schedule metadata required.
    static func saveRuleTokens(ruleId: UUID, selection: [ActivityToken]) {
        saveRuleTokens(
            ruleId: ruleId,
            selection: selection,
            type: "appLimit",
            startHour: nil,
            startMinute: nil,
            endHour: nil,
            endMinute: nil,
            daysActive: nil
        )
    }

    /// Full save — used by TimeLimit rules to also persist schedule data.
    /// The DeviceActivityMonitorExtension reads type/startHour/endHour/daysActive
    /// in `reapplyTimeLimitShields()` to restore shields after unblock expiry.
    static func saveRuleTokens(
        ruleId: UUID,
        selection: [ActivityToken],
        type: String,
        startHour: Int?,
        startMinute: Int?,
        endHour: Int?,
        endMinute: Int?,
        daysActive: [String]?
    ) {
        guard let defaults = AppGroupConstants.sharedDefaults else { return }

        var appTokenData: [Data] = []
        var categoryTokenData: [Data] = []

        for app in selection {
            if let token = app.applicationToken,
               let data = try? JSONEncoder().encode(token) {
                appTokenData.append(data)
            }
            if let token = app.categoryToken,
               let data = try? JSONEncoder().encode(token) {
                categoryTokenData.append(data)
            }
        }

        var ruleEntry: [String: Any] = [
            "apps": appTokenData,
            "categories": categoryTokenData,
            "type": type
        ]

        // Only TimeLimit rules need these fields
        if let startHour   { ruleEntry["startHour"]   = startHour   }
        if let startMinute { ruleEntry["startMinute"] = startMinute }
        if let endHour     { ruleEntry["endHour"]     = endHour     }
        if let endMinute   { ruleEntry["endMinute"]   = endMinute   }
        if let daysActive  { ruleEntry["daysActive"]  = daysActive  }

        var allRules = defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey) as? [String: Any] ?? [:]
        allRules[ruleId.uuidString] = ruleEntry
        defaults.set(allRules, forKey: AppGroupConstants.ruleTokensKey)
    }

    /// Removes the token storage for a deleted rule.
    static func removeRuleTokens(ruleId: UUID) {
        guard let defaults = AppGroupConstants.sharedDefaults else { return }
        var allRules = defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey) as? [String: Any] ?? [:]
        allRules.removeValue(forKey: ruleId.uuidString)
        defaults.set(allRules, forKey: AppGroupConstants.ruleTokensKey)
    }

    // MARK: - Triggered Rule ID Tracking
    //
    // When an AppLimit rule reaches its daily threshold, we persist its ID so that
    // `reapplyActiveShields` can restore the shield after a Focus Session ends —
    // even though the DeviceActivityMonitorExtension (which originally applied the shield)
    // runs in a separate process and can't be queried directly.

    /// Records that an AppLimit rule has fired its threshold today.
    /// Called from `DeviceActivityMonitorExtension.eventDidReachThreshold`.
    static func markRuleAsTriggered(ruleId: UUID) {
        guard let defaults = AppGroupConstants.sharedDefaults else { return }
        var triggered = defaults.stringArray(forKey: AppGroupConstants.triggeredRuleIdsKey) ?? []
        let idString = ruleId.uuidString
        if !triggered.contains(idString) {
            triggered.append(idString)
            defaults.set(triggered, forKey: AppGroupConstants.triggeredRuleIdsKey)
        }
    }

    /// Clears the triggered flag for one rule.
    /// Call this on midnight reset (intervalDidStart) and when a rule is deleted.
    static func removeTriggeredRuleId(ruleId: UUID) {
        guard let defaults = AppGroupConstants.sharedDefaults else { return }
        var triggered = defaults.stringArray(forKey: AppGroupConstants.triggeredRuleIdsKey) ?? []
        triggered.removeAll { $0 == ruleId.uuidString }
        defaults.set(triggered, forKey: AppGroupConstants.triggeredRuleIdsKey)
    }

    /// Clears ALL triggered flags.
    /// Use this in `deleteAllRules` for a full clean slate.
    static func clearAllTriggeredRuleIds() {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.triggeredRuleIdsKey)
    }

    /// Returns the set of rule IDs that have been triggered today.
    static func getTriggeredRuleIds() -> Set<String> {
        let arr = AppGroupConstants.sharedDefaults?.stringArray(
            forKey: AppGroupConstants.triggeredRuleIdsKey) ?? []
        return Set(arr)
    }
}

// MARK: - Activity Token

public struct ActivityToken {
    public let id: UUID
    public let applicationToken: ApplicationToken?
    public let categoryToken: ActivityCategoryToken?

    public init(
        id: UUID = UUID(),
        applicationToken: ApplicationToken? = nil,
        categoryToken: ActivityCategoryToken? = nil
    ) {
        self.id = id
        self.applicationToken = applicationToken
        self.categoryToken = categoryToken
    }
}

// MARK: - Screen Time Activity

public enum ScreenTimeActivity {
    public static func dailyMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("daily_\(ruleId.uuidString)")
    }

    public static func timeLimitMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("timeLimit_\(ruleId.uuidString)")
    }
}