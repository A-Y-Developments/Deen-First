import DeviceActivity
import FamilyControls
import ManagedSettings
import XCTest

@testable import DeenFirst

// MARK: - Tiered Unblock Integration Tests (DF-41)
//
// Drives the full ReciteToUnblockViewModel state machine through Tier 1 / Tier 2
// scenarios via the `processRecitationOutcome(passed:score:)` test seam.
// Tier 3 (timer-based) is covered in ActiveSessionViewModelTieredUnblockTests.

@MainActor
final class TieredUnblockIntegrationTests: XCTestCase {

    var mockService: MockScreenTimeRulesServiceForRecite!
    var testDefaults: UserDefaults!
    var testDefaultsSuiteName: String!
    private var nudgeSuiteNames: [String] = []

    override func setUp() async throws {
        mockService = MockScreenTimeRulesServiceForRecite()
        testDefaultsSuiteName = "com.test.tiered-\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testDefaultsSuiteName)
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: testDefaultsSuiteName)
        testDefaults = nil
        testDefaultsSuiteName = nil
        for suite in nudgeSuiteNames {
            UserDefaults().removePersistentDomain(forName: suite)
        }
        nudgeSuiteNames = []
        mockService = nil
    }

    // MARK: - Tier 1 scenarios

    /// Tier 1 — Pass: score >= 70% → 5-min unblock granted.
    func testTier1_Pass_Grants5MinUnblock() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let vm = makeViewModel()
        vm.tier = .tier1
        vm.targetRuleId = ruleId
        primeAyahSequence(vm, count: 1)

        await vm.processRecitationOutcome(passed: true, score: 80)

        XCTAssertEqual(vm.state, .result(passed: true, score: 80))
        XCTAssertTrue(mockService.temporaryUnblockCalled)
        XCTAssertEqual(mockService.unblockMinutes, 5)
    }

    /// Tier 1 — Fail: score < 70% → no unblock, retry offered.
    func testTier1_Fail_NoUnblockRetryOffered() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let vm = makeViewModel()
        vm.tier = .tier1
        vm.targetRuleId = ruleId
        primeAyahSequence(vm, count: 1)

        await vm.processRecitationOutcome(passed: false, score: 50)

        XCTAssertEqual(vm.state, .result(passed: false, score: 50))
        XCTAssertFalse(mockService.temporaryUnblockCalled)
        XCTAssertEqual(vm.failureCountForCurrentAyah, 1)

        // Retry resets transcript and state without changing position
        vm.transcript = "previous"
        vm.retry()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.transcript, "")
        XCTAssertEqual(vm.currentAyahIndex, 0)
    }

    /// Tier 1 — Shorter-wins: 8 min remaining > 5 min new grant → don't replace.
    func testTier1_ShorterWins_DoesNotReplaceLongerActiveUnblock() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let expiryKey = AppGroupConstants.unblockExpiryKey(for: ruleId)
        let eightMinExpiry = Date().addingTimeInterval(8 * 60).timeIntervalSince1970
        testDefaults.set(eightMinExpiry, forKey: expiryKey)

        let vm = makeViewModel()
        vm.tier = .tier1
        vm.targetRuleId = ruleId
        primeAyahSequence(vm, count: 1)

        await vm.processRecitationOutcome(passed: true, score: 92)

        // The state still transitions to .result(passed:) — but the unblock call
        // is suppressed by the shorter-wins guard inside handlePass.
        XCTAssertEqual(vm.state, .result(passed: true, score: 92))
        XCTAssertFalse(mockService.temporaryUnblockCalled,
                       "Tier 1 (5 min) must not replace an active 8-min unblock")
    }

    // MARK: - Tier 2 scenarios

    /// Tier 2 — Pass both ayahs → 10 min unblock at the end.
    func testTier2_PassBothAyahs_Grants10MinUnblock() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let vm = makeViewModel()
        vm.tier = .tier2
        vm.targetRuleId = ruleId
        primeAyahSequence(vm, count: 2)

        // Ayah 1 passes → advance to Ayah 2 (no unblock yet)
        await vm.processRecitationOutcome(passed: true, score: 80)

        XCTAssertEqual(vm.state, .awaitingNextAyah(score: 80, completedIndex: 1, totalAyahs: 2))
        XCTAssertEqual(vm.currentAyahIndex, 1)
        XCTAssertEqual(vm.ayah?.numberInSurah, 2, "Ayah should advance to second item")
        XCTAssertEqual(vm.progressText, "Ayah 2 of 2")
        XCTAssertFalse(mockService.temporaryUnblockCalled, "No unblock until both ayahs pass")

        // User taps "Next Ayah" → state returns to .ready
        vm.proceedToNextAyah()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.transcript, "")

        // Ayah 2 passes → final unblock granted (10 min)
        await vm.processRecitationOutcome(passed: true, score: 90)

        XCTAssertEqual(vm.state, .result(passed: true, score: 90))
        XCTAssertTrue(mockService.temporaryUnblockCalled)
        XCTAssertEqual(mockService.unblockMinutes, 10)
    }

    /// Tier 2 — Fail Ayah 2: Ayah 1 progress preserved, retry stays on Ayah 2.
    func testTier2_FailAyah2_PreservesAyah1AndRetriesAyah2() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let vm = makeViewModel()
        vm.tier = .tier2
        vm.targetRuleId = ruleId
        primeAyahSequence(vm, count: 2)

        // Ayah 1 passes
        await vm.processRecitationOutcome(passed: true, score: 80)
        XCTAssertEqual(vm.currentAyahIndex, 1)

        // Move to ready to mirror real proceedToNextAyah
        vm.proceedToNextAyah()

        // Ayah 2 fails
        await vm.processRecitationOutcome(passed: false, score: 40)

        XCTAssertEqual(vm.state, .result(passed: false, score: 40))
        XCTAssertEqual(vm.currentAyahIndex, 1, "Should NOT regress to Ayah 1")
        XCTAssertEqual(vm.ayah?.numberInSurah, 2, "Should still be on Ayah 2")
        XCTAssertEqual(vm.failureCountForCurrentAyah, 1)
        XCTAssertFalse(mockService.temporaryUnblockCalled, "No unblock granted on Ayah 2 failure")
    }

    /// Tier 2 — Fail Ayah 1: stays on Ayah 1 (retry restarts the sequence).
    func testTier2_FailAyah1_StaysOnAyah1() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let vm = makeViewModel()
        vm.tier = .tier2
        vm.targetRuleId = ruleId
        primeAyahSequence(vm, count: 2)

        await vm.processRecitationOutcome(passed: false, score: 30)

        XCTAssertEqual(vm.state, .result(passed: false, score: 30))
        XCTAssertEqual(vm.currentAyahIndex, 0)
        XCTAssertEqual(vm.ayah?.numberInSurah, 1, "Failure on Ayah 1 must keep VM on Ayah 1")
        XCTAssertEqual(vm.failureCountForCurrentAyah, 1)
        XCTAssertFalse(mockService.temporaryUnblockCalled)

        // Retry resumes the same Ayah 1 — full restart of the sequence
        vm.retry()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.currentAyahIndex, 0)
    }

    // MARK: - Helpers

    private func makeViewModel() -> ReciteToUnblockViewModel {
        ReciteToUnblockViewModel(
            quranPreferences: MockQuranPreferencesServiceForRecite(),
            screenTimeService: mockService,
            scoringService: MockRecitationScoringService(),
            sequenceProvider: MockAyahSequenceProvider(),
            sharedDefaults: testDefaults,
            nudgeDefaults: makeFreshNudgeDefaults()
        )
    }

    private func makeFreshNudgeDefaults() -> UserDefaults {
        let suiteName = "com.test.tiered-nudge-\(UUID().uuidString)"
        nudgeSuiteNames.append(suiteName)
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return defaults
    }

    /// Pre-populates a fake ayah sequence so processRecitationOutcome can
    /// advance through it without going through loadRandomAyah / network.
    private func primeAyahSequence(_ vm: ReciteToUnblockViewModel, count: Int) {
        let sequence: [Ayah] = (1...count).map { i in
            Ayah(number: i, text: "ayah \(i)", numberInSurah: i, arabic2: "kalimah kalimah kalimah")
        }
        vm.ayahSequence = sequence
        vm.currentAyahIndex = 0
        vm.failureCountForCurrentAyah = 0
        vm.ayah = sequence.first
    }

    private func makeTimeLimitRule(id: UUID, isHardMode: Bool = false) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Test Rule",
            selection: FamilyActivitySelection(),
            type: .timeLimit,
            startTime: DateComponents(hour: 0, minute: 0),
            endTime: DateComponents(hour: 23, minute: 59),
            isHardMode: isHardMode
        )
    }
}
