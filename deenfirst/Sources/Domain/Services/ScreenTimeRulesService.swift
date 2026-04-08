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

    // MARK: - Per-Rule Unblock

    /// Temporarily unblocks only the apps belonging to a specific rule.
    /// Each rule maintains its own independent timer and notification.
    func temporaryUnblock(minutes: Int, ruleId: UUID) async

    /// Fallback for the Shield flow (no specific rule context).
    /// Unblocks all currently blocking rules simultaneously.
    func temporaryUnblockAll(minutes: Int) async

    /// Checks if a specific rule's unblock period has expired and re-applies its shields.
    func reblockIfExpired(ruleId: UUID) async

    /// Called on foreground — iterates all rules and re-blocks any whose timer has expired.
    func reblockAllExpired() async

    // MARK: - Emergency Unblock

    func activateEmergencyUnblock() async
    func deactivateEmergencyUnblock() async
    func reblockEmergencyIfExpired() async
    var isEmergencyUnblockActive: Bool { get }
    func emergencyUnblockQuotaRemaining() -> Int
}

// MARK: - Implementation

final class ScreenTimeRulesServiceImpl: ScreenTimeRulesService {
    let repository: ScreenTimeRulesRepository
    let deviceActivityManager: DeviceActivityManager
    let notificationSchedulingService: NotificationSchedulingService
    private let authCenter = AuthorizationCenter.shared

    init(
        repository: ScreenTimeRulesRepository,
        deviceActivityManager: DeviceActivityManager,
        notificationSchedulingService: NotificationSchedulingService
    ) {
        self.repository = repository
        self.deviceActivityManager = deviceActivityManager
        self.notificationSchedulingService = notificationSchedulingService
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
            durationOptions: config.durationOptions,
            isHardMode: config.isHardMode,
            isLockEditingEnabled: config.isLockEditingEnabled
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
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)
        repository.setAppLimitRule(rule)
    }

    func deleteAppLimit(id: UUID) async throws {
        let name = DeviceActivityName("daily_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        ScreenTimeEvents.removeRuleTokens(ruleId: id)
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
            durationOptions: config.durationOptions,
            isHardMode: config.isHardMode,
            isLockEditingEnabled: config.isLockEditingEnabled
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
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)
        repository.setTimeLimitRule(rule)
        notificationSchedulingService.scheduleTimeLimitWarning(for: rule)

        if config.isCurrentlyInBlockingPeriod {
            await deviceActivityManager.applyShield(for: selection)
        }
    }

    func deleteTimeLimit(id: UUID) async throws {
        let name = DeviceActivityName("timeLimit_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        ScreenTimeEvents.removeRuleTokens(ruleId: id)
        ScreenTimeEvents.removeTriggeredRuleId(ruleId: id)
        repository.deleteTimeLimitRule(id: id)
        notificationSchedulingService.cancelTimeLimitWarning(for: id)
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

    func removeSessionShield() async {
        AppGroupConstants.sharedDefaults?.set(false, forKey: AppGroupConstants.isSessionActiveKey)
        await reapplyActiveShields()
        print("✅ Session shield removed, rule-based shields reapplied atomically")
    }

    // MARK: - Pause / Delete All

    func pauseAllRules() async {
        let allRules = getAllRules()
        let timeLimitRuleIds = allRules
            .filter { $0.type == .timeLimit }
            .map(\.id)

        let allNames: [DeviceActivityName] = allRules.map { rule in
            switch rule.type {
            case .appLimit:  return DeviceActivityName("daily_\(rule.id.uuidString)")
            case .timeLimit: return DeviceActivityName("timeLimit_\(rule.id.uuidString)")
            }
        }

        if !allNames.isEmpty {
            do {
                try await deviceActivityManager.stopMonitoring(names: Set(allNames))
            } catch {
                print("⚠️ [pauseAllRules] Failed to stop monitoring: \(error)")
            }
        }

        await deviceActivityManager.removeShield()

        for ruleId in timeLimitRuleIds {
            notificationSchedulingService.cancelTimeLimitWarning(for: ruleId)
        }
        await notificationSchedulingService.cancelMotivationalNotifications()

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

        let defaults = AppGroupConstants.sharedDefaults
        defaults?.removeObject(forKey: AppGroupConstants.tokenMappingKey)
        defaults?.removeObject(forKey: AppGroupConstants.categoryTokensKey)
        defaults?.removeObject(forKey: AppGroupConstants.ruleTokensKey)
        ScreenTimeEvents.clearAllTriggeredRuleIds()
        defaults?.synchronize()
        print("[ScreenTime] All rules deleted — clean slate")
    }

    // NOTE: temporaryUnblock, temporaryUnblockAll, reblockIfExpired, reblockAllExpired
    // are implemented in ScreenTimeRulesService+Unblock.swift
}
