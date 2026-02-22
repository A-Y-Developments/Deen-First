import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

public enum ScreenTimeEvents {

    static func createEvents(
        for limit: TimeLimit,
        ruleId: UUID,
        selection: [ActivityToken]
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {

        var appTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        for app in selection {
            if let token = app.applicationToken {
                appTokens.insert(token)
            }
            if let token = app.categoryToken {
                categoryTokens.insert(token)
            }
        }

        saveRuleTokens(ruleId: ruleId, selection: selection)

        let eventName = DeviceActivityEvent.Name("limitReached_\(ruleId.uuidString)")
        let event = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            webDomains: [],
            threshold: DateComponents(second: limit.seconds)
        )

        return [eventName: event]
    }

    static func createTimeLimitEvents(
        for ruleId: UUID,
        selection: [ActivityToken]
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {

        var appTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        for app in selection {
            if let token = app.applicationToken {
                appTokens.insert(token)
            }
            if let token = app.categoryToken {
                categoryTokens.insert(token)
            }
        }

        saveRuleTokens(ruleId: ruleId, selection: selection)

        let eventName = DeviceActivityEvent.Name("timeLimit_\(ruleId.uuidString)")
        let event = DeviceActivityEvent(
            applications: appTokens,
            categories: categoryTokens,
            webDomains: [],
            threshold: DateComponents(hour: 0, minute: 0)
        )

        return [eventName: event]
    }

    static func saveRuleTokens(ruleId: UUID, selection: [ActivityToken]) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }

        var appTokenData: [Data] = []
        var categoryTokenData: [Data] = []

        for app in selection {
            if let token = app.applicationToken,
                let data = try? JSONEncoder().encode(token)
            {
                appTokenData.append(data)
            }
            if let token = app.categoryToken,
                let data = try? JSONEncoder().encode(token)
            {
                categoryTokenData.append(data)
            }
        }

        var allRules =
            defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey) as? [String: Any] ?? [:]
        allRules[ruleId.uuidString] = [
            "apps": appTokenData,
            "categories": categoryTokenData,
        ]
        defaults.set(allRules, forKey: AppGroupConstants.ruleTokensKey)
    }

    static func removeRuleTokens(ruleId: UUID) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }
        var allRules =
            defaults.dictionary(forKey: AppGroupConstants.ruleTokensKey) as? [String: Any] ?? [:]
        allRules.removeValue(forKey: ruleId.uuidString)
        defaults.set(allRules, forKey: AppGroupConstants.ruleTokensKey)
    }
}

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

public enum ScreenTimeActivity {
    public static func dailyMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("daily_\(ruleId.uuidString)")
    }

    public static func timeLimitMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("timeLimit_\(ruleId.uuidString)")
    }
}
