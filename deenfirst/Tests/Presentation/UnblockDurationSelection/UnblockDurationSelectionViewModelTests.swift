import DeviceActivity
import FamilyControls
import ManagedSettings
import XCTest

@testable import DeenFirst

@MainActor
final class UnblockDurationSelectionViewModelTests: XCTestCase {
    var viewModel: UnblockDurationSelectionViewModel!
    var mockService: MockScreenTimeRulesServiceForDurationSelection!

    override func setUp() async throws {
        mockService = MockScreenTimeRulesServiceForDurationSelection()
        viewModel = UnblockDurationSelectionViewModel(screenTimeRulesService: mockService)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
    }

    func testInitialState_RuleNameIsEmpty() {
        XCTAssertEqual(viewModel.ruleName, "")
    }

    func testInitialState_IsHardModeIsFalse() {
        XCTAssertFalse(viewModel.isHardMode)
    }

    func testLoadRule_SetsRuleName_WhenRuleExists() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeRule(id: ruleId, name: "Instagram", isHardMode: false)

        viewModel.loadRule(ruleId: ruleId)

        XCTAssertEqual(viewModel.ruleName, "Instagram")
    }

    func testLoadRule_SetsIsHardModeTrue_WhenRuleHasHardMode() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeRule(id: ruleId, name: "TikTok", isHardMode: true)

        viewModel.loadRule(ruleId: ruleId)

        XCTAssertTrue(viewModel.isHardMode)
    }

    func testLoadRule_SetsIsHardModeFalse_WhenRuleIsNormalMode() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeRule(id: ruleId, name: "Twitter", isHardMode: false)

        viewModel.loadRule(ruleId: ruleId)

        XCTAssertFalse(viewModel.isHardMode)
    }

    func testLoadRule_LeavesDefaults_WhenRuleNotFound() {
        let ruleId = UUID()
        mockService.ruleToReturn = nil

        viewModel.loadRule(ruleId: ruleId)

        XCTAssertEqual(viewModel.ruleName, "")
        XCTAssertFalse(viewModel.isHardMode)
    }

    // MARK: - Helpers

    private func makeRule(id: UUID, name: String, isHardMode: Bool) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: name,
            selection: FamilyActivitySelection(),
            type: .appLimit,
            isHardMode: isHardMode
        )
    }
}

// MARK: - Mock

class MockScreenTimeRulesServiceForDurationSelection: ScreenTimeRulesService {
    var ruleToReturn: ScreenTimeRule?

    func getRule(id: UUID) -> ScreenTimeRule? { ruleToReturn }
    func getAllRules() -> [ScreenTimeRule] { [] }
    func getAppLimitRules() -> [ScreenTimeRule] { [] }
    func getTimeLimitRules() -> [ScreenTimeRule] { [] }
    func requestAuthorization() async throws {}
    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func deleteAppLimit(id: UUID) async throws {}
    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteTimeLimit(id: UUID) async throws {}
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
