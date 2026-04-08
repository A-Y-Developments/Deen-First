import DeviceActivity
import FamilyControls
import ManagedSettings
import XCTest

@testable import DeenFirst

// MARK: - UnblockTier Tests

final class UnblockTierTests: XCTestCase {

    func testTier1_Minutes_Is5() {
        XCTAssertEqual(UnblockTier.tier1.minutes, 5)
    }

    func testTier2_Minutes_Is10() {
        XCTAssertEqual(UnblockTier.tier2.minutes, 10)
    }

    func testTier3_Minutes_Is15() {
        XCTAssertEqual(UnblockTier.tier3.minutes, 15)
    }
}

// MARK: - ReciteToUnblockViewModel Tier + Shorter-Wins Tests

@MainActor
final class ReciteToUnblockViewModelTests: XCTestCase {

    var mockService: MockScreenTimeRulesServiceForRecite!
    var testDefaults: UserDefaults!

    override func setUp() async throws {
        mockService = MockScreenTimeRulesServiceForRecite()
        let suiteName = "com.test.recite-\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        if let suiteName = testDefaults.suiteName {
            testDefaults.removePersistentDomain(forName: suiteName)
        }
        testDefaults = nil
        mockService = nil
    }

    // MARK: - Tier defaults

    func testDefaultTier_IsTier1() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.tier.minutes, 5)
    }

    func testUnblockDurationMinutes_ReflectsTier() {
        let vm = makeViewModel()
        vm.tier = .tier2
        XCTAssertEqual(vm.unblockDurationMinutes, 10)
    }

    // MARK: - Shorter-wins logic

    /// 8 min remain on current unblock. Tier 1 grants only 5 min — should NOT replace.
    func testHandlePass_SkipsUnblock_WhenExistingUnblockHasMoreTime() async {
        let ruleId = UUID()
        let rule = makeTimeLimitRule(id: ruleId)
        mockService.ruleToReturn = rule

        let expiryKey = AppGroupConstants.unblockExpiryKey(for: ruleId)
        let eightMinExpiry = Date().addingTimeInterval(8 * 60).timeIntervalSince1970
        testDefaults.set(eightMinExpiry, forKey: expiryKey)

        let vm = makeViewModel()
        vm.tier = .tier1  // 5 min
        vm.targetRuleId = ruleId

        await vm.handlePass()

        XCTAssertFalse(mockService.temporaryUnblockCalled, "Should not replace an 8-min unblock with a 5-min grant")
    }

    /// No existing unblock timer. Tier 1 should grant 5 min.
    func testHandlePass_Unblocks_WhenNoExistingTimer() async {
        let ruleId = UUID()
        let rule = makeTimeLimitRule(id: ruleId)
        mockService.ruleToReturn = rule

        let vm = makeViewModel()
        vm.tier = .tier1
        vm.targetRuleId = ruleId

        await vm.handlePass()

        XCTAssertTrue(mockService.temporaryUnblockCalled)
        XCTAssertEqual(mockService.unblockMinutes, 5)
    }

    /// 3 min remain, Tier 1 grants 5 — longer wins, should replace.
    func testHandlePass_Unblocks_WhenNewGrantExceedsRemaining() async {
        let ruleId = UUID()
        let rule = makeTimeLimitRule(id: ruleId)
        mockService.ruleToReturn = rule

        let expiryKey = AppGroupConstants.unblockExpiryKey(for: ruleId)
        let threeMinExpiry = Date().addingTimeInterval(3 * 60).timeIntervalSince1970
        testDefaults.set(threeMinExpiry, forKey: expiryKey)

        let vm = makeViewModel()
        vm.tier = .tier1  // 5 min > 3 min remaining
        vm.targetRuleId = ruleId

        await vm.handlePass()

        XCTAssertTrue(mockService.temporaryUnblockCalled)
        XCTAssertEqual(mockService.unblockMinutes, 5)
    }

    /// Rule not found — should not call unblock.
    func testHandlePass_SkipsUnblock_WhenRuleNotFound() async {
        mockService.ruleToReturn = nil
        let vm = makeViewModel()
        vm.tier = .tier1
        vm.targetRuleId = UUID()

        await vm.handlePass()

        XCTAssertFalse(mockService.temporaryUnblockCalled)
    }

    // MARK: - Helpers

    private func makeViewModel() -> ReciteToUnblockViewModel {
        ReciteToUnblockViewModel(
            quranPreferences: MockQuranPreferencesServiceForRecite(),
            screenTimeService: mockService,
            sharedDefaults: testDefaults
        )
    }

    /// A timeLimit rule active all day so isCurrentlyInBlockingPeriod returns true during tests.
    private func makeTimeLimitRule(id: UUID) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Test Rule",
            selection: FamilyActivitySelection(),
            type: .timeLimit,
            startTime: DateComponents(hour: 0, minute: 0),
            endTime: DateComponents(hour: 23, minute: 59)
        )
    }
}

// MARK: - Mocks

final class MockScreenTimeRulesServiceForRecite: ScreenTimeRulesService {
    var ruleToReturn: ScreenTimeRule?
    var temporaryUnblockCalled = false
    var unblockMinutes: Int?

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
    func temporaryUnblock(minutes: Int, ruleId: UUID) async {
        temporaryUnblockCalled = true
        unblockMinutes = minutes
    }
    func temporaryUnblockAll(minutes: Int) async {}
    func reblockIfExpired(ruleId: UUID) async {}
    func reblockAllExpired() async {}
    func activateEmergencyUnblock() async {}
    func deactivateEmergencyUnblock() async {}
    func reblockEmergencyIfExpired() async {}
    var isEmergencyUnblockActive: Bool { false }
    func emergencyUnblockQuotaRemaining() -> Int { 0 }
}

final class MockQuranPreferencesServiceForRecite: QuranPreferencesService {
    var selectedTranslation: TranslationLanguage = .english
    var selectedReciterId: Int = 1
    func getTranslation(for ayah: Ayah) -> String { "" }
    func getReciterAudio(for ayah: Ayah) -> ReciterAudio? { nil }
}
