import FamilyControls
import XCTest

@testable import DeenFirst

@MainActor
final class BlockingTabViewModelTests: XCTestCase {
    var viewModel: BlockingTabViewModel!
    var mockScreenTimeService: MockScreenTimeRulesServiceForBlocking!
    var mockPendingChangeService: MockPendingChangeServiceForBlocking!

    override func setUp() async throws {
        mockScreenTimeService = MockScreenTimeRulesServiceForBlocking()
        mockPendingChangeService = MockPendingChangeServiceForBlocking()
        viewModel = BlockingTabViewModel(
            screenTimeRulesService: mockScreenTimeService,
            pendingChangeService: mockPendingChangeService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockScreenTimeService = nil
        mockPendingChangeService = nil
    }

    // MARK: - hasPendingChange

    func testHasPendingChange_ReturnsTrueWhenServiceReturnsTrue() {
        let ruleId = UUID()
        mockPendingChangeService.pendingRuleIds.insert(ruleId)

        XCTAssertTrue(viewModel.hasPendingChange(for: ruleId))
    }

    func testHasPendingChange_ReturnsFalseWhenServiceReturnsFalse() {
        let ruleId = UUID()

        XCTAssertFalse(viewModel.hasPendingChange(for: ruleId))
    }

    func testHasPendingChange_ReturnsFalseForUnknownRule() {
        let known = UUID()
        let unknown = UUID()
        mockPendingChangeService.pendingRuleIds.insert(known)

        XCTAssertFalse(viewModel.hasPendingChange(for: unknown))
    }
}

// MARK: - Mocks

final class MockScreenTimeRulesServiceForBlocking: ScreenTimeRulesService {
    func requestAuthorization() async throws {}
    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func deleteAppLimit(id: UUID) async throws {}
    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteTimeLimit(id: UUID) async throws {}
    func getAllRules() -> [ScreenTimeRule] { [] }
    func getAppLimitRules() -> [ScreenTimeRule] { [] }
    func getTimeLimitRules() -> [ScreenTimeRule] { [] }
    func getRule(id: UUID) -> ScreenTimeRule? { nil }
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
}

final class MockPendingChangeServiceForBlocking: PendingChangeService {
    var pendingRuleIds: Set<UUID> = []

    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async {}
    func cancelPendingChange(for ruleId: UUID) async {}
    func applyExpiredChanges() async {}

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingRuleIds.contains(ruleId)
    }

    func pendingChange(for ruleId: UUID) -> PendingRuleChange? { nil }
}
