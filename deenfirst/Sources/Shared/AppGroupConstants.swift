import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.aydev.deenfirst"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Token Storage Keys

    static let tokenMappingKey = "tokenMapping"
    static let categoryTokensKey = "categoryTokens"
    static let selectedAppsKey = "selectedApps"  // Deprecated — kept for backward compat

    /// Per-rule token storage used by DeviceActivityMonitorExtension.
    /// Structure: [ruleId (UUID string): ["apps": [Data], "categories": [Data]]]
    static let ruleTokensKey = "ruleTokens"

    // MARK: - State Tracking Keys

    static let triggeredRuleIdsKey = "triggeredRuleIds"
    static let isSessionActiveKey = "isSessionActive"
    static let tempUnblockActivityPrefix = "tempUnblock_"
    static let reciteRequested = "reciteRequested"

    // MARK: - Emergency Unblock Keys

    static let emergencyUnblockExpiryKey = "emergencyUnblockExpiry"
    static let emergencyUnblockUsedCountKey = "emergencyUnblockUsedCount"
    static let emergencyUnblockWeekStartKey = "emergencyUnblockWeekStart"
    static let emergencyReblockNotificationId = "emergencyReblock"

    // MARK: - Per-Rule Unblock Keys

    /// Returns the SharedDefaults key storing the unblock expiry timestamp for a specific rule.
    /// Each rule has its own independent expiry — multiple rules can be unblocked simultaneously
    /// with separate timers (e.g. Games unblocked for 3 min, Entertainment unblocked for 1 min).
    static func unblockExpiryKey(for ruleId: UUID) -> String {
        "unblockExpiry_\(ruleId.uuidString)"
    }

    /// Returns the UNNotificationRequest identifier for the reblock notification of a specific rule.
    /// Per-rule identifiers allow cancelling one rule's notification without affecting others.
    static func reblockNotificationId(for ruleId: UUID) -> String {
        "reblock_\(ruleId.uuidString)"
    }

    static func timeLimitWarningNotificationId(for ruleId: UUID) -> String {
        "timeLimitWarning_\(ruleId.uuidString)"
    }

    static func timeLimitWarningNotificationId(for ruleId: UUID, weekday: Int) -> String {
        "timeLimitWarning_\(ruleId.uuidString)_\(weekday)"
    }

    static let motivationalNotificationPrefix = "motivational_"
}
