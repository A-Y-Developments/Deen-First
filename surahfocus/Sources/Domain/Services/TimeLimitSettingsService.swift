import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

protocol TimeLimitService {
    func createTimeLimit(userId: UUID, name: String, appTokens: [Data], startTime: String, endTime: String, activeDays: [Int], isAllDay: Bool, prayerTimes: [String]) async throws
    func getTimeLimits(userId: UUID) async throws -> [TimeLimitSettings]
    func updateTimeLimit(_ limit: TimeLimitSettings) async throws
    func deleteTimeLimit(_ limit: TimeLimitSettings) async throws
    func validateTimeRange(start: String, end: String) -> Bool
}

final class TimeLimitSettingsServiceImpl: TimeLimitService {
    let repository: TimeLimitRepository
    let screenTimeRepository: ScreenTimeRepository

    init(repository: TimeLimitRepository, screenTimeRepository: ScreenTimeRepository) {
        self.repository = repository
        self.screenTimeRepository = screenTimeRepository
    }

    func createTimeLimit(userId: UUID, name: String, appTokens: [Data], startTime: String, endTime: String, activeDays: [Int], isAllDay: Bool, prayerTimes: [String]) async throws {
        // Validate time range
        guard validateTimeRange(start: startTime, end: endTime) else {
            throw TimeLimitSettingsServiceError.invalidTimeRange
        }

        let limit = TimeLimitSettings(
            userId: userId,
            name: name,
            appTokens: appTokens,
            startTime: startTime,
            endTime: endTime,
            activeDays: activeDays,
            isAllDay: isAllDay,
            prayerTimes: prayerTimes
        )

        try await repository.create(limit)

        // Start DeviceActivity monitoring for prayer time blocking
        try await startActivityMonitoring(for: limit)
    }

    func getTimeLimits(userId: UUID) async throws -> [TimeLimitSettings] {
        try await repository.getAll(for: userId)
    }

    func updateTimeLimit(_ limit: TimeLimitSettings) async throws {
        // Stop old monitoring
        let oldName = ScreenTimeActivity.timeOfDayMonitoring(for: limit.id)
        try await screenTimeRepository.stopActivityMonitoring([oldName])

        // Validate time range if updated
        if !validateTimeRange(start: limit.startTime, end: limit.endTime) {
            throw TimeLimitSettingsServiceError.invalidTimeRange
        }

        try await repository.update(limit)

        // Restart monitoring with new settings
        try await startActivityMonitoring(for: limit)
    }

    func deleteTimeLimit(_ limit: TimeLimitSettings) async throws {
        // Stop monitoring
        let name = ScreenTimeActivity.timeOfDayMonitoring(for: limit.id)
        try await screenTimeRepository.stopActivityMonitoring([name])

        try await repository.delete(limit)

        // Reapply shields for remaining active limits
        await reapplyActiveShields()
    }

    // MARK: - Private Helpers

    private func startActivityMonitoring(for limit: TimeLimitSettings) async throws {
        // Parse time strings to DateComponents
        guard let startComponents = parseTimeToComponents(limit.startTime),
              let endComponents = parseTimeToComponents(limit.endTime) else {
            throw TimeLimitSettingsServiceError.invalidTimeFormat
        }

        // Decode app tokens
        var appTokens: [AppLimitToken] = []
        for tokenData in limit.appTokens {
            if let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) {
                appTokens.append(AppLimitToken(id: UUID(), applicationToken: token, categoryToken: nil))
            }
        }

        // Create time-of-day events with zero threshold (immediate)
        let events = ScreenTimeEvents.createTimeOfDayEvents(for: appTokens)

        // Create schedule with custom time window
        let schedule = DeviceActivityScheduleHelper.createCustomSchedule(
            startTime: startComponents,
            endTime: endComponents,
            repeats: true
        )

        // Start monitoring
        let name = ScreenTimeActivity.timeOfDayMonitoring(for: limit.id)
        try await screenTimeRepository.startActivityMonitoring(name: name, schedule: schedule, events: events)

        // Apply shield immediately if currently within time window and today is active
        let isTodayActive = DayHelper.isDayActive(activeDays: limit.activeDays)
        if isTodayActive && isCurrentlyInTimeWindow(start: startComponents, end: endComponents) {
            await applyImmediateShield(for: appTokens)
        }
    }

    private func parseTimeToComponents(_ time: String) -> DateComponents? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: time) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return components
    }

    private func isCurrentlyInTimeWindow(start: DateComponents, end: DateComponents) -> Bool {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.hour, .minute], from: Date())

        let currentHour = now.hour ?? 0
        let currentMinute = now.minute ?? 0
        let startHour = start.hour ?? 0
        let startMinute = start.minute ?? 0
        let endHour = end.hour ?? 0
        let endMinute = end.minute ?? 0

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }

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

    private func reapplyActiveShields() async {
        do {
            let allLimits = try await repository.getAll(for: UUID()) // Get all limits regardless of user

            let todayActiveLimits = allLimits.filter { limit in
                limit.isActive &&
                DayHelper.isDayActive(activeDays: limit.activeDays)
            }

            guard !todayActiveLimits.isEmpty else {
                await MainActor.run {
                    let store = ManagedSettingsStore()
                    store.clearAllSettings()
                }
                return
            }

            var allApplicationTokens: Set<ApplicationToken> = []

            for limit in todayActiveLimits {
                for tokenData in limit.appTokens {
                    if let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) {
                        allApplicationTokens.insert(token)
                    }
                }
            }

            await MainActor.run {
                let store = ManagedSettingsStore()
                store.shield.applications = allApplicationTokens
            }
        } catch {
            // Silently fail
        }
    }

    func validateTimeRange(start: String, end: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            return false
        }

        return endDate > startDate
    }
}

enum TimeLimitSettingsServiceError: Error, LocalizedError {
    case invalidTimeRange
    case invalidTimeFormat

    var errorDescription: String? {
        switch self {
        case .invalidTimeRange:
            return "End time must be later than start time"
        case .invalidTimeFormat:
            return "Time format must be HH:mm"
        }
    }
}
