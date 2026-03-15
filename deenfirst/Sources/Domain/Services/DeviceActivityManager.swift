import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

protocol DeviceActivityManager {
    func startMonitoring(
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws
    func stopMonitoring(names: Set<DeviceActivityName>) async throws
    func applyShield(for selection: FamilyActivitySelection) async
    func removeShield() async
    func removeShield(for selection: FamilyActivitySelection) async
    func reapplyActiveShields(rules: [ScreenTimeRule]) async
}

@MainActor
final class DeviceActivityManagerImpl: DeviceActivityManager {
    private let activityCenter = DeviceActivityCenter()
    private let managedSettings: ManagedSettingsWrapper

    init(managedSettings: ManagedSettingsWrapper) {
        self.managedSettings = managedSettings
    }

    // MARK: - Monitoring

    func startMonitoring(
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws {
        print("🚀 Starting monitoring for: \(name.rawValue) with \(events.count) events")
        for (eventName, event) in events {
            print("  Event: \(eventName.rawValue) threshold: \(event.threshold.second ?? 0)s")
        }
        if !events.isEmpty {
            try activityCenter.startMonitoring(name, during: schedule, events: events)
        } else {
            try activityCenter.startMonitoring(name, during: schedule)
        }
        print("✅ Monitoring started successfully")
    }

    func stopMonitoring(names: Set<DeviceActivityName>) async throws {
        try activityCenter.stopMonitoring(Array(names))
    }

    // MARK: - Shield Application (additive)

    func applyShield(for selection: FamilyActivitySelection) async {
        managedSettings.applyShields(
            applicationTokens: selection.applicationTokens,
            categoryTokens: selection.categoryTokens
        )
    }

    // MARK: - Shield Removal

    /// Removes ALL shields unconditionally.
    /// Only use for subscription expiry or full rule deletion.
    func removeShield() async {
        managedSettings.removeAllShields()
    }

    /// Removes only the tokens from the given selection.
    func removeShield(for selection: FamilyActivitySelection) async {
        managedSettings.removeShields(
            applicationTokens: selection.applicationTokens,
            categoryTokens: selection.categoryTokens
        )
    }

    // MARK: - Reapply Active Shields (atomic full recompute)

    /// Computes the complete desired shield state from ALL active rule sources,
    /// then atomically replaces whatever is currently set.
    ///
    /// Sources considered:
    ///   1. TimeLimit rules — if we're currently inside their scheduled window
    ///   2. AppLimit rules — if their daily threshold was reached today
    ///   3. Active Focus Session — if a session is currently running
    ///
    /// FIX: Previously only handled TimeLimit rules, ignoring AppLimit rules entirely.
    /// FIX: Uses `replaceShields` (atomic swap) instead of removeAll+reapply, eliminating
    ///      the brief unshielded window between the two calls.
    func reapplyActiveShields(rules: [ScreenTimeRule]) async {
        var applicationTokens: Set<ApplicationToken> = []
        var categoryTokens: Set<ActivityCategoryToken> = []

        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        // Load triggered AppLimit rule IDs (persisted by DeviceActivityMonitorExtension)
        let triggeredRuleIds = ScreenTimeEvents.getTriggeredRuleIds()

        func isWithinWindow(start: DateComponents?, end: DateComponents?) -> Bool {
            guard let s = start, let e = end else { return false }
            let sMin = (s.hour ?? 0) * 60 + (s.minute ?? 0)
            let eMin = (e.hour ?? 0) * 60 + (e.minute ?? 0)
            if sMin <= eMin {
                return currentMinutes >= sMin && currentMinutes <= eMin
            } else {
                // Overnight schedule (e.g., 23:00 → 01:00)
                return currentMinutes >= sMin || currentMinutes <= eMin
            }
        }

        for rule in rules {
            // Use unified day check (respects locale via DayHelper)
            guard DayHelper.isActiveToday(daysActive: rule.daysActive) else { continue }

            switch rule.type {
            case .timeLimit:
                // Restore if we're currently inside the schedule window
                if isWithinWindow(
                    start: rule.getStartTimeComponents(),
                    end: rule.getEndTimeComponents()
                ) {
                    let selection = rule.getFamilyActivitySelection()
                    applicationTokens.formUnion(selection.applicationTokens)
                    categoryTokens.formUnion(selection.categoryTokens)
                }

            case .appLimit:
                // FIX: Restore if this rule's quota was reached today
                if triggeredRuleIds.contains(rule.id.uuidString) {
                    let selection = rule.getFamilyActivitySelection()
                    applicationTokens.formUnion(selection.applicationTokens)
                    categoryTokens.formUnion(selection.categoryTokens)
                }
            }
        }

        // FIX: If a Focus Session is currently active, include its app tokens too.
        // Without this, calling reapplyActiveShields mid-session (e.g., when deleting
        // a rule) would strip the session shield.
        let isSessionActive = AppGroupConstants.sharedDefaults?.bool(
            forKey: AppGroupConstants.isSessionActiveKey) ?? false

        if isSessionActive {
            if let tokenMapping = AppGroupConstants.sharedDefaults?
                .dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data]
            {
                for (_, data) in tokenMapping {
                    if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                        applicationTokens.insert(token)
                    }
                }
            }
            if let categoryMapping = AppGroupConstants.sharedDefaults?
                .dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data]
            {
                for (_, data) in categoryMapping {
                    if let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                        categoryTokens.insert(token)
                    }
                }
            }
        }

        // Atomic replace — compute full desired state first, then apply in one call
        managedSettings.replaceShields(
            applicationTokens: applicationTokens,
            categoryTokens: categoryTokens
        )

        print("✅ Reapplied shields: \(applicationTokens.count) apps, \(categoryTokens.count) categories" +
              (isSessionActive ? " (+ session active)" : ""))
    }
}