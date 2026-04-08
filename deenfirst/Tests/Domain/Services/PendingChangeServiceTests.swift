import FamilyControls
import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class PendingChangeServiceTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var mockRulesService: MockScreenTimeRulesServiceForPending!
    var mockRulesRepository: MockScreenTimeRulesRepositoryForPending!
    var mockNotificationService: MockNotificationSchedulingService!
    var service: PendingChangeServiceImpl!

    override func setUp() async throws {
        let schema = Schema([PendingRuleChange.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        mockRulesService = MockScreenTimeRulesServiceForPending()
        mockRulesRepository = MockScreenTimeRulesRepositoryForPending()
        mockNotificationService = MockNotificationSchedulingService()
        service = PendingChangeServiceImpl(
            localDataSource: localDataSource,
            screenTimeRulesService: mockRulesService,
            screenTimeRulesRepository: mockRulesRepository,
            notificationSchedulingService: mockNotificationService
        )
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownDateKey)
    }

    override func tearDown() async throws {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownDateKey)
        container = nil
        localDataSource = nil
        mockRulesService = nil
        mockRulesRepository = nil
        mockNotificationService = nil
        service = nil
    }

    // MARK: - createPendingChange

    func testCreatePendingChange_setsAppliesAtRequestedAtPlus24Hours() async {
        let rule = makeRule()
        let before = Date()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)
        let after = Date()

        guard let change = service.pendingChange(for: rule.id) else {
            XCTFail("Expected pending change")
            return
        }

        XCTAssertGreaterThanOrEqual(change.requestedAt, before)
        XCTAssertLessThanOrEqual(change.requestedAt, after)

        let delta = change.appliesAt.timeIntervalSince(change.requestedAt)
        XCTAssertEqual(delta, 86_400, accuracy: 0.001, "appliesAt should equal requestedAt + 86400 seconds")
    }

    func testCreatePendingChange_createsChange() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        XCTAssertTrue(service.hasPendingChange(for: rule.id))
        let change = service.pendingChange(for: rule.id)
        XCTAssertNotNil(change)
        XCTAssertEqual(change?.changeType, "disableLockEditing")
        XCTAssertEqual(change?.ruleId, rule.id)
        XCTAssertFalse(change?.isCancelled ?? true)
        XCTAssertFalse(change?.isApplied ?? true)
    }

    func testCreatePendingChange_ignoresUnknownChangeType() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "unknownType", pendingData: nil)

        XCTAssertFalse(service.hasPendingChange(for: rule.id))
    }

    func testCreatePendingChange_replacesExistingForSameRule() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableHardMode", pendingData: nil)
        let firstChange = service.pendingChange(for: rule.id)
        let firstAppliesAt = firstChange?.appliesAt

        // Brief pause so new requestedAt is measurably different
        try? await Task.sleep(nanoseconds: 10_000_000)

        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        let all = try? localDataSource.fetchPendingChanges()
        let active = all?.filter { !$0.isCancelled && !$0.isApplied && $0.ruleId == rule.id }

        XCTAssertEqual(active?.count, 1)
        XCTAssertEqual(active?.first?.changeType, "disableLockEditing")

        if let newAppliesAt = active?.first?.appliesAt, let oldAppliesAt = firstAppliesAt {
            XCTAssertGreaterThanOrEqual(newAppliesAt, oldAppliesAt)
        }
    }

    // MARK: - cancelPendingChange

    func testCancelPendingChange_marksCancelled() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        XCTAssertTrue(service.hasPendingChange(for: rule.id))

        await service.cancelPendingChange(for: rule.id)

        XCTAssertFalse(service.hasPendingChange(for: rule.id))

        let all = try? localDataSource.fetchPendingChanges()
        XCTAssertTrue(all?.first?.isCancelled ?? false)
    }

    func testCancelPendingChange_noOpWhenNoneExists() async {
        let ruleId = UUID()
        await service.cancelPendingChange(for: ruleId)
        // Should not crash
        XCTAssertFalse(service.hasPendingChange(for: ruleId))
    }

    // MARK: - hasPendingChange / pendingChange

    func testHasPendingChange_returnsFalseWhenNone() {
        XCTAssertFalse(service.hasPendingChange(for: UUID()))
        XCTAssertNil(service.pendingChange(for: UUID()))
    }

    func testHasPendingChange_returnsFalseForAppliedChange() async {
        let ruleId = UUID()
        let change = PendingRuleChange(ruleId: ruleId, changeType: .disableLockEditing)
        change.isApplied = true
        try? localDataSource.insertPendingChange(change)

        XCTAssertFalse(service.hasPendingChange(for: ruleId))
    }

    func testHasPendingChange_returnsFalseForCancelledChange() async {
        let ruleId = UUID()
        let change = PendingRuleChange(ruleId: ruleId, changeType: .disableLockEditing)
        change.isCancelled = true
        try? localDataSource.insertPendingChange(change)

        XCTAssertFalse(service.hasPendingChange(for: ruleId))
    }

    // MARK: - applyExpiredChanges — clock jump

    func testApplyExpiredChanges_clockJumpSkipsApply() async {
        let ruleId = UUID()
        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableLockEditing, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        let clockJumpDate = Date().addingTimeInterval(-8_000)
        AppGroupConstants.sharedDefaults?.set(
            clockJumpDate.timeIntervalSince1970,
            forKey: AppGroupConstants.lastKnownDateKey
        )

        await service.applyExpiredChanges()

        let all = try? localDataSource.fetchPendingChanges()
        XCTAssertFalse(all?.first?.isApplied ?? true, "Clock jump should prevent apply")
        XCTAssertEqual(mockRulesRepository.setAppLimitCallCount + mockRulesRepository.setTimeLimitCallCount, 0)
    }

    // MARK: - applyExpiredChanges — normal flow

    func testApplyExpiredChanges_skipsNonExpiredChanges() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        await service.applyExpiredChanges()

        let change = service.pendingChange(for: rule.id)
        XCTAssertFalse(change?.isApplied ?? true, "Future change should not be applied")
    }

    func testApplyExpiredChanges_appliesExpiredDisableLockEditingChange() async {
        let ruleId = UUID()
        var rule = makeRule(id: ruleId)
        rule.isLockEditingEnabled = true
        mockRulesRepository.rules[ruleId] = rule

        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableLockEditing, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        await service.applyExpiredChanges()

        let all = try? localDataSource.fetchPendingChanges()
        XCTAssertTrue(all?.first?.isApplied ?? false, "Expired change should be marked applied")

        let updatedRule = mockRulesRepository.rules[ruleId]
        XCTAssertFalse(updatedRule?.isLockEditingEnabled ?? true, "isLockEditingEnabled should be false")
    }

    func testApplyExpiredChanges_appliesExpiredDisableHardModeChange() async {
        let ruleId = UUID()
        var rule = makeRule(id: ruleId)
        rule.isHardMode = true
        mockRulesRepository.rules[ruleId] = rule

        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableHardMode, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        await service.applyExpiredChanges()

        let updatedRule = mockRulesRepository.rules[ruleId]
        XCTAssertFalse(updatedRule?.isHardMode ?? true, "isHardMode should be false")
    }

    func testApplyExpiredChanges_appliesDeleteChange() async {
        let ruleId = UUID()
        let rule = makeRule(id: ruleId, type: .appLimit)
        mockRulesService.rulesById[ruleId] = rule

        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .delete, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        await service.applyExpiredChanges()

        XCTAssertTrue(mockRulesService.deletedAppLimitIds.contains(ruleId))
    }

    func testApplyExpiredChanges_normalProgressionUnderTwoHoursProceeds() async {
        let ruleId = UUID()
        var rule = makeRule(id: ruleId)
        rule.isLockEditingEnabled = true
        mockRulesRepository.rules[ruleId] = rule

        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableLockEditing, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        // lastKnownDate 1 hour ago — well within the 2hr threshold
        let oneHourAgo = Date().addingTimeInterval(-3_600)
        AppGroupConstants.sharedDefaults?.set(
            oneHourAgo.timeIntervalSince1970,
            forKey: AppGroupConstants.lastKnownDateKey
        )

        await service.applyExpiredChanges()

        let all = try? localDataSource.fetchPendingChanges()
        XCTAssertTrue(all?.first?.isApplied ?? false, "Normal time progression should allow apply")
    }

    func testApplyExpiredChanges_updatesLastKnownDateAfterRun() async {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownDateKey)

        await service.applyExpiredChanges()

        let stored = AppGroupConstants.sharedDefaults?.double(forKey: AppGroupConstants.lastKnownDateKey) ?? 0
        XCTAssertGreaterThan(stored, 0, "lastKnownDate should be updated after applyExpiredChanges")
    }

    // MARK: - Notifications

    func testCreatePendingChange_schedulesNotification() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        XCTAssertEqual(mockNotificationService.scheduledChangeIds.count, 1)
        XCTAssertEqual(mockNotificationService.scheduledRuleNames.first, rule.name)
    }

    func testCreatePendingChange_replacesExisting_cancelsOldNotification() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)
        guard let firstChange = service.pendingChange(for: rule.id) else {
            XCTFail("Expected first pending change")
            return
        }

        await service.createPendingChange(for: rule, changeType: "disableHardMode", pendingData: nil)

        XCTAssertTrue(mockNotificationService.cancelledChangeIds.contains(firstChange.id))
        XCTAssertEqual(mockNotificationService.scheduledChangeIds.count, 2)
    }

    func testCreatePendingChange_unknownType_doesNotScheduleNotification() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "unknownType", pendingData: nil)

        XCTAssertTrue(mockNotificationService.scheduledChangeIds.isEmpty)
    }

    func testCancelPendingChange_cancelsNotification() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        guard let change = service.pendingChange(for: rule.id) else {
            XCTFail("Expected pending change")
            return
        }

        await service.cancelPendingChange(for: rule.id)

        XCTAssertTrue(mockNotificationService.cancelledChangeIds.contains(change.id))
    }

    func testApplyExpiredChanges_cancelsScheduledNotification() async {
        let ruleId = UUID()
        var rule = makeRule(id: ruleId)
        rule.isLockEditingEnabled = true
        mockRulesRepository.rules[ruleId] = rule

        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableLockEditing, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        await service.applyExpiredChanges()

        XCTAssertTrue(mockNotificationService.cancelledChangeIds.contains(expiredChange.id))
    }

    // MARK: - Helpers

    private func makeRule(id: UUID = UUID(), type: RuleType = .appLimit) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Test Rule",
            selection: FamilyActivitySelection(),
            type: type,
            limitSeconds: 3600
        )
    }
}

// MARK: - Mocks

final class MockScreenTimeRulesServiceForPending: ScreenTimeRulesService {
    var rulesById: [UUID: ScreenTimeRule] = [:]
    var deletedAppLimitIds: [UUID] = []
    var deletedTimeLimitIds: [UUID] = []

    func requestAuthorization() async throws {}
    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func deleteAppLimit(id: UUID) async throws { deletedAppLimitIds.append(id) }
    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteTimeLimit(id: UUID) async throws { deletedTimeLimitIds.append(id) }
    func getAllRules() -> [ScreenTimeRule] { Array(rulesById.values) }
    func getAppLimitRules() -> [ScreenTimeRule] { getAllRules().filter { $0.type == .appLimit } }
    func getTimeLimitRules() -> [ScreenTimeRule] { getAllRules().filter { $0.type == .timeLimit } }
    func getRule(id: UUID) -> ScreenTimeRule? { rulesById[id] }
    func reapplyActiveShields() async {}
    func applySessionShield(for selection: FamilyActivitySelection) async {}
    func removeSessionShield() async {}
    func pauseAllRules() async {}
    func deleteAllRules() async throws {}
    func temporaryUnblock(minutes: Int, ruleId: UUID) async {}
    func temporaryUnblockAll(minutes: Int) async {}
    func reblockIfExpired(ruleId: UUID) async {}
    func reblockAllExpired() async {}
    func activateEmergencyUnblock() async {}
    func deactivateEmergencyUnblock() async {}
    func reblockEmergencyIfExpired() async {}
    var isEmergencyUnblockActive: Bool { false }
    func emergencyUnblockQuotaRemaining() -> Int { 0 }
    func editAppLimitRule(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func editTimeLimitRule(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteRule(id: UUID) async throws {}
    func disableRule(id: UUID) async throws {}
    func disableHardMode(for ruleId: UUID) async {}
    func disableLockEditing(for ruleId: UUID) async {}
}

final class MockNotificationSchedulingService: NotificationSchedulingService {
    var scheduledChangeIds: [UUID] = []
    var scheduledRuleNames: [String] = []
    var cancelledChangeIds: [UUID] = []

    func scheduleTimeLimitWarning(for rule: ScreenTimeRule) {}
    func cancelTimeLimitWarning(for ruleId: UUID) {}
    func scheduleMotivationalNotifications() async {}
    func cancelMotivationalNotifications() async {}

    func schedulePendingChangeNotification(for change: PendingRuleChange, ruleName: String) {
        scheduledChangeIds.append(change.id)
        scheduledRuleNames.append(ruleName)
    }

    func cancelPendingChangeNotification(for changeId: UUID) {
        cancelledChangeIds.append(changeId)
    }
}

final class MockScreenTimeRulesRepositoryForPending: ScreenTimeRulesRepository {
    var rules: [UUID: ScreenTimeRule] = [:]
    var setAppLimitCallCount = 0
    var setTimeLimitCallCount = 0

    func getAppLimitRules() -> [ScreenTimeRule] { rules.values.filter { $0.type == .appLimit } }
    func getTimeLimitRules() -> [ScreenTimeRule] { rules.values.filter { $0.type == .timeLimit } }
    func getAllRules() -> [ScreenTimeRule] { Array(rules.values) }
    func setAppLimitRule(_ rule: ScreenTimeRule) { rules[rule.id] = rule; setAppLimitCallCount += 1 }
    func setTimeLimitRule(_ rule: ScreenTimeRule) { rules[rule.id] = rule; setTimeLimitCallCount += 1 }
    func deleteAppLimitRule(id: UUID) { rules.removeValue(forKey: id) }
    func deleteTimeLimitRule(id: UUID) { rules.removeValue(forKey: id) }
    func getRule(id: UUID) -> ScreenTimeRule? { rules[id] }
    func clearAllRules() { rules.removeAll() }
}
