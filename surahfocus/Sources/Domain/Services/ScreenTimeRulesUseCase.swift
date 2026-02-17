import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

// MARK: - Screen Time Use Case Protocol

protocol ScreenTimeRulesUseCase {
    func requestAuthorization() async throws

    // App Limit (Time Limit)
    func setTimeLimit(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws
    func updateTimeLimit(id: UUID, for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws
    func deleteTimeLimit(id: UUID) async throws

    // Downtime (Time of Day)
    func setTimeOfDayBlock(for selection: FamilyActivitySelection, config: TimeOfDayConfig) async throws
    func updateTimeOfDayBlock(id: UUID, for selection: FamilyActivitySelection, config: TimeOfDayConfig) async throws
    func deleteTimeOfDay(id: UUID) async throws

    // All Day Limit
    func setAllDayBlock(for selection: FamilyActivitySelection, config: AllDayConfig) async throws
    func updateAllDayBlock(id: UUID, for selection: FamilyActivitySelection, config: AllDayConfig) async throws
    func deleteAllDay(id: UUID) async throws

    // Get Rules
    func getAllRules() -> [ScreenTimeRule]
    func getTimeLimitRules() -> [ScreenTimeRule]
    func getTimeOfDayRules() -> [ScreenTimeRule]
    func getAllDayRules() -> [ScreenTimeRule]
    func getRule(id: UUID) -> ScreenTimeRule?

    // Shield Management
    func reapplyActiveShields() async

    // Session Shield Management
    func applySessionShield(for selection: FamilyActivitySelection) async
    func removeSessionShield() async
}

// MARK: - Screen Time Use Case Implementation

final class ScreenTimeRulesUseCaseImpl: ScreenTimeRulesUseCase {
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

    // MARK: - App Limit (Time Limit)

    func setTimeLimit(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {
        let ruleId = config.id ?? UUID()
        let rule = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeLimit,
            limitSeconds: config.limitSeconds,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )

        repository.setTimeLimitRule(rule)

        // Build AppLimit array for events
        var appLimits: [AppLimitToken] = []
        appLimits += selection.applicationTokens.map {
            AppLimitToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        // Create daily schedule (resets at midnight)
        let schedule = DeviceActivityScheduleHelper.createDailySchedule()

        // Create events with time threshold
        let timeLimit = TimeLimit.fromMinutes(config.limitSeconds / 60)
        let events = ScreenTimeEvents.createEvents(for: timeLimit, selection: appLimits)

        // Start monitoring
        let name = DeviceActivityName("daily_\(ruleId.uuidString)")
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)

        // Do NOT apply shield immediately for time limits
        // Shield will be applied by extension when threshold is reached
    }

    func deleteTimeLimit(id: UUID) async throws {
        let name = DeviceActivityName("daily_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        repository.deleteTimeLimitRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - Downtime (Time of Day)

    func setTimeOfDayBlock(for selection: FamilyActivitySelection, config: TimeOfDayConfig) async throws {
        let ruleId = config.id ?? UUID()
        let rule = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeOfDay,
            startTime: config.startTime,
            endTime: config.endTime,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )

        repository.setTimeOfDayRule(rule)

        // Build AppLimit array for events
        var appLimits: [AppLimitToken] = []
        appLimits += selection.applicationTokens.map {
            AppLimitToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        // IMMEDIATE SHIELD APPLICATION - Key difference from Time Limit
        if config.isCurrentlyInBlockingPeriod {
            await deviceActivityManager.applyShield(for: selection)
        } else {
            // Clear shields for these apps if not in blocking period
            await deviceActivityManager.removeShield(for: selection)
        }

        // Create schedule with custom time window
        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: config.startTime,
            endTime: config.endTime,
            repeats: true
        )

        // Create events with zero threshold (immediate)
        let events = ScreenTimeEvents.createTimeOfDayEvents(for: appLimits)

        // Start monitoring
        let name = DeviceActivityName("timeOfDay_\(ruleId.uuidString)")
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)
    }

    func deleteTimeOfDay(id: UUID) async throws {
        let name = DeviceActivityName("timeOfDay_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        repository.deleteTimeOfDayRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - All Day Limit

    func setAllDayBlock(for selection: FamilyActivitySelection, config: AllDayConfig) async throws {
        let ruleId = config.id ?? UUID()
        let rule = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .allDay,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )

        repository.setAllDayRule(rule)

        // Build AppLimit array for events
        var appLimits: [AppLimitToken] = []
        appLimits += selection.applicationTokens.map {
            AppLimitToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        // IMMEDIATE SHIELD APPLICATION - Key difference
        if config.shouldBlockToday {
            await deviceActivityManager.applyShield(for: selection)
        } else {
            // Clear shields for these apps if today is not active
            await deviceActivityManager.removeShield(for: selection)
        }

        // Create full-day schedule
        let schedule = DeviceActivityScheduleHelper.createFullDaySchedule()

        // Create events
        let events = ScreenTimeEvents.createAllDayEvents(for: appLimits)

        // Start monitoring
        let name = DeviceActivityName("allDay_\(ruleId.uuidString)")
        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)
    }

    func deleteAllDay(id: UUID) async throws {
        let name = DeviceActivityName("allDay_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])
        repository.deleteAllDayRule(id: id)
        await reapplyActiveShields()
    }

    // MARK: - Get Rules

    func getAllRules() -> [ScreenTimeRule] {
        repository.getAllRules()
    }

    func getTimeLimitRules() -> [ScreenTimeRule] {
        repository.getTimeLimitRules()
    }

    func getTimeOfDayRules() -> [ScreenTimeRule] {
        repository.getTimeOfDayRules()
    }

    func getAllDayRules() -> [ScreenTimeRule] {
        repository.getAllDayRules()
    }

    func getRule(id: UUID) -> ScreenTimeRule? {
        repository.getRule(id: id)
    }

    // MARK: - Shield Management

    func reapplyActiveShields() async {
        let allRules = getAllRules()
        await deviceActivityManager.reapplyActiveShields(rules: allRules)
    }

    // MARK: - Session Shield Management

    func applySessionShield(for selection: FamilyActivitySelection) async {
        await deviceActivityManager.applyShield(for: selection)
    }

    func removeSessionShield() async {
        // Remove all shields first
        await deviceActivityManager.removeShield()

        // Reapply rule-based shields
        await reapplyActiveShields()
    }

    // MARK: - Update Methods

    func updateTimeLimit(id: UUID, for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {
        // 1. Stop existing monitoring
        let name = DeviceActivityName("daily_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])

        // 2. Update rule in repository
        let rule = ScreenTimeRule(
            id: id,
            name: config.name,
            selection: selection,
            type: .timeLimit,
            limitSeconds: config.limitSeconds,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )
        repository.setTimeLimitRule(rule)

        // 3. Restart monitoring
        var appLimits: [AppLimitToken] = []
        appLimits += selection.applicationTokens.map {
            AppLimitToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        let schedule = DeviceActivityScheduleHelper.createDailySchedule()
        let timeLimit = TimeLimit.fromMinutes(config.limitSeconds / 60)
        let events = ScreenTimeEvents.createEvents(for: timeLimit, selection: appLimits)

        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)

        // 4. Reapply shields
        await reapplyActiveShields()
    }

    func updateTimeOfDayBlock(id: UUID, for selection: FamilyActivitySelection, config: TimeOfDayConfig) async throws {
        // 1. Stop existing monitoring
        let name = DeviceActivityName("timeOfDay_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])

        // 2. Update rule in repository
        let rule = ScreenTimeRule(
            id: id,
            name: config.name,
            selection: selection,
            type: .timeOfDay,
            startTime: config.startTime,
            endTime: config.endTime,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )
        repository.setTimeOfDayRule(rule)

        // 3. Apply shields if currently in blocking period
        if config.isCurrentlyInBlockingPeriod {
            await deviceActivityManager.applyShield(for: selection)
        } else {
            await deviceActivityManager.removeShield(for: selection)
        }

        // 4. Restart monitoring
        var appLimits: [AppLimitToken] = []
        appLimits += selection.applicationTokens.map {
            AppLimitToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: config.startTime,
            endTime: config.endTime,
            repeats: true
        )
        let events = ScreenTimeEvents.createTimeOfDayEvents(for: appLimits)

        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)

        // 5. Reapply shields
        await reapplyActiveShields()
    }

    func updateAllDayBlock(id: UUID, for selection: FamilyActivitySelection, config: AllDayConfig) async throws {
        // 1. Stop existing monitoring
        let name = DeviceActivityName("allDay_\(id.uuidString)")
        try await deviceActivityManager.stopMonitoring(names: [name])

        // 2. Update rule in repository
        let rule = ScreenTimeRule(
            id: id,
            name: config.name,
            selection: selection,
            type: .allDay,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions
        )
        repository.setAllDayRule(rule)

        // 3. Apply shields if today is active
        if config.shouldBlockToday {
            await deviceActivityManager.applyShield(for: selection)
        } else {
            await deviceActivityManager.removeShield(for: selection)
        }

        // 4. Restart monitoring
        var appLimits: [AppLimitToken] = []
        appLimits += selection.applicationTokens.map {
            AppLimitToken(id: UUID(), applicationToken: $0, categoryToken: nil)
        }
        appLimits += selection.categoryTokens.map {
            AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: $0)
        }

        let schedule = DeviceActivityScheduleHelper.createFullDaySchedule()
        let events = ScreenTimeEvents.createAllDayEvents(for: appLimits)

        try await deviceActivityManager.startMonitoring(name: name, schedule: schedule, events: events)

        // 5. Reapply shields
        await reapplyActiveShields()
    }
}
