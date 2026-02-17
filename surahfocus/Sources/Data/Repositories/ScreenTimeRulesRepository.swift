import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

// MARK: - Screen Time Rules Repository Protocol

protocol ScreenTimeRulesRepository {
    func getTimeLimitRules() -> [ScreenTimeRule]
    func getTimeOfDayRules() -> [ScreenTimeRule]
    func getAllDayRules() -> [ScreenTimeRule]
    func getAllRules() -> [ScreenTimeRule]

    func setTimeLimitRule(_ rule: ScreenTimeRule)
    func setTimeOfDayRule(_ rule: ScreenTimeRule)
    func setAllDayRule(_ rule: ScreenTimeRule)

    func deleteTimeLimitRule(id: UUID)
    func deleteTimeOfDayRule(id: UUID)
    func deleteAllDayRule(id: UUID)

    func getRule(id: UUID) -> ScreenTimeRule?

    func clearAllRules()
}

// MARK: - UserDefaults Keys

private enum UserDefaultsKeys {
    static let timeLimitRules = "timeLimitRules"
    static let timeOfDayRules = "timeOfDayRules"
    static let allDayRules = "allDayRules"
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

    func getTimeLimitRules() -> [ScreenTimeRule] {
        loadRules(forKey: UserDefaultsKeys.timeLimitRules)
    }

    func getTimeOfDayRules() -> [ScreenTimeRule] {
        loadRules(forKey: UserDefaultsKeys.timeOfDayRules)
    }

    func getAllDayRules() -> [ScreenTimeRule] {
        loadRules(forKey: UserDefaultsKeys.allDayRules)
    }

    func getAllRules() -> [ScreenTimeRule] {
        getTimeLimitRules() + getTimeOfDayRules() + getAllDayRules()
    }

    func getRule(id: UUID) -> ScreenTimeRule? {
        getAllRules().first { $0.id == id }
    }

    // MARK: - Set Rules

    func setTimeLimitRule(_ rule: ScreenTimeRule) {
        var rules = getTimeLimitRules()
        addOrUpdateRule(&rules, rule: rule)
        saveRules(rules, forKey: UserDefaultsKeys.timeLimitRules)
    }

    func setTimeOfDayRule(_ rule: ScreenTimeRule) {
        var rules = getTimeOfDayRules()
        addOrUpdateRule(&rules, rule: rule)
        saveRules(rules, forKey: UserDefaultsKeys.timeOfDayRules)
    }

    func setAllDayRule(_ rule: ScreenTimeRule) {
        var rules = getAllDayRules()
        addOrUpdateRule(&rules, rule: rule)
        saveRules(rules, forKey: UserDefaultsKeys.allDayRules)
    }

    // MARK: - Delete Rules

    func deleteTimeLimitRule(id: UUID) {
        var rules = getTimeLimitRules()
        rules.removeAll { $0.id == id }
        saveRules(rules, forKey: UserDefaultsKeys.timeLimitRules)
    }

    func deleteTimeOfDayRule(id: UUID) {
        var rules = getTimeOfDayRules()
        rules.removeAll { $0.id == id }
        saveRules(rules, forKey: UserDefaultsKeys.timeOfDayRules)
    }

    func deleteAllDayRule(id: UUID) {
        var rules = getAllDayRules()
        rules.removeAll { $0.id == id }
        saveRules(rules, forKey: UserDefaultsKeys.allDayRules)
    }

    func clearAllRules() {
        userDefaults?.removeObject(forKey: UserDefaultsKeys.timeLimitRules)
        userDefaults?.removeObject(forKey: UserDefaultsKeys.timeOfDayRules)
        userDefaults?.removeObject(forKey: UserDefaultsKeys.allDayRules)
    }

    // MARK: - Private Helpers

    private func loadRules(forKey key: String) -> [ScreenTimeRule] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: key),
              let rules = try? JSONDecoder().decode([ScreenTimeRule].self, from: data) else {
            return []
        }
        return rules
    }

    private func saveRules(_ rules: [ScreenTimeRule], forKey key: String) {
        guard let userDefaults = userDefaults,
              let data = try? JSONEncoder().encode(rules) else {
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
