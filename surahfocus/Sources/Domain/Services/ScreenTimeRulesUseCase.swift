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
}

// MARK: - Screen Time Use Case Implementation

final class ScreenTimeRulesUseCaseImpl: ScreenTimeRulesUseCase {
    private let repository: ScreenTimeRulesRepository
    private let activityCenter = DeviceActivityCenter()
    private let managedSettingsStore = ManagedSettingsStore()
    private let authCenter = AuthorizationCenter.shared

    init(repository: ScreenTimeRulesRepository) {
        self.repository = repository
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
        try await startActivityMonitoring(name: name, schedule: schedule, events: events)

        // Do NOT apply shield immediately for time limits
        // Shield will be applied by extension when threshold is reached
    }

    func deleteTimeLimit(id: UUID) async throws {
        let name = DeviceActivityName("daily_\(id.uuidString)")
        try await stopActivityMonitoring([name])
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
            managedSettingsStore.shield.applications = Set(selection.applicationTokens)
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(selection.categoryTokens)
        } else {
            // Clear shields for these apps if not in blocking period
            clearShieldsFor(selection: selection)
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
        try await startActivityMonitoring(name: name, schedule: schedule, events: events)
    }

    func deleteTimeOfDay(id: UUID) async throws {
        let name = DeviceActivityName("timeOfDay_\(id.uuidString)")
        try await stopActivityMonitoring([name])
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
            managedSettingsStore.shield.applications = Set(selection.applicationTokens)
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(selection.categoryTokens)
        } else {
            // Clear shields for these apps if today is not active
            clearShieldsFor(selection: selection)
        }

        // Create full-day schedule
        let schedule = DeviceActivityScheduleHelper.createFullDaySchedule()

        // Create events
        let events = ScreenTimeEvents.createAllDayEvents(for: appLimits)

        // Start monitoring
        let name = DeviceActivityName("allDay_\(ruleId.uuidString)")
        try await startActivityMonitoring(name: name, schedule: schedule, events: events)
    }

    func deleteAllDay(id: UUID) async throws {
        let name = DeviceActivityName("allDay_\(id.uuidString)")
        try await stopActivityMonitoring([name])
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
        await MainActor.run {
            let allRules = getAllRules()

            var applicationTokens: Set<ApplicationToken> = []
            var categoryTokens: Set<ActivityCategoryToken> = []

            let todayName = DayHelper.getCurrentDayName()
            let calendar = Calendar.current
            let now = Date()
            let comps = calendar.dateComponents([.hour, .minute], from: now)
            let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

            func isWithin(start: DateComponents?, end: DateComponents?) -> Bool {
                guard let s = start, let e = end else { return false }
                let sMin = (s.hour ?? 0) * 60 + (s.minute ?? 0)
                let eMin = (e.hour ?? 0) * 60 + (e.minute ?? 0)
                if sMin <= eMin {
                    return currentMinutes >= sMin && currentMinutes <= eMin
                } else {
                    return currentMinutes >= sMin || currentMinutes <= eMin
                }
            }

            // Time-of-day rules
            for rule in getTimeOfDayRules() {
                let days = rule.daysActive ?? []
                let isActiveDay = days.isEmpty || days.contains(todayName)
                if isActiveDay && isWithin(start: rule.getStartTimeComponents(), end: rule.getEndTimeComponents()) {
                    let selection = rule.getFamilyActivitySelection()
                    applicationTokens.formUnion(selection.applicationTokens)
                    categoryTokens.formUnion(selection.categoryTokens)
                }
            }

            // All-day rules
            for rule in getAllDayRules() {
                let days = rule.daysActive ?? []
                let isActiveDay = days.isEmpty || days.contains(todayName)
                if isActiveDay {
                    let selection = rule.getFamilyActivitySelection()
                    applicationTokens.formUnion(selection.applicationTokens)
                    categoryTokens.formUnion(selection.categoryTokens)
                }
            }

            // Apply shields
            if !applicationTokens.isEmpty || !categoryTokens.isEmpty {
                managedSettingsStore.shield.applications = applicationTokens
                if categoryTokens.isEmpty {
                    managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
                } else {
                    managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(categoryTokens)
                }
            } else {
                managedSettingsStore.clearAllSettings()
            }
        }
    }

    // MARK: - Private Helpers

    private func startActivityMonitoring(
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws {
        print("🚀 Starting monitoring for: \(name.rawValue) with \(events.count) events")
        for (eventName, event) in events {
            print("  Event: \(eventName.rawValue) threshold: \(event.threshold.second ?? 0)s")
        }
        try await MainActor.run {
            if !events.isEmpty {
                try activityCenter.startMonitoring(name, during: schedule, events: events)
            } else {
                try activityCenter.startMonitoring(name, during: schedule)
            }
        }
        print("✅ Monitoring started successfully")
    }

    private func stopActivityMonitoring(_ names: [DeviceActivityName]) async throws {
        try await MainActor.run {
            try activityCenter.stopMonitoring(names)
        }
    }

    private func clearShieldsFor(selection: FamilyActivitySelection) {
        // Get current tokens
        let currentApps = managedSettingsStore.shield.applications ?? []
        let currentCategories = getCurrentCategoryTokens()

        // Remove the selection tokens from current shields
        let newApps = currentApps.subtracting(selection.applicationTokens)

        // For categories, we need to rebuild since it's a policy
        managedSettingsStore.shield.applications = newApps.isEmpty ? [] : newApps

        // Note: Category handling is more complex, simplified here
        // In production, you'd need to track all category policies
    }

    private func getCurrentCategoryTokens() -> Set<ActivityCategoryToken> {
        // This is a simplified version
        // In production, you'd need to track the actual category tokens from policies
        return []
    }

    // MARK: - Update Methods

    func updateTimeLimit(id: UUID, for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {
        // 1. Stop existing monitoring
        let name = DeviceActivityName("daily_\(id.uuidString)")
        try await stopActivityMonitoring([name])

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

        try await startActivityMonitoring(name: name, schedule: schedule, events: events)

        // 4. Reapply shields
        await reapplyActiveShields()
    }

    func updateTimeOfDayBlock(id: UUID, for selection: FamilyActivitySelection, config: TimeOfDayConfig) async throws {
        // 1. Stop existing monitoring
        let name = DeviceActivityName("timeOfDay_\(id.uuidString)")
        try await stopActivityMonitoring([name])

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
            managedSettingsStore.shield.applications = Set(selection.applicationTokens)
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(selection.categoryTokens)
        } else {
            clearShieldsFor(selection: selection)
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

        try await startActivityMonitoring(name: name, schedule: schedule, events: events)

        // 5. Reapply shields
        await reapplyActiveShields()
    }

    func updateAllDayBlock(id: UUID, for selection: FamilyActivitySelection, config: AllDayConfig) async throws {
        // 1. Stop existing monitoring
        let name = DeviceActivityName("allDay_\(id.uuidString)")
        try await stopActivityMonitoring([name])

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
            managedSettingsStore.shield.applications = Set(selection.applicationTokens)
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(selection.categoryTokens)
        } else {
            clearShieldsFor(selection: selection)
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

        try await startActivityMonitoring(name: name, schedule: schedule, events: events)

        // 5. Reapply shields
        await reapplyActiveShields()
    }
}
