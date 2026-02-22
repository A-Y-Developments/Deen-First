import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings


protocol ScreenTimeRulesService {
    func requestAuthorization() async throws

    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig)
        async throws
    func deleteAppLimit(id: UUID) async throws

    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig)
        async throws
    func deleteTimeLimit(id: UUID) async throws

    func getAllRules() -> [ScreenTimeRule]
    func getAppLimitRules() -> [ScreenTimeRule]
    func getTimeLimitRules() -> [ScreenTimeRule]
    func getRule(id: UUID) -> ScreenTimeRule?

    func reapplyActiveShields() async
    func applySessionShield(for selection: FamilyActivitySelection) async
    func removeSessionShield() async

    func pauseAllRules() async
    func deleteAllRules() async throws

    func temporaryUnblock(minutes: Int) async
    func reblockIfExpired() async
}

// MARK: - Screen Time Use Case Implementation

final class ScreenTimeRulesServiceImpl: ScreenTimeRulesService {
    private let repository: ScreenTimeRulesRepository
    private let deviceActivityManager: DeviceActivityManager
    private let authCenter = AuthorizationCenter.shared

    init(repository: ScreenTimeRulesRepository, deviceActivityManager: DeviceActivityManager) {
        self.repository = repository
        self.deviceActivityManager = deviceActivityManager
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await authCenter.requestAuthorization(for: .individual)
    }

    // MARK: - App Limit (time-based quota)

    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig)
        async throws
    {
        let ruleId = config.id ?? UUID()
        let rule = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .appLimit,
            limitSeconds: config.limitSeconds,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )

        repository.setAppLimitRule(rule)

        var appLimits: [ActivityToken] = []
        appLimits += selection.applicationTokens.map {
            ActivityToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            ActivityToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        let schedule = DeviceActivityScheduleHelper.createDailySchedule()
        let timeLimit = TimeLimit.fromMinutes(config.limitSeconds / 60)
        let events = ScreenTimeEvents.createEvents(
            for: timeLimit,
            ruleId: ruleId,
            selection: appLimits
        )

        let name = DeviceActivityName("daily_\(ruleId.uuidString)")
        try await deviceActivityManager.startMonitoring(
            name: name, schedule: schedule, events: events)
    }

    func deleteAppLimit(id: UUID) async throws {
        let name = DeviceActivityName("daily_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        ScreenTimeEvents.removeRuleTokens(ruleId: id)
        repository.deleteAppLimitRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - Time Limit / Time of Day (schedule-based blocking)

    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig)
        async throws
    {
        let ruleId = config.id ?? UUID()
        let rule = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeLimit,
            startTime: config.startTime,
            endTime: config.endTime,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )

        repository.setTimeLimitRule(rule)

        var appLimits: [ActivityToken] = []
        appLimits += selection.applicationTokens.map {
            ActivityToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            ActivityToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        if config.isCurrentlyInBlockingPeriod {
            await deviceActivityManager.applyShield(for: selection)
        } else {
            await deviceActivityManager.removeShield(for: selection)
        }

        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: config.startTime,
            endTime: config.endTime,
            repeats: true
        )
        let events = ScreenTimeEvents.createTimeLimitEvents(for: ruleId, selection: appLimits)

        let name = DeviceActivityName("timeLimit_\(ruleId.uuidString)")
        try await deviceActivityManager.startMonitoring(
            name: name, schedule: schedule, events: events)
    }

    func deleteTimeLimit(id: UUID) async throws {
        let name = DeviceActivityName("timeLimit_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        ScreenTimeEvents.removeRuleTokens(ruleId: id)  // ← cleanup
        repository.deleteTimeLimitRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - Get Rules

    func getAllRules() -> [ScreenTimeRule] {
        repository.getAllRules()
    }

    func getAppLimitRules() -> [ScreenTimeRule] {
        repository.getAppLimitRules()
    }

    func getTimeLimitRules() -> [ScreenTimeRule] {
        repository.getTimeLimitRules()
    }

    func getRule(id: UUID) -> ScreenTimeRule? {
        repository.getRule(id: id)
    }

    // MARK: - Shield Management

    func reapplyActiveShields() async {
        await deviceActivityManager.reapplyActiveShields(rules: getAllRules())
    }

    func applySessionShield(for selection: FamilyActivitySelection) async {
        await deviceActivityManager.applyShield(for: selection)
    }

    func removeSessionShield() async {
        await deviceActivityManager.removeShield()
        await reapplyActiveShields()
    }

    func pauseAllRules() async {
        let allRules = getAllRules()

        let allNames: [DeviceActivityName] = allRules.map { rule in
            switch rule.type {
            case .appLimit:
                return DeviceActivityName("daily_\(rule.id.uuidString)")
            case .timeLimit:
                return DeviceActivityName("timeLimit_\(rule.id.uuidString)")
            }
        }

        if !allNames.isEmpty {
            try? await deviceActivityManager.stopMonitoring(names: Set(allNames))
        }

        await deviceActivityManager.removeShield()
        print("[ScreenTime] All rules paused due to subscription expiry")
    }

    func deleteAllRules() async throws {
        let allRules = getAllRules()

        for rule in allRules {
            switch rule.type {
            case .appLimit:
                try await deleteAppLimit(id: rule.id)
            case .timeLimit:
                try await deleteTimeLimit(id: rule.id)
            }
        }

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.removeObject(forKey: AppGroupConstants.tokenMappingKey)
        defaults?.removeObject(forKey: AppGroupConstants.categoryTokensKey)
        defaults?.removeObject(forKey: AppGroupConstants.ruleTokensKey)
        defaults?.synchronize()

        print("[ScreenTime] All rules deleted — clean slate")
    }
}
