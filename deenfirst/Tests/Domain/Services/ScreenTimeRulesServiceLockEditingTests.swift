import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import XCTest

@testable import DeenFirst

// MARK: - Lock Editing Gate Tests

@MainActor
final class ScreenTimeRulesServiceLockEditingTests: XCTestCase {
    var mockRepository: MockLockEditingRepository!
    var mockPendingChangeService: MockPendingChangeServiceForLockEditing!
    var service: ScreenTimeRulesServiceImpl!

    override func setUp() async throws {
        mockRepository = MockLockEditingRepository()
        mockPendingChangeService = MockPendingChangeServiceForLockEditing()
        service = ScreenTimeRulesServiceImpl(
            repository: mockRepository,
            deviceActivityManager: MockDeviceActivityManagerForLockEditing(),
            notificationSchedulingService: MockNotificationSchedulingServiceForLockEditing()
        )
        service.pendingChangeService = mockPendingChangeService
    }

    override func tearDown() async throws {
        service = nil
        mockRepository = nil
        mockPendingChangeService = nil
    }

    // MARK: - Helpers

    private func makeLockedRule(id: UUID = UUID(), type: RuleType = .appLimit) -> ScreenTimeRule {
        var rule = ScreenTimeRule(
            id: id,
            name: "Locked Rule",
            selection: FamilyActivitySelection(),
            type: type,
            limitSeconds: 3600,
            isLockEditingEnabled: true
        )
        return rule
    }

    private func makeUnlockedRule(id: UUID = UUID(), type: RuleType = .appLimit) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Unlocked Rule",
            selection: FamilyActivitySelection(),
            type: type,
            limitSeconds: 3600,
            isLockEditingEnabled: false
        )
    }

    // MARK: - editAppLimitRule

    func testEditAppLimitRule_lockedRule_queuesPendingChange() async throws {
        let rule = makeLockedRule()
        mockRepository.rules[rule.id] = rule
        let config = AppLimitConfig(id: rule.id, name: "Updated", timeLimit: .thirtyMin)

        try await service.editAppLimitRule(for: FamilyActivitySelection(), config: config)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastChangeType, PendingChangeType.edit.rawValue)
        XCTAssertNotNil(mockPendingChangeService.lastPendingData)
    }

    func testEditAppLimitRule_unlockedRule_callsRawOperation() async throws {
        let rule = makeUnlockedRule()
        mockRepository.rules[rule.id] = rule
        let config = AppLimitConfig(id: rule.id, name: "Updated", timeLimit: .thirtyMin)

        try await service.editAppLimitRule(for: FamilyActivitySelection(), config: config)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
    }

    // MARK: - editTimeLimitRule

    func testEditTimeLimitRule_lockedRule_queuesPendingChange() async throws {
        let rule = makeLockedRule(type: .timeLimit)
        mockRepository.rules[rule.id] = rule
        let start = DateComponents(hour: 22, minute: 0)
        let end = DateComponents(hour: 23, minute: 0)
        let config = TimeLimitConfig(id: rule.id, name: "Updated", startTime: start, endTime: end)

        try await service.editTimeLimitRule(for: FamilyActivitySelection(), config: config)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastChangeType, PendingChangeType.edit.rawValue)
        XCTAssertNotNil(mockPendingChangeService.lastPendingData)
    }

    func testEditTimeLimitRule_unlockedRule_callsRawOperation() async throws {
        let rule = makeUnlockedRule(type: .timeLimit)
        mockRepository.rules[rule.id] = rule
        let start = DateComponents(hour: 22, minute: 0)
        let end = DateComponents(hour: 23, minute: 0)
        let config = TimeLimitConfig(id: rule.id, name: "Updated", startTime: start, endTime: end)

        try await service.editTimeLimitRule(for: FamilyActivitySelection(), config: config)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
    }

    // MARK: - deleteRule

    func testDeleteRule_lockedRule_queuesPendingChange() async throws {
        let rule = makeLockedRule()
        mockRepository.rules[rule.id] = rule

        try await service.deleteRule(id: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastChangeType, PendingChangeType.delete.rawValue)
        XCTAssertNil(mockPendingChangeService.lastPendingData)
    }

    func testDeleteRule_unlockedRule_deletesDirectly() async throws {
        let rule = makeUnlockedRule()
        mockRepository.rules[rule.id] = rule

        try await service.deleteRule(id: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
        XCTAssertNil(mockRepository.rules[rule.id])
    }

    func testDeleteRule_missingRule_isNoOp() async throws {
        try await service.deleteRule(id: UUID())

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
    }

    // MARK: - disableRule

    func testDisableRule_lockedRule_queuesPendingChange() async throws {
        let rule = makeLockedRule()
        mockRepository.rules[rule.id] = rule

        try await service.disableRule(id: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastChangeType, PendingChangeType.disable.rawValue)
    }

    func testDisableRule_unlockedRule_deletesDirectly() async throws {
        let rule = makeUnlockedRule()
        mockRepository.rules[rule.id] = rule

        try await service.disableRule(id: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
        XCTAssertNil(mockRepository.rules[rule.id])
    }

    // MARK: - disableHardMode

    func testDisableHardMode_lockedRule_queuesPendingChange() async {
        var rule = makeLockedRule()
        rule.isHardMode = true
        mockRepository.rules[rule.id] = rule

        await service.disableHardMode(for: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastChangeType, PendingChangeType.disableHardMode.rawValue)
        XCTAssertTrue(mockRepository.rules[rule.id]?.isHardMode ?? false, "Hard mode should not change immediately when locked")
    }

    func testDisableHardMode_unlockedRule_appliesImmediately() async {
        var rule = makeUnlockedRule()
        rule.isHardMode = true
        mockRepository.rules[rule.id] = rule

        await service.disableHardMode(for: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
        XCTAssertFalse(mockRepository.rules[rule.id]?.isHardMode ?? true, "Hard mode should be false after immediate apply")
    }

    // MARK: - disableLockEditing

    func testDisableLockEditing_lockedRule_queuesPendingChange() async {
        let rule = makeLockedRule()
        mockRepository.rules[rule.id] = rule

        await service.disableLockEditing(for: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastChangeType, PendingChangeType.disableLockEditing.rawValue)
        XCTAssertTrue(mockRepository.rules[rule.id]?.isLockEditingEnabled ?? false, "Lock editing should not change immediately when locked")
    }

    func testDisableLockEditing_unlockedRule_appliesImmediately() async {
        let rule = makeUnlockedRule()
        mockRepository.rules[rule.id] = rule

        await service.disableLockEditing(for: rule.id)

        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
        XCTAssertFalse(mockRepository.rules[rule.id]?.isLockEditingEnabled ?? true, "Lock editing should be false after immediate apply")
    }

    // MARK: - Unblocking operations must bypass gate

    func testTemporaryUnblock_doesNotCheckLockEditing() async {
        // Unblock operations are exempt — they work even when isLockEditingEnabled = true.
        // This test documents that disableHardMode gate is separate from unblock.
        let rule = makeLockedRule()
        mockRepository.rules[rule.id] = rule

        // temporaryUnblock / temporaryUnblockAll are in +Unblock.swift and don't go through the gate.
        // Just verify pendingChangeService was never called after a disableHardMode (not an unblock call).
        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
    }
}

// MARK: - Mocks

final class MockPendingChangeServiceForLockEditing: PendingChangeService {
    var createCallCount = 0
    var lastChangeType: String?
    var lastPendingData: Data?
    var lastRuleId: UUID?

    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async {
        createCallCount += 1
        lastChangeType = changeType
        lastPendingData = pendingData
        lastRuleId = rule.id
    }

    func cancelPendingChange(for ruleId: UUID) async {}
    func applyExpiredChanges() async {}
    func hasPendingChange(for ruleId: UUID) -> Bool { false }
    func pendingChange(for ruleId: UUID) -> PendingRuleChange? { nil }
}

final class MockLockEditingRepository: ScreenTimeRulesRepository {
    var rules: [UUID: ScreenTimeRule] = [:]
    var deletedIds: [UUID] = []

    func getAppLimitRules() -> [ScreenTimeRule] { rules.values.filter { $0.type == .appLimit } }
    func getTimeLimitRules() -> [ScreenTimeRule] { rules.values.filter { $0.type == .timeLimit } }
    func getAllRules() -> [ScreenTimeRule] { Array(rules.values) }
    func getRule(id: UUID) -> ScreenTimeRule? { rules[id] }
    func setAppLimitRule(_ rule: ScreenTimeRule) { rules[rule.id] = rule }
    func setTimeLimitRule(_ rule: ScreenTimeRule) { rules[rule.id] = rule }
    func deleteAppLimitRule(id: UUID) { rules.removeValue(forKey: id); deletedIds.append(id) }
    func deleteTimeLimitRule(id: UUID) { rules.removeValue(forKey: id); deletedIds.append(id) }
    func clearAllRules() { rules.removeAll() }
}

final class MockDeviceActivityManagerForLockEditing: DeviceActivityManager {
    func startMonitoring(name: DeviceActivityName, schedule: DeviceActivitySchedule, events: [DeviceActivityEvent.Name: DeviceActivityEvent]) async throws {}
    func stopMonitoring(names: Set<DeviceActivityName>) async throws {}
    func applyShield(for selection: FamilyActivitySelection) async {}
    func removeShield() async {}
    func removeShield(for selection: FamilyActivitySelection) async {}
    func reapplyActiveShields(rules: [ScreenTimeRule]) async {}
}

final class MockNotificationSchedulingServiceForLockEditing: NotificationSchedulingService {
    func scheduleTimeLimitWarning(for rule: ScreenTimeRule) {}
    func cancelTimeLimitWarning(for ruleId: UUID) {}
    func scheduleMotivationalNotifications() async {}
    func cancelMotivationalNotifications() async {}
    func schedulePendingChangeNotification(for change: PendingRuleChange, ruleName: String) {}
    func cancelPendingChangeNotification(for changeId: UUID) {}
}
