import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

protocol AppLimitService {
    func createAppLimit(name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int], isAllDay: Bool) async throws
    func getAppLimits() async throws -> [AppLimit]
    func updateAppLimit(_ limit: AppLimit) async throws
    func deleteAppLimit(_ limit: AppLimit) async throws
}

final class AppLimitServiceImpl: AppLimitService {
    let repository: AppLimitRepository
    let screenTimeRepository: ScreenTimeRepository

    init(repository: AppLimitRepository, screenTimeRepository: ScreenTimeRepository) {
        self.repository = repository
        self.screenTimeRepository = screenTimeRepository
    }

    func createAppLimit(name: String, appTokens: [Data], dailyLimitMinutes: Int, activeDays: [Int], isAllDay: Bool) async throws {
        let limit = AppLimit(
            name: name,
            appTokens: appTokens,
            dailyLimitMinutes: dailyLimitMinutes,
            activeDays: activeDays,
            isAllDay: isAllDay
        )

        // Save to database
        try await repository.create(limit)

        // Setup DeviceActivity monitoring
        try await startActivityMonitoring(for: limit)
    }

    func getAppLimits() async throws -> [AppLimit] {
        try await repository.getAll()
    }

    func updateAppLimit(_ limit: AppLimit) async throws {
        // Stop old monitoring based on type
        let oldName = limit.isAllDay ? ScreenTimeActivity.allDayMonitoring(for: limit.id) : ScreenTimeActivity.dailyMonitoring(for: limit.id)
        try await screenTimeRepository.stopActivityMonitoring([oldName])

        // Update in database
        try await repository.update(limit)

        // Restart monitoring with new settings
        try await startActivityMonitoring(for: limit)
    }

    func deleteAppLimit(_ limit: AppLimit) async throws {
        // Stop monitoring
        let name = limit.isAllDay ? ScreenTimeActivity.allDayMonitoring(for: limit.id) : ScreenTimeActivity.dailyMonitoring(for: limit.id)
        try await screenTimeRepository.stopActivityMonitoring([name])

        // Delete from database
        try await repository.delete(limit)

        // Reapply shields for remaining active limits
        await reapplyActiveShields(excluding: limit.id)
    }

    // MARK: - Private Helpers

    private func startActivityMonitoring(for limit: AppLimit) async throws {
        // Decode app tokens - UUID will be generated deterministically in ScreenTimeEvents
        var appTokens: [AppLimitToken] = []
        for tokenData in limit.appTokens {
            if let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) {
                appTokens.append(AppLimitToken(id: UUID(), applicationToken: token, categoryToken: nil))
            }
        }

        let isTodayActive = DayHelper.isDayActive(activeDays: limit.activeDays)

        if limit.isAllDay {
            // All Day Limit: immediate blocking on active days
            // Create events with zero threshold (immediate)
            let events = ScreenTimeEvents.createAllDayEvents(for: appTokens)

            // Create full-day schedule
            let schedule = DeviceActivityScheduleHelper.createFullDaySchedule()

            // Start monitoring
            let name = ScreenTimeActivity.allDayMonitoring(for: limit.id)
            try await screenTimeRepository.startActivityMonitoring(name: name, schedule: schedule, events: events)

            // Apply shield immediately if today is active
            if isTodayActive {
                await applyImmediateShield(for: appTokens)
            }
        } else {
            // Time Limit: track usage and apply shield when threshold reached
            let timeLimit = TimeLimit.fromMinutes(limit.dailyLimitMinutes)

            // Create events with time threshold
            let events = ScreenTimeEvents.createEvents(for: timeLimit, selection: appTokens)

            // Create daily schedule (resets at midnight)
            let schedule = DeviceActivityScheduleHelper.createDailySchedule()

            // Start monitoring
            let name = ScreenTimeActivity.dailyMonitoring(for: limit.id)
            try await screenTimeRepository.startActivityMonitoring(name: name, schedule: schedule, events: events)

            // Do NOT apply shield immediately for time limits
            // Shield will be applied by extension when threshold is reached
        }
    }

    // MARK: - Immediate Shield Application

    private func applyImmediateShield(for appTokens: [AppLimitToken]) async {
        await MainActor.run {
            let store = ManagedSettingsStore()
            var applicationTokens: Set<ApplicationToken> = []

            for appToken in appTokens {
                if let token = appToken.applicationToken {
                    applicationTokens.insert(token)
                }
            }

            store.shield.applications = applicationTokens
        }
    }

    // MARK: - Reapply Shields

    private func reapplyActiveShields(excluding excludedId: UUID) async {
        do {
            let activeLimits = try await repository.getAll()

            // Filter out the deleted limit and limits that are not active today
            let todayActiveLimits = activeLimits.filter { limit in
                limit.id != excludedId &&
                limit.isActive &&
                DayHelper.isDayActive(activeDays: limit.activeDays)
            }

            guard !todayActiveLimits.isEmpty else {
                // No more active limits - clear all shields
                await MainActor.run {
                    let store = ManagedSettingsStore()
                    store.clearAllSettings()
                }
                return
            }

            // Collect all tokens from active limits
            var allApplicationTokens: Set<ApplicationToken> = []

            for limit in todayActiveLimits {
                for tokenData in limit.appTokens {
                    if let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) {
                        allApplicationTokens.insert(token)
                    }
                }
            }

            // Apply shields for remaining active limits
            await MainActor.run {
                let store = ManagedSettingsStore()
                store.shield.applications = allApplicationTokens
            }
        } catch {
            // Silently fail - reapplying shields is best-effort
        }
    }
}
