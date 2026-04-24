import FamilyControls
import Foundation

// MARK: - Lock Editing Gate Extension

extension ScreenTimeRulesServiceImpl {

    /// Resolves the injected `PendingChangeService` or crashes if it was
    /// never wired. DIContainer injects this after both services are built
    /// to break a circular init dependency — a nil here means the DI wiring
    /// regressed, and silently no-op'ing would disable the entire lock-editing
    /// gate (security-critical). Fail loudly instead.
    fileprivate func requirePendingChangeService(_ context: String) -> PendingChangeService {
        guard let pending = pendingChangeService else {
            preconditionFailure("PendingChangeService must be injected before \(context) is called")
        }
        return pending
    }

    // MARK: - Edit App Limit (Gated)

    func editAppLimitRule(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {
        guard let ruleId = config.id else {
            // No id — treat as create (new rule, no lock gate applies)
            try await setAppLimitBlock(for: selection, config: config)
            return
        }
        guard let rule = repository.getRule(id: ruleId) else { return }

        if rule.isLockEditingEnabled {
            let pending = requirePendingChangeService("editAppLimitRule")
            let updatedRule = ScreenTimeRule(
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
            let pendingData = try? JSONEncoder().encode(updatedRule)
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.edit.rawValue, pendingData: pendingData)
        } else {
            // Transactional update-in-place. setAppLimitBlock starts monitoring
            // under the same DeviceActivityName (replacing the prior monitor)
            // before upserting the repo — if it throws, the existing rule and
            // its monitor remain intact. Re-apply shields to reflect the new
            // selection and clear any stale shields.
            try await setAppLimitBlock(for: selection, config: config)
            await reapplyActiveShields()
        }
    }

    // MARK: - Edit Time Limit (Gated)

    func editTimeLimitRule(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {
        guard let ruleId = config.id else {
            try await setTimeLimitBlock(for: selection, config: config)
            return
        }
        guard let rule = repository.getRule(id: ruleId) else { return }

        if rule.isLockEditingEnabled {
            let pending = requirePendingChangeService("editTimeLimitRule")
            let updatedRule = ScreenTimeRule(
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
            let pendingData = try? JSONEncoder().encode(updatedRule)
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.edit.rawValue, pendingData: pendingData)
        } else {
            // Transactional update-in-place. See editAppLimitRule above for rationale.
            try await setTimeLimitBlock(for: selection, config: config)
            await reapplyActiveShields()
        }
    }

    // MARK: - Delete Rule (Gated)

    func deleteRule(id: UUID) async throws {
        guard let rule = repository.getRule(id: id) else { return }

        if rule.isLockEditingEnabled {
            let pending = requirePendingChangeService("deleteRule")
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.delete.rawValue, pendingData: nil)
        } else {
            switch rule.type {
            case .appLimit:  try await deleteAppLimit(id: id)
            case .timeLimit: try await deleteTimeLimit(id: id)
            }
        }
    }

    // MARK: - Disable Rule (Gated)

    func disableRule(id: UUID) async throws {
        guard let rule = repository.getRule(id: id) else { return }

        if rule.isLockEditingEnabled {
            let pending = requirePendingChangeService("disableRule")
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.disable.rawValue, pendingData: nil)
        } else {
            try await deactivateRule(id: id)
        }
    }

    // MARK: - Disable Hard Mode (Gated)

    func disableHardMode(for ruleId: UUID) async {
        guard let rule = repository.getRule(id: ruleId) else { return }
        let pending = requirePendingChangeService("disableHardMode")

        if rule.isLockEditingEnabled {
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.disableHardMode.rawValue, pendingData: nil)
        } else {
            await pending.applyFlagUpdate(ruleId: ruleId) { $0.isHardMode = false }
        }
    }

    // MARK: - Disable Lock Editing (Gated)

    func disableLockEditing(for ruleId: UUID) async {
        guard let rule = repository.getRule(id: ruleId) else { return }
        let pending = requirePendingChangeService("disableLockEditing")

        if rule.isLockEditingEnabled {
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.disableLockEditing.rawValue, pendingData: nil)
        } else {
            await pending.applyFlagUpdate(ruleId: ruleId) { $0.isLockEditingEnabled = false }
        }
    }
}
