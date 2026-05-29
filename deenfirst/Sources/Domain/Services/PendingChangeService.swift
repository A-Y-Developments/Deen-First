import Foundation
import os

// MARK: - Protocol

protocol PendingChangeService {
    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async
    func cancelPendingChange(for ruleId: UUID) async
    func applyExpiredChanges() async
    func hasPendingChange(for ruleId: UUID) -> Bool
    func pendingChange(for ruleId: UUID) -> PendingRuleChange?

    /// Canonical helper for flipping boolean flags on a persisted rule.
    /// Shared with `ScreenTimeRulesService+LockEditing` — do not duplicate.
    func applyFlagUpdate(ruleId: UUID, update: @Sendable (inout ScreenTimeRule) -> Void)
}

// MARK: - Implementation

@MainActor
final class PendingChangeServiceImpl: PendingChangeService {
    private let localDataSource: LocalDataSource
    private let screenTimeRulesService: ScreenTimeRulesService
    private let screenTimeRulesRepository: ScreenTimeRulesRepository
    private let notificationSchedulingService: NotificationSchedulingService

    /// Tolerance when comparing wall-clock delta to monotonic-clock delta.
    /// Wall-clock may drift slightly relative to monotonic (NTP adjustments);
    /// 10 minutes is well above normal drift and well below any meaningful
    /// tamper attempt.
    private static let clockTamperToleranceSeconds: TimeInterval = 600

    private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "PendingChangeService")

    /// Monotonic seconds since boot. Unlike `Date()`, this is unaffected by
    /// wall-clock tampering and continues advancing during device sleep.
    private static func monotonicNow() -> TimeInterval {
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return TimeInterval(ts.tv_sec) + TimeInterval(ts.tv_nsec) / 1_000_000_000
    }

    init(
        localDataSource: LocalDataSource,
        screenTimeRulesService: ScreenTimeRulesService,
        screenTimeRulesRepository: ScreenTimeRulesRepository,
        notificationSchedulingService: NotificationSchedulingService
    ) {
        self.localDataSource = localDataSource
        self.screenTimeRulesService = screenTimeRulesService
        self.screenTimeRulesRepository = screenTimeRulesRepository
        self.notificationSchedulingService = notificationSchedulingService
    }

    // MARK: - Create

    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async {
        // Soft-cancel any existing pending change instead of hard-deleting it,
        // so the audit trail is preserved and we don't risk losing the prior
        // change if the subsequent insert fails.
        if let existing = pendingChange(for: rule.id) {
            notificationSchedulingService.cancelPendingChangeNotification(for: existing.id)
            existing.isCancelled = true
            do {
                try localDataSource.savePendingChanges()
            } catch {
                logger.error("Failed to soft-cancel prior pending change for rule \(rule.id): \(error.localizedDescription)")
            }
        }

        guard let parsedType = PendingChangeType(rawValue: changeType) else {
            logger.warning("Unknown changeType '\(changeType)' — change not created")
            return
        }

        let change = PendingRuleChange(
            ruleId: rule.id,
            changeType: parsedType,
            pendingData: pendingData
        )
        do {
            try localDataSource.insertPendingChange(change)
            notificationSchedulingService.schedulePendingChangeNotification(for: change, ruleName: rule.name)
        } catch {
            logger.error("Failed to insert change for rule \(rule.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel

    func cancelPendingChange(for ruleId: UUID) async {
        guard let change = pendingChange(for: ruleId) else { return }
        notificationSchedulingService.cancelPendingChangeNotification(for: change.id)
        change.isCancelled = true
        do {
            try localDataSource.savePendingChanges()
        } catch {
            logger.error("Failed to persist cancelled pending change \(change.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Apply Expired

    func applyExpiredChanges() async {
        let defaults = AppGroupConstants.sharedDefaults
        let now = Date()
        let monoNow = Self.monotonicNow()
        let lastWall = defaults?.double(forKey: AppGroupConstants.lastKnownDateKey) ?? 0
        let lastMono = defaults?.double(forKey: AppGroupConstants.lastKnownMonotonicKey) ?? 0

        if lastWall > 0 && lastMono > 0 {
            let wallElapsed = now.timeIntervalSince1970 - lastWall
            let monoElapsed = monoNow - lastMono

            // Monotonic clock resets on reboot. If it moved backwards (below
            // zero) or is less than the recorded last value, the device rebooted;
            // treat as benign and refresh the baseline.
            if monoElapsed < 0 {
                persistBaseline(wall: now, mono: monoNow, defaults: defaults)
            } else {
                // Wall clock rolled backwards: treat as tamper; skip silently.
                if wallElapsed < -Self.clockTamperToleranceSeconds {
                    logger.error("Wall clock rolled back \(Int(wallElapsed))s — skipping auto-apply")
                    persistBaseline(wall: now, mono: monoNow, defaults: defaults)
                    return
                }

                // Wall clock jumped forward materially further than monotonic:
                // real time didn't pass but the clock moved. Tamper — skip.
                if wallElapsed - monoElapsed > Self.clockTamperToleranceSeconds {
                    logger.error("Wall clock jumped \(Int(wallElapsed))s while monotonic advanced \(Int(monoElapsed))s — skipping auto-apply")
                    persistBaseline(wall: now, mono: monoNow, defaults: defaults)
                    return
                }
            }
        }

        persistBaseline(wall: now, mono: monoNow, defaults: defaults)

        let allChanges = (try? localDataSource.fetchPendingChanges()) ?? []
        let expired = allChanges.filter {
            !$0.isCancelled && !$0.isApplied && $0.appliesAt <= now
        }

        var appliedCount = 0
        for change in expired {
            do {
                try await applyChange(change)
                change.isApplied = true
                appliedCount += 1
                do {
                    try localDataSource.savePendingChanges()
                } catch {
                    logger.error("Applied change \(change.id) but failed to persist isApplied: \(error.localizedDescription)")
                }
                notificationSchedulingService.cancelPendingChangeNotification(for: change.id)
            } catch {
                logger.error("Failed to apply change \(change.id) for rule \(change.ruleId): \(error.localizedDescription)")
            }
        }

        // DF-22: notify observers (e.g. BlockingTabView) so a stale rule card
        // refreshes on the same foreground the change applied on. Only fire when
        // at least one change actually applied — failed applies stay pending.
        if appliedCount > 0 {
            NotificationCenter.default.post(name: .pendingChangesApplied, object: nil)
        }
    }

    private func persistBaseline(wall: Date, mono: TimeInterval, defaults: UserDefaults?) {
        defaults?.set(wall.timeIntervalSince1970, forKey: AppGroupConstants.lastKnownDateKey)
        defaults?.set(mono, forKey: AppGroupConstants.lastKnownMonotonicKey)
    }

    // MARK: - Query

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingChange(for: ruleId) != nil
    }

    func pendingChange(for ruleId: UUID) -> PendingRuleChange? {
        let all = (try? localDataSource.fetchPendingChanges()) ?? []
        return all.first { $0.ruleId == ruleId && !$0.isCancelled && !$0.isApplied }
    }

    // MARK: - Private: Apply Logic

    private func applyChange(_ change: PendingRuleChange) async throws {
        guard let type = PendingChangeType(rawValue: change.changeType) else {
            logger.warning("Unknown changeType '\(change.changeType)' — skipping")
            return
        }

        switch type {
        case .edit:
            try await applyEdit(change)
        case .delete:
            try await applyDelete(ruleId: change.ruleId)
        case .disable:
            try await applyDisable(ruleId: change.ruleId)
        case .disableHardMode:
            // DF-16: disabling Hard Mode must NOT auto-clear Lock Editing —
            // the user turns that off separately via .disableLockEditing.
            applyFlagUpdate(ruleId: change.ruleId) { $0.isHardMode = false }
        case .disableLockEditing:
            applyFlagUpdate(ruleId: change.ruleId) { $0.isLockEditingEnabled = false }
        }
    }

    private func applyEdit(_ change: PendingRuleChange) async throws {
        guard let data = change.pendingData else { return }
        let updatedRule = try JSONDecoder().decode(ScreenTimeRule.self, from: data)
        let selection = updatedRule.getFamilyActivitySelection()

        switch updatedRule.type {
        case .appLimit:
            let config = AppLimitConfig(
                id: updatedRule.id,
                name: updatedRule.name,
                timeLimit: .custom(updatedRule.limitSeconds ?? 0),
                daysActive: updatedRule.daysActive ?? [],
                unblockAllowedAfterLimit: updatedRule.unblockAllowedAfterLimit ?? 0,
                durationOptions: updatedRule.durationOptions ?? [],
                isHardMode: updatedRule.isHardMode,
                isLockEditingEnabled: updatedRule.isLockEditingEnabled
            )
            try await screenTimeRulesService.setAppLimitBlock(for: selection, config: config)

        case .timeLimit:
            guard let start = updatedRule.getStartTimeComponents(),
                  let end = updatedRule.getEndTimeComponents() else { return }
            let config = TimeLimitConfig(
                id: updatedRule.id,
                name: updatedRule.name,
                startTime: start,
                endTime: end,
                daysActive: updatedRule.daysActive ?? [],
                unblockAllowedAfterLimit: updatedRule.unblockAllowedAfterLimit ?? 0,
                durationOptions: updatedRule.durationOptions ?? [],
                isHardMode: updatedRule.isHardMode,
                isLockEditingEnabled: updatedRule.isLockEditingEnabled
            )
            try await screenTimeRulesService.setTimeLimitBlock(for: selection, config: config)
        }
    }

    private func applyDelete(ruleId: UUID) async throws {
        guard let rule = screenTimeRulesService.getRule(id: ruleId) else { return }
        switch rule.type {
        case .appLimit:  try await screenTimeRulesService.deleteAppLimit(id: ruleId)
        case .timeLimit: try await screenTimeRulesService.deleteTimeLimit(id: ruleId)
        }
    }

    private func applyDisable(ruleId: UUID) async throws {
        try await screenTimeRulesService.deactivateRule(id: ruleId)
    }

    func applyFlagUpdate(ruleId: UUID, update: @Sendable (inout ScreenTimeRule) -> Void) {
        guard var rule = screenTimeRulesRepository.getRule(id: ruleId) else {
            logger.warning("Rule \(ruleId) not found — skipping flag update")
            return
        }
        update(&rule)
        switch rule.type {
        case .appLimit:  screenTimeRulesRepository.setAppLimitRule(rule)
        case .timeLimit: screenTimeRulesRepository.setTimeLimitRule(rule)
        }
    }

}

// MARK: - Notifications

extension Notification.Name {
    /// Posted by `PendingChangeServiceImpl.applyExpiredChanges()` after ≥1
    /// expired pending change is applied. Observed by `BlockingTabView` to
    /// refresh stale rule cards on the same foreground. Declared here (not in
    /// `RootView.swift`) to keep the poster and the name together and avoid
    /// touching `RootView.swift`.
    static let pendingChangesApplied = Notification.Name("pendingChangesApplied")
}
