import FamilyControls
import Foundation

// MARK: - Lock Editing Gate Extension

extension ScreenTimeRulesServiceImpl {

    // MARK: - Edit App Limit (Gated)

    func editAppLimitRule(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {
        guard let ruleId = config.id else {
            // No id — treat as create (new rule, no lock gate applies)
            try await setAppLimitBlock(for: selection, config: config)
            return
        }
        guard let rule = repository.getRule(id: ruleId) else { return }

        if rule.isLockEditingEnabled {
            guard let pending = pendingChangeService else {
                print("⚠️ [LockEditing] pendingChangeService not injected — cannot queue edit for rule \(ruleId)")
                return
            }
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
            try? await deleteAppLimit(id: ruleId)
            try await setAppLimitBlock(for: selection, config: config)
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
            guard let pending = pendingChangeService else {
                print("⚠️ [LockEditing] pendingChangeService not injected — cannot queue edit for rule \(ruleId)")
                return
            }
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
            try? await deleteTimeLimit(id: ruleId)
            try await setTimeLimitBlock(for: selection, config: config)
        }
    }

    // MARK: - Delete Rule (Gated)

    func deleteRule(id: UUID) async throws {
        guard let rule = repository.getRule(id: id) else { return }

        if rule.isLockEditingEnabled {
            guard let pending = pendingChangeService else {
                print("⚠️ [LockEditing] pendingChangeService not injected — cannot queue delete for rule \(id)")
                return
            }
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
            guard let pending = pendingChangeService else {
                print("⚠️ [LockEditing] pendingChangeService not injected — cannot queue disable for rule \(id)")
                return
            }
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.disable.rawValue, pendingData: nil)
        } else {
            try await deactivateRule(id: id)
        }
    }

    // MARK: - Disable Hard Mode (Gated)

    func disableHardMode(for ruleId: UUID) async {
        guard let rule = repository.getRule(id: ruleId) else { return }

        if rule.isLockEditingEnabled {
            guard let pending = pendingChangeService else {
                print("⚠️ [LockEditing] pendingChangeService not injected — cannot queue disableHardMode for rule \(ruleId)")
                return
            }
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.disableHardMode.rawValue, pendingData: nil)
        } else {
            applyFlagUpdate(ruleId: ruleId) { $0.isHardMode = false }
        }
    }

    // MARK: - Disable Lock Editing (Gated)

    func disableLockEditing(for ruleId: UUID) async {
        guard let rule = repository.getRule(id: ruleId) else { return }

        if rule.isLockEditingEnabled {
            guard let pending = pendingChangeService else {
                print("⚠️ [LockEditing] pendingChangeService not injected — cannot queue disableLockEditing for rule \(ruleId)")
                return
            }
            await pending.createPendingChange(for: rule, changeType: PendingChangeType.disableLockEditing.rawValue, pendingData: nil)
        } else {
            applyFlagUpdate(ruleId: ruleId) { $0.isLockEditingEnabled = false }
        }
    }

    // MARK: - Private: Flag Update Helper

    private func applyFlagUpdate(ruleId: UUID, update: (inout ScreenTimeRule) -> Void) {
        guard var rule = repository.getRule(id: ruleId) else { return }
        update(&rule)
        switch rule.type {
        case .appLimit:  repository.setAppLimitRule(rule)
        case .timeLimit: repository.setTimeLimitRule(rule)
        }
    }
}
