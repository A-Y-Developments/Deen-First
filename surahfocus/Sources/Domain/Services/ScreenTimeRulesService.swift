import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

protocol ScreenTimeRulesService {
    func requestAuthorization() async throws

    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws
    func deleteAppLimit(id: UUID) async throws

    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws
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

// MARK: - Implementation

final class ScreenTimeRulesServiceImpl: ScreenTimeRulesService {
    let repository: ScreenTimeRulesRepository
    let deviceActivityManager: DeviceActivityManager
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

    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {
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

        var appLimits: [ActivityToken] = []
        appLimits += selection.applicationTokens.map {
            ActivityToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            ActivityToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        let schedule = DeviceActivityScheduleHelper.createDailySchedule()
        let events = ScreenTimeEvents.createEvents(
            limitSeconds: config.limitSeconds,
            ruleId: ruleId,
            selection: appLimits
        )

        let name = DeviceActivityName("daily_\(ruleId.uuidString)")

        // FIX: Start monitoring BEFORE saving to repository.
        // Previously the rule was saved first — if startMonitoring threw, the rule would
        // exist in the repository with no active monitoring behind it (phantom rule).
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)

        // Only persist after monitoring successfully started
        repository.setAppLimitRule(rule)
    }

    func deleteAppLimit(id: UUID) async throws {
        let name = DeviceActivityName("daily_\(id.uuidString)")

        // FIX: stopMonitoring error is no longer silently swallowed via try?
        // If stopping fails, we propagate the error so the caller knows the rule is still active.
        try await deviceActivityManager.stopMonitoring(names: [name])

        ScreenTimeEvents.removeRuleTokens(ruleId: id)

        // FIX: Clean up triggered state for this rule.
        // Without this, the ID lingers in triggeredRuleIds and reapplyActiveShields would
        // continue trying to restore shields for a rule that no longer exists.
        ScreenTimeEvents.removeTriggeredRuleId(ruleId: id)

        repository.deleteAppLimitRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - Time Limit (schedule-based blocking)

    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {
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

        var appLimits: [ActivityToken] = []
        appLimits += selection.applicationTokens.map {
            ActivityToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            ActivityToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: config.startTime,
            endTime: config.endTime,
            repeats: true
        )

        // config.startTime and config.endTime are already DateComponents —
        // read hour/minute directly for storage in SharedDefaults.
        let events = ScreenTimeEvents.createTimeLimitEvents(
            for: ruleId,
            selection: appLimits,
            startHour:   config.startTime.hour   ?? 0,
            startMinute: config.startTime.minute ?? 0,
            endHour:     config.endTime.hour     ?? 0,
            endMinute:   config.endTime.minute   ?? 0,
            daysActive:  Array(config.daysActive)
        )
        let name = DeviceActivityName("timeLimit_\(ruleId.uuidString)")

        // FIX: Start monitoring BEFORE saving to repository (same reason as AppLimit above).
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)

        // Only persist after successful start
        repository.setTimeLimitRule(rule)

        // Apply or remove shield based on whether we're currently in the blocking window
        if config.isCurrentlyInBlockingPeriod {
            await deviceActivityManager.applyShield(for: selection)
        }
        // Note: no need to explicitly removeShield here — if we're NOT in the window,
        // this rule simply has no active shield yet, which is correct.
    }

    func deleteTimeLimit(id: UUID) async throws {
        let name = DeviceActivityName("timeLimit_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        ScreenTimeEvents.removeRuleTokens(ruleId: id)

        // TimeLimit rules don't use triggeredRuleIds, but clean up defensively in case
        // we ever add hybrid rule types in future.
        ScreenTimeEvents.removeTriggeredRuleId(ruleId: id)

        repository.deleteTimeLimitRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - Get Rules

    func getAllRules() -> [ScreenTimeRule] { repository.getAllRules() }
    func getAppLimitRules() -> [ScreenTimeRule] { repository.getAppLimitRules() }
    func getTimeLimitRules() -> [ScreenTimeRule] { repository.getTimeLimitRules() }
    func getRule(id: UUID) -> ScreenTimeRule? { repository.getRule(id: id) }

    // MARK: - Shield Management

    func reapplyActiveShields() async {
        await deviceActivityManager.reapplyActiveShields(rules: getAllRules())
    }

    func applySessionShield(for selection: FamilyActivitySelection) async {
        await deviceActivityManager.applyShield(for: selection)
    }

    /// Called when a Focus Session ends.
    ///
    /// FIX: Removed the old two-step pattern:
    ///   1. removeAllShields()   ← created a brief gap with no shields
    ///   2. reapplyActiveShields ← restored rule-based shields
    ///
    /// Now `reapplyActiveShields` computes the full desired state (rules only, since
    /// `isSessionActive` is cleared first) and atomically replaces everything in one call.
    /// This eliminates both the gap AND the bug where AppLimit shields weren't restored.
    func removeSessionShield() async {
        // Mark session as inactive BEFORE reapplying, so reapplyActiveShields doesn't
        // include session tokens in the new shield state.
        AppGroupConstants.sharedDefaults?.set(false, forKey: AppGroupConstants.isSessionActiveKey)

        // Atomic recompute — replaces current state with only rule-based shields
        await reapplyActiveShields()

        print("✅ Session shield removed, rule-based shields reapplied atomically")
    }

    // MARK: - Pause / Delete All

    func pauseAllRules() async {
        let allRules = getAllRules()

        let allNames: [DeviceActivityName] = allRules.map { rule in
            switch rule.type {
            case .appLimit:  return DeviceActivityName("daily_\(rule.id.uuidString)")
            case .timeLimit: return DeviceActivityName("timeLimit_\(rule.id.uuidString)")
            }
        }

        if !allNames.isEmpty {
            // FIX: Log the error instead of silently swallowing it.
            // If monitoring fails to stop, shields may re-trigger unexpectedly.
            do {
                try await deviceActivityManager.stopMonitoring(names: Set(allNames))
            } catch {
                print("⚠️ [pauseAllRules] Failed to stop monitoring: \(error)")
            }
        }

        await deviceActivityManager.removeShield()
        print("[ScreenTime] All rules paused due to subscription expiry")
    }

    func deleteAllRules() async throws {
        let allRules = getAllRules()

        for rule in allRules {
            switch rule.type {
            case .appLimit:  try await deleteAppLimit(id: rule.id)
            case .timeLimit: try await deleteTimeLimit(id: rule.id)
            }
        }

        // Full clean slate in shared defaults
        let defaults = AppGroupConstants.sharedDefaults
        defaults?.removeObject(forKey: AppGroupConstants.tokenMappingKey)
        defaults?.removeObject(forKey: AppGroupConstants.categoryTokensKey)
        defaults?.removeObject(forKey: AppGroupConstants.ruleTokensKey)

        // FIX: Also clear triggered state on full delete
        ScreenTimeEvents.clearAllTriggeredRuleIds()

        defaults?.synchronize()
        print("[ScreenTime] All rules deleted — clean slate")
    }

    // NOTE: temporaryUnblock and reblockIfExpired are implemented in
    // ScreenTimeRulesService+Unblock.swift — do not declare them here.
}