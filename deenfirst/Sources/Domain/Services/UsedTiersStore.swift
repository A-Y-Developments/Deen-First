import Foundation

/// Per-rule set of UnblockTiers the user has already completed in the current
/// blocking window. Used by `UnblockDurationSelectionViewModel` to gate the
/// progressive unlock (DF-022) and 3-tier cap (DF-023).
///
/// Reset by `ScreenTimeRulesService+Unblock.reblockIfExpired(ruleId:)` when the
/// rule re-blocks — a fresh block window grants the user a fresh 3-tier budget.
enum UsedTiersStore {
    static func usedTiers(
        ruleId: UUID,
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) -> Set<UnblockTier> {
        guard let raw = defaults?.stringArray(forKey: AppGroupConstants.usedTiersKey(for: ruleId)) else {
            return []
        }
        return Set(raw.compactMap(UnblockTier.init(rawValue:)))
    }

    static func mark(
        _ tier: UnblockTier,
        ruleId: UUID,
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) {
        var set = usedTiers(ruleId: ruleId, defaults: defaults)
        set.insert(tier)
        defaults?.set(set.map(\.rawValue), forKey: AppGroupConstants.usedTiersKey(for: ruleId))
    }

    static func reset(
        ruleId: UUID,
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) {
        defaults?.removeObject(forKey: AppGroupConstants.usedTiersKey(for: ruleId))
    }
}
