import FamilyControls
import SwiftData
import XCTest

@testable import DeenFirst

/// Matches `PendingChangeServiceImpl.monotonicNow()` so tests can seed the
/// baseline using the same clock source the guard reads.
private func currentMonotonicNow() -> TimeInterval {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return TimeInterval(ts.tv_sec) + TimeInterval(ts.tv_nsec) / 1_000_000_000
}

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
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownMonotonicKey)
    }

    override func tearDown() async throws {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownDateKey)
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownMonotonicKey)
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

    // DF-041: creating a new pending change for the same rule must soft-cancel
    // the prior one (not hard-delete it). Both records must persist in the
    // store so the history is auditable; the prior record carries
    // isCancelled = true.
    func testCreatePendingChange_softCancelsPriorChange() async {
        let rule = makeRule()
        await service.createPendingChange(for: rule, changeType: "disableHardMode", pendingData: nil)
        let firstId = service.pendingChange(for: rule.id)?.id
        XCTAssertNotNil(firstId)

        await service.createPendingChange(for: rule, changeType: "disableLockEditing", pendingData: nil)

        let all = (try? localDataSource.fetchPendingChanges()) ?? []
        let forRule = all.filter { $0.ruleId == rule.id }
        XCTAssertEqual(forRule.count, 2, "Both prior and new records must persist")

        let prior = forRule.first { $0.id == firstId }
        XCTAssertNotNil(prior, "Prior record must still exist in the store")
        XCTAssertTrue(prior?.isCancelled ?? false, "Prior record must be soft-cancelled")

        let active = forRule.filter { !$0.isCancelled && !$0.isApplied }
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.changeType, "disableLockEditing")
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

    // DF-040: guard now compares wall-clock delta to monotonic-clock delta.
    // A tamper attempt looks like wall-clock advanced far more than monotonic.
    // Here we simulate that by seeding a recent monotonic baseline together
    // with a wall baseline far in the past — wallElapsed is large, monoElapsed
    // is near-zero, so the guard fires.
    func testApplyExpiredChanges_wallJumpWithoutMonotonicAdvance_skipsApply() async {
        let ruleId = UUID()
        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableLockEditing, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        // Wall clock baseline = 1h in the past → wallElapsed ≈ 3600s on apply.
        AppGroupConstants.sharedDefaults?.set(
            Date().addingTimeInterval(-3_600).timeIntervalSince1970,
            forKey: AppGroupConstants.lastKnownDateKey
        )
        // Monotonic baseline = "now" → monoElapsed ≈ 0s on apply.
        AppGroupConstants.sharedDefaults?.set(
            currentMonotonicNow(),
            forKey: AppGroupConstants.lastKnownMonotonicKey
        )

        await service.applyExpiredChanges()

        let all = try? localDataSource.fetchPendingChanges()
        XCTAssertFalse(all?.first?.isApplied ?? true, "Tamper (wall jumped, mono didn't) must skip apply")
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

    // DF-040: overnight sleep — wall clock advances many hours alongside
    // monotonic (device wasn't tampered, it just slept). Guard must allow
    // the apply to proceed.
    func testApplyExpiredChanges_overnightSleep_proceeds() async {
        let ruleId = UUID()
        var rule = makeRule(id: ruleId)
        rule.isLockEditingEnabled = true
        mockRulesRepository.rules[ruleId] = rule

        let pastDate = Date().addingTimeInterval(-90_000)
        let expiredChange = PendingRuleChange(
            ruleId: ruleId, changeType: .disableLockEditing, requestedAt: pastDate)
        try? localDataSource.insertPendingChange(expiredChange)

        // Simulate 8h proportional advance on both clocks.
        let eightHours: TimeInterval = 8 * 3600
        AppGroupConstants.sharedDefaults?.set(
            Date().addingTimeInterval(-eightHours).timeIntervalSince1970,
            forKey: AppGroupConstants.lastKnownDateKey
        )
        AppGroupConstants.sharedDefaults?.set(
            currentMonotonicNow() - eightHours,
            forKey: AppGroupConstants.lastKnownMonotonicKey
        )

        await service.applyExpiredChanges()

        let all = try? localDataSource.fetchPendingChanges()
        XCTAssertTrue(all?.first?.isApplied ?? false, "Proportional wall+mono advance (benign overnight sleep) should allow apply")
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
    var deactivatedIds: [UUID] = []
    func deactivateRule(id: UUID) async throws {
        deactivatedIds.append(id)
        if var rule = rulesById[id] {
            rule.isEnabled = false
            rulesById[id] = rule
        }
    }
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
    func isTemporarilyUnblocked(ruleId: UUID) -> Bool { false }
    func unblockRemainingSeconds(ruleId: UUID) -> Int? { nil }
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
