import Foundation
import UserNotifications
import os

// MARK: - Protocol

protocol PendingChangeService {
    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async
    func cancelPendingChange(for ruleId: UUID) async
    func applyExpiredChanges() async
    func hasPendingChange(for ruleId: UUID) -> Bool
    func pendingChange(for ruleId: UUID) -> PendingRuleChange?
}

// MARK: - Implementation

@MainActor
final class PendingChangeServiceImpl: PendingChangeService {
    private let localDataSource: LocalDataSource
    private let screenTimeRulesService: ScreenTimeRulesService
    private let screenTimeRulesRepository: ScreenTimeRulesRepository

    private static let clockJumpThreshold: TimeInterval = 7_200
    private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "PendingChangeService")

    init(
        localDataSource: LocalDataSource,
        screenTimeRulesService: ScreenTimeRulesService,
        screenTimeRulesRepository: ScreenTimeRulesRepository
    ) {
        self.localDataSource = localDataSource
        self.screenTimeRulesService = screenTimeRulesService
        self.screenTimeRulesRepository = screenTimeRulesRepository
    }

    // MARK: - Create

    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async {
        if let existing = pendingChange(for: rule.id) {
            try? localDataSource.deletePendingChange(existing)
        }

        guard let parsedType = PendingChangeType(rawValue: changeType) else {
            print("⚠️ [PendingChangeService] Unknown changeType '\(changeType)' — change not created")
            return
        }

        let change = PendingRuleChange(
            ruleId: rule.id,
            changeType: parsedType,
            pendingData: pendingData
        )
        try? localDataSource.insertPendingChange(change)
    }

    // MARK: - Cancel

    func cancelPendingChange(for ruleId: UUID) async {
        guard let change = pendingChange(for: ruleId) else { return }
        change.isCancelled = true
        try? localDataSource.savePendingChanges()
    }

    // MARK: - Apply Expired

    func applyExpiredChanges() async {
        let defaults = AppGroupConstants.sharedDefaults
        let lastKnownInterval = defaults?.double(forKey: AppGroupConstants.lastKnownDateKey) ?? 0
        let now = Date()

        if lastKnownInterval > 0 {
            let lastKnownDate = Date(timeIntervalSince1970: lastKnownInterval)
            let elapsed = now.timeIntervalSince(lastKnownDate)
            if elapsed > Self.clockJumpThreshold {
                logger.fault("Clock manipulation suspected: jumped \(Int(elapsed))s — skipping auto-apply")
                defaults?.set(now.timeIntervalSince1970, forKey: AppGroupConstants.lastKnownDateKey)
                return
            }
        }

        defaults?.set(now.timeIntervalSince1970, forKey: AppGroupConstants.lastKnownDateKey)

        let allChanges = (try? localDataSource.fetchPendingChanges()) ?? []
        let expired = allChanges.filter {
            !$0.isCancelled && !$0.isApplied && $0.appliesAt <= now
        }

        for change in expired {
            do {
                try await applyChange(change)
                change.isApplied = true
                try? localDataSource.savePendingChanges()
                schedulePendingChangeAppliedNotification(for: change.ruleId)
            } catch {
                print("⚠️ [PendingChangeService] Failed to apply change \(change.id) for rule \(change.ruleId): \(error)")
            }
        }
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
            print("⚠️ [PendingChangeService] Unknown changeType '\(change.changeType)' — skipping")
            return
        }

        switch type {
        case .edit:
            try await applyEdit(change)
        case .delete:
            try await applyDelete(ruleId: change.ruleId)
        case .disable:
            try await applyDelete(ruleId: change.ruleId)
        case .disableHardMode:
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

    private func applyFlagUpdate(ruleId: UUID, update: (inout ScreenTimeRule) -> Void) {
        guard var rule = screenTimeRulesRepository.getRule(id: ruleId) else {
            print("⚠️ [PendingChangeService] Rule \(ruleId) not found — skipping flag update")
            return
        }
        update(&rule)
        switch rule.type {
        case .appLimit:  screenTimeRulesRepository.setAppLimitRule(rule)
        case .timeLimit: screenTimeRulesRepository.setTimeLimitRule(rule)
        }
    }

    // MARK: - Private: Notification

    private func schedulePendingChangeAppliedNotification(for ruleId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "Deen First"
        content.body = "A scheduled rule change has been applied"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: AppGroupConstants.pendingChangeAppliedNotificationId(for: ruleId),
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("⚠️ [PendingChangeService] Failed to schedule applied notification for rule \(ruleId): \(error)")
            }
        }
    }
}
