import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

// MARK: - Screen Time Rules Repository Protocol

protocol ScreenTimeRulesRepository {
    func getAppLimitRules() -> [ScreenTimeRule]
    func getTimeLimitRules() -> [ScreenTimeRule]
    func getAllRules() -> [ScreenTimeRule]

    func setAppLimitRule(_ rule: ScreenTimeRule)
    func setTimeLimitRule(_ rule: ScreenTimeRule)

    func deleteAppLimitRule(id: UUID)
    func deleteTimeLimitRule(id: UUID)

    func getRule(id: UUID) -> ScreenTimeRule?
    func clearAllRules()
}

// MARK: - UserDefaults Keys

private enum UserDefaultsKeys {
    static let appLimitRules = "appLimitRules"
    static let timeLimitRules = "timeLimitRules"
    static let tokenMapping = "tokenMapping"
    static let categoryTokens = "categoryTokens"
}

// MARK: - Screen Time Rules Repository Implementation

final class ScreenTimeRulesRepositoryImpl: ScreenTimeRulesRepository {
    private let userDefaults: UserDefaults?

    init(suiteName: String = AppGroupConstants.suiteName) {
        self.userDefaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Get Rules

    func getAppLimitRules() -> [ScreenTimeRule] {
        loadRules(forKey: UserDefaultsKeys.appLimitRules)
    }

    func getTimeLimitRules() -> [ScreenTimeRule] {
        loadRules(forKey: UserDefaultsKeys.timeLimitRules)
    }

    func getAllRules() -> [ScreenTimeRule] {
        getAppLimitRules() + getTimeLimitRules()
    }

    func getRule(id: UUID) -> ScreenTimeRule? {
        getAllRules().first { $0.id == id }
    }

    // MARK: - Set Rules

    func setAppLimitRule(_ rule: ScreenTimeRule) {
        var rules = getAppLimitRules()
        addOrUpdateRule(&rules, rule: rule)
        saveRules(rules, forKey: UserDefaultsKeys.appLimitRules)
    }

    func setTimeLimitRule(_ rule: ScreenTimeRule) {
        var rules = getTimeLimitRules()
        addOrUpdateRule(&rules, rule: rule)
        saveRules(rules, forKey: UserDefaultsKeys.timeLimitRules)
    }

    // MARK: - Delete Rules

    func deleteAppLimitRule(id: UUID) {
        var rules = getAppLimitRules()
        rules.removeAll { $0.id == id }
        saveRules(rules, forKey: UserDefaultsKeys.appLimitRules)
    }

    func deleteTimeLimitRule(id: UUID) {
        var rules = getTimeLimitRules()
        rules.removeAll { $0.id == id }
        saveRules(rules, forKey: UserDefaultsKeys.timeLimitRules)
    }

    func clearAllRules() {
        userDefaults?.removeObject(forKey: UserDefaultsKeys.appLimitRules)
        userDefaults?.removeObject(forKey: UserDefaultsKeys.timeLimitRules)
    }

    // MARK: - Private Helpers

    private func loadRules(forKey key: String) -> [ScreenTimeRule] {
        guard let userDefaults = userDefaults,
            let data = userDefaults.data(forKey: key),
            let rules = try? JSONDecoder().decode([ScreenTimeRule].self, from: data)
        else {
            return []
        }
        return rules
    }

    private func saveRules(_ rules: [ScreenTimeRule], forKey key: String) {
        guard let userDefaults = userDefaults,
            let data = try? JSONEncoder().encode(rules)
        else {
            return
        }
        userDefaults.set(data, forKey: key)
    }

    private func addOrUpdateRule(_ rules: inout [ScreenTimeRule], rule: ScreenTimeRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }
}