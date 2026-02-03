import DeviceActivity
import FamilyControls
import ManagedSettings

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let managedSettingsStore = ManagedSettingsStore()
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    // MARK: - Interval Lifecycle

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // New day starts - reapply shields based on saved app selection
        reapplyShieldsForNewDay()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Interval ends - could reset daily counters
        resetDailyCounters()
    }

    // MARK: - Event Thresholds

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // User exceeded their time limit - apply shield
        applyShieldForEvent(event)
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)

        // User is approaching their limit - could trigger notification
        // (Not accessible from extension, but main app could listen for this)
    }

    // MARK: - Interval Warnings

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Interval about to start
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Interval about to end
    }

    // MARK: - Private Helpers

    private func reapplyShieldsForNewDay() {
        guard let sharedDefaults = sharedDefaults else { return }

        // Check if there's an active session
        let hasActiveSession = sharedDefaults.bool(forKey: "activeSession")

        // Reapply shields based on saved app selection
        if hasActiveSession,
           let tokenMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data],
           let categoryMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] {

            let applicationTokens = tokenMapping.compactMap { _, data -> ApplicationToken? in
                try? JSONDecoder().decode(ApplicationToken.self, from: data)
            }

            let categoryTokens = categoryMapping.compactMap { _, data -> ActivityCategoryToken? in
                try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
            }

            // Apply shields
            var settings = ManagedSettings()
            if !applicationTokens.isEmpty {
                settings.applicationShield = .strict(applicationTokens)
            }
            if !categoryTokens.isEmpty {
                settings.categoryShield = .strict(categoryTokens)
            }

            managedSettingsStore.shieldConfiguration = settings
        }
    }

    private func resetDailyCounters() {
        // Reset any daily usage tracking stored in app group
        sharedDefaults?.set(0, forKey: "dailyUsageSeconds")
    }

    private func applyShieldForEvent(_ event: DeviceActivityEvent.Name) {
        guard let sharedDefaults = sharedDefaults else { return }

        // Event name could be app-specific or category-specific
        // For now, we apply all configured shields
        reapplyShieldsForNewDay()
    }
}
