import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.aydev.surahfocus"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Token Storage Keys

    /// Stores the Focus Session's selected app tokens (keyed by token hashValue).
    static let tokenMappingKey = "tokenMapping"

    /// Stores the Focus Session's selected category tokens (keyed by token hashValue).
    static let categoryTokensKey = "categoryTokens"

    /// Deprecated — kept for backward compat. Use tokenMappingKey.
    static let selectedAppsKey = "selectedApps"

    /// Per-rule token storage used by DeviceActivityMonitorExtension.
    /// Structure: [ruleId (UUID string): ["apps": [Data], "categories": [Data]]]
    static let ruleTokensKey = "ruleTokens"

    // MARK: - State Tracking Keys

    /// Stores the UUIDs (as strings) of AppLimit rules that have reached their daily threshold.
    /// Cleared per-rule at midnight (intervalDidStart). Used by reapplyActiveShields to
    /// know which AppLimit rules need their shields restored after a Focus Session ends.
    static let triggeredRuleIdsKey = "triggeredRuleIds"

    /// Boolean flag — true while a Focus Session is active.
    /// Set to true in SessionService.startSession, false in SessionService.endSession.
    /// Used by reapplyActiveShields to include session app tokens when recomputing
    /// the full desired shield state (e.g., when an AppLimit rule is deleted mid-session)
    static let isSessionActiveKey = "isSessionActive"

    /// DeviceActivityName prefix for the temporary unblock schedule.
    /// When intervalDidEnd fires with this prefix, the extension re-applies all shields.
    /// This is the only reliable background re-block mechanism — Task.sleep is suspended
    /// by iOS when the app backgrounds.
    static let tempUnblockActivityPrefix = "tempUnblock_"

    /// Keys for recite-to-unblock feature
    static let reciteRequested = "reciteRequested"
    static let unblockExpiryKey = "unblockExpiry"
}