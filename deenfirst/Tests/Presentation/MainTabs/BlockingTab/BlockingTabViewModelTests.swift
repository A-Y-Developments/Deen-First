import FamilyControls
import XCTest

@testable import DeenFirst

@MainActor
final class BlockingTabViewModelTests: XCTestCase {
    var viewModel: BlockingTabViewModel!
    var mockRulesService: MockRulesServiceForBlocking!
    var mockPendingChangeService: MockPendingChangeServiceForBlocking!

    override func setUp() async throws {
        mockRulesService = MockRulesServiceForBlocking()
        mockPendingChangeService = MockPendingChangeServiceForBlocking()
        viewModel = BlockingTabViewModel(
            screenTimeRulesService: mockRulesService,
            pendingChangeService: mockPendingChangeService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockRulesService = nil
        mockPendingChangeService = nil
    }

    // MARK: - hasPendingChange

    func testHasPendingChange_ReturnsTrueWhenServiceReturnsTrue() {
        let ruleId = UUID()
        let change = PendingRuleChange(ruleId: ruleId, changeType: .delete)
        mockPendingChangeService.pendingChanges[ruleId] = change

        XCTAssertTrue(viewModel.hasPendingChange(for: ruleId))
    }

    func testHasPendingChange_ReturnsFalseWhenServiceReturnsFalse() {
        let ruleId = UUID()

        XCTAssertFalse(viewModel.hasPendingChange(for: ruleId))
    }

    func testHasPendingChange_ReturnsFalseForUnknownRule() {
        let known = UUID()
        let unknown = UUID()
        let change = PendingRuleChange(ruleId: known, changeType: .delete)
        mockPendingChangeService.pendingChanges[known] = change

        XCTAssertFalse(viewModel.hasPendingChange(for: unknown))
    }

    // MARK: - attemptEdit

    func testAttemptEdit_unlockedRule_returnsTrue() {
        let rule = makeRule(locked: false)
        XCTAssertTrue(viewModel.attemptEdit(rule))
        XCTAssertNil(viewModel.pendingChangeSheetRule)
    }

    func testAttemptEdit_lockedRule_returnsFalse() {
        let rule = makeRule(locked: true)
        XCTAssertFalse(viewModel.attemptEdit(rule))
    }

    func testAttemptEdit_lockedRule_setsSheetRule() {
        let rule = makeRule(locked: true)
        _ = viewModel.attemptEdit(rule)
        XCTAssertEqual(viewModel.pendingChangeSheetRule?.id, rule.id)
    }

    func testAttemptEdit_lockedRule_setsTypeToEdit() {
        let rule = makeRule(locked: true)
        _ = viewModel.attemptEdit(rule)
        XCTAssertEqual(viewModel.pendingChangeSheetType, .edit)
    }

    // MARK: - attemptDelete

    func testAttemptDelete_unlockedRule_callsDeleteService() async {
        let rule = makeRule(locked: false, type: .appLimit)
        mockRulesService.rules[rule.id] = rule
        await viewModel.attemptDelete(rule)
        XCTAssertTrue(mockRulesService.deletedRuleIds.contains(rule.id))
    }

    func testAttemptDelete_lockedRule_setsSheetRule() async {
        let rule = makeRule(locked: true)
        await viewModel.attemptDelete(rule)
        XCTAssertEqual(viewModel.pendingChangeSheetRule?.id, rule.id)
    }

    func testAttemptDelete_lockedRule_setsTypeToDelete() async {
        let rule = makeRule(locked: true)
        await viewModel.attemptDelete(rule)
        XCTAssertEqual(viewModel.pendingChangeSheetType, .delete)
    }

    func testAttemptDelete_lockedRule_doesNotCallDeleteService() async {
        let rule = makeRule(locked: true)
        await viewModel.attemptDelete(rule)
        XCTAssertFalse(mockRulesService.deletedRuleIds.contains(rule.id))
    }

    // MARK: - confirmPendingChange

    func testConfirmPendingChange_callsServiceCreate() async {
        let rule = makeRule(locked: true)
        viewModel.pendingChangeSheetRule = rule
        viewModel.pendingChangeSheetType = .delete
        await viewModel.confirmPendingChange()
        XCTAssertEqual(mockPendingChangeService.createCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastCreatedChangeType, "delete")
    }

    func testConfirmPendingChange_clearsSheetRule() async {
        let rule = makeRule(locked: true)
        viewModel.pendingChangeSheetRule = rule
        await viewModel.confirmPendingChange()
        XCTAssertNil(viewModel.pendingChangeSheetRule)
    }

    func testConfirmPendingChange_noopWhenSheetRuleNil() async {
        viewModel.pendingChangeSheetRule = nil
        await viewModel.confirmPendingChange()
        XCTAssertEqual(mockPendingChangeService.createCallCount, 0)
    }

    // MARK: - cancelExistingPendingChange

    func testCancelExistingPendingChange_callsServiceCancel() async {
        let rule = makeRule(locked: true)
        viewModel.pendingChangeSheetRule = rule
        await viewModel.cancelExistingPendingChange()
        XCTAssertEqual(mockPendingChangeService.cancelCallCount, 1)
        XCTAssertEqual(mockPendingChangeService.lastCancelledRuleId, rule.id)
    }

    func testCancelExistingPendingChange_clearsSheetRule() async {
        let rule = makeRule(locked: true)
        viewModel.pendingChangeSheetRule = rule
        await viewModel.cancelExistingPendingChange()
        XCTAssertNil(viewModel.pendingChangeSheetRule)
    }

    // MARK: - existingPendingChange

    func testExistingPendingChange_delegatesToService() {
        let ruleId = UUID()
        let change = PendingRuleChange(ruleId: ruleId, changeType: .delete)
        mockPendingChangeService.pendingChanges[ruleId] = change
        let result = viewModel.existingPendingChange(for: ruleId)
        XCTAssertEqual(result?.ruleId, ruleId)
    }

    func testExistingPendingChange_returnsNilWhenNone() {
        XCTAssertNil(viewModel.existingPendingChange(for: UUID()))
    }

    // MARK: - Helpers

    private func makeRule(
        id: UUID = UUID(),
        locked: Bool = false,
        type: RuleType = .appLimit
    ) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Test Rule",
            selection: FamilyActivitySelection(),
            type: type,
            limitSeconds: 3600,
            isLockEditingEnabled: locked
        )
    }
}

// MARK: - Mocks

final class MockRulesServiceForBlocking: ScreenTimeRulesService {
    var rules: [UUID: ScreenTimeRule] = [:]
    var deletedRuleIds: [UUID] = []

    func requestAuthorization() async throws {}
    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func deleteAppLimit(id: UUID) async throws { deletedRuleIds.append(id) }
    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteTimeLimit(id: UUID) async throws { deletedRuleIds.append(id) }
    func deactivateRule(id: UUID) async throws { deletedRuleIds.append(id) }
    func getAllRules() -> [ScreenTimeRule] { Array(rules.values) }
    func getAppLimitRules() -> [ScreenTimeRule] { getAllRules().filter { $0.type == .appLimit } }
    func getTimeLimitRules() -> [ScreenTimeRule] { getAllRules().filter { $0.type == .timeLimit } }
    func getRule(id: UUID) -> ScreenTimeRule? { rules[id] }
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
    func deleteRule(id: UUID) async throws { deletedRuleIds.append(id) }
    func disableRule(id: UUID) async throws {}
    func disableHardMode(for ruleId: UUID) async {}
    func disableLockEditing(for ruleId: UUID) async {}
}

final class MockPendingChangeServiceForBlocking: PendingChangeService {
    var pendingChanges: [UUID: PendingRuleChange] = [:]
    var createCallCount = 0
    var cancelCallCount = 0
    var lastCreatedChangeType: String?
    var lastCancelledRuleId: UUID?

    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async {
        createCallCount += 1
        lastCreatedChangeType = changeType
        if let type = PendingChangeType(rawValue: changeType) {
            pendingChanges[rule.id] = PendingRuleChange(ruleId: rule.id, changeType: type, pendingData: pendingData)
        }
    }

    func cancelPendingChange(for ruleId: UUID) async {
        cancelCallCount += 1
        lastCancelledRuleId = ruleId
        pendingChanges.removeValue(forKey: ruleId)
    }

    func applyExpiredChanges() async {}

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingChanges[ruleId] != nil
    }

    func pendingChange(for ruleId: UUID) -> PendingRuleChange? {
        pendingChanges[ruleId]
    }

    func applyFlagUpdate(ruleId: UUID, update: @Sendable (inout ScreenTimeRule) -> Void) {}
}
