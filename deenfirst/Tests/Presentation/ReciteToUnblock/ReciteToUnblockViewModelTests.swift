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

    // MARK: - minutes(isHardMode:)

    func testTier3_MinutesHardMode_Is20() {
        XCTAssertEqual(UnblockTier.tier3.minutes(isHardMode: true), 20)
    }

    func testTier3_MinutesNormalMode_Is15() {
        XCTAssertEqual(UnblockTier.tier3.minutes(isHardMode: false), 15)
    }

    func testTier1_MinutesHardMode_Is5() {
        XCTAssertEqual(UnblockTier.tier1.minutes(isHardMode: true), 5)
    }

    func testTier2_MinutesHardMode_Is10() {
        XCTAssertEqual(UnblockTier.tier2.minutes(isHardMode: true), 10)
    }

    // MARK: - ayahCount(isHardMode:)

    func testTier1_AyahCount_NormalMode_Is1() {
        XCTAssertEqual(UnblockTier.tier1.ayahCount(isHardMode: false), 1)
    }

    func testTier1_AyahCount_HardMode_Is2() {
        XCTAssertEqual(UnblockTier.tier1.ayahCount(isHardMode: true), 2)
    }

    func testTier2_AyahCount_NormalMode_Is2() {
        XCTAssertEqual(UnblockTier.tier2.ayahCount(isHardMode: false), 2)
    }

    func testTier2_AyahCount_HardMode_Is3() {
        XCTAssertEqual(UnblockTier.tier2.ayahCount(isHardMode: true), 3)
    }

    func testTier3_AyahCount_IsZero() {
        XCTAssertEqual(UnblockTier.tier3.ayahCount(isHardMode: false), 0)
        XCTAssertEqual(UnblockTier.tier3.ayahCount(isHardMode: true), 0)
    }
}

// MARK: - ReciteToUnblockViewModel Tier + Shorter-Wins Tests

@MainActor
final class ReciteToUnblockViewModelTests: XCTestCase {

    var mockService: MockScreenTimeRulesServiceForRecite!
    var testDefaults: UserDefaults!
    var testDefaultsSuiteName: String!

    override func setUp() async throws {
        mockService = MockScreenTimeRulesServiceForRecite()
        testDefaultsSuiteName = "com.test.recite-\(UUID().uuidString)"
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

    // MARK: - Hard Mode computed properties

    func testCanRefreshAyah_TrueInNormalMode() {
        let ruleId = UUID()
        let rule = makeTimeLimitRule(id: ruleId, isHardMode: false)
        mockService.ruleToReturn = rule
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        XCTAssertTrue(vm.canRefreshAyah)
    }

    func testCanRefreshAyah_FalseInHardMode() {
        let ruleId = UUID()
        let rule = makeTimeLimitRule(id: ruleId, isHardMode: true)
        mockService.ruleToReturn = rule
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        XCTAssertFalse(vm.canRefreshAyah)
    }

    func testSimilarityThreshold_NormalMode() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.similarityThreshold, 0.70, accuracy: 0.001)
    }

    func testSimilarityThreshold_HardMode() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        XCTAssertEqual(vm.similarityThreshold, 0.85, accuracy: 0.001)
    }

    func testMinWordCount_NilInNormalMode() {
        let vm = makeViewModel()
        XCTAssertNil(vm.minWordCount)
    }

    func testMinWordCount_5InHardMode() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        XCTAssertEqual(vm.minWordCount, 5)
    }

    // MARK: - Pool nudge

    func testPoolNudge_NotShownByDefault() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.showPoolNudge)
    }

    func testPoolNudge_ShownOncePerDay_NotRepeated() async {
        let nudgeSuiteName = "com.test.nudge-\(UUID().uuidString)"
        let nudgeDefaults = UserDefaults(suiteName: nudgeSuiteName)!
        defer { nudgeDefaults.removePersistentDomain(forName: nudgeSuiteName) }
        // Simulate nudge already recorded today
        nudgeDefaults.set(Calendar.current.startOfDay(for: Date()), forKey: "com.aydev.deenfirst.poolNudgeDate")
        let pool = MockAyahPoolServiceForRecite()
        pool.poolToReturn = []
        let vm = makeViewModel(ayahPoolService: pool, nudgeDefaults: nudgeDefaults)

        _ = await vm.resolveEligiblePool()

        XCTAssertFalse(vm.showPoolNudge, "Nudge must not re-fire on the same day")
    }

    /// Normal Mode, empty pool → nudge should show. (DF-29 extends DF-13 beyond Hard Mode.)
    func testPoolNudge_NormalMode_EmptyPool_ShowsNudge() async {
        let nudgeDefaults = makeFreshNudgeDefaults()
let pool = MockAyahPoolServiceForRecite()
        pool.poolToReturn = []
        let vm = makeViewModel(ayahPoolService: pool, nudgeDefaults: nudgeDefaults)

        let eligible = await vm.resolveEligiblePool()

        XCTAssertTrue(eligible.isEmpty)
        XCTAssertTrue(vm.showPoolNudge)
    }

    /// Normal Mode, non-empty pool → pool returned, nudge NOT shown.
    func testResolveEligiblePool_NormalMode_NonEmptyPool_ReturnsPoolNoNudge() async {
        let nudgeDefaults = makeFreshNudgeDefaults()
let pool = MockAyahPoolServiceForRecite()
        pool.poolToReturn = [
            makePoolItem(surah: 112, ayah: 1, wordCount: 4), // short — still eligible in normal mode
            makePoolItem(surah: 114, ayah: 1, wordCount: 6),
        ]
        let vm = makeViewModel(ayahPoolService: pool, nudgeDefaults: nudgeDefaults)

        let eligible = await vm.resolveEligiblePool()

        XCTAssertEqual(eligible.count, 2)
        XCTAssertFalse(vm.showPoolNudge)
    }

    /// Hard Mode, non-empty pool but all short → eligible empty, nudge fires.
    func testResolveEligiblePool_HardMode_OnlyShortAyahs_TriggersNudge() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let nudgeDefaults = makeFreshNudgeDefaults()
let pool = MockAyahPoolServiceForRecite()
        pool.poolToReturn = [
            makePoolItem(surah: 112, ayah: 1, wordCount: 4),
            makePoolItem(surah: 112, ayah: 2, wordCount: 3),
        ]
        let vm = makeViewModel(ayahPoolService: pool, nudgeDefaults: nudgeDefaults)
        vm.targetRuleId = ruleId

        let eligible = await vm.resolveEligiblePool()

        XCTAssertTrue(eligible.isEmpty)
        XCTAssertTrue(vm.showPoolNudge)
    }

    /// Hard Mode, pool with mixed word counts → only items with wordCount >= 5 kept.
    func testResolveEligiblePool_HardMode_FiltersShortAyahs() async {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let nudgeDefaults = makeFreshNudgeDefaults()
let pool = MockAyahPoolServiceForRecite()
        pool.poolToReturn = [
            makePoolItem(surah: 112, ayah: 1, wordCount: 4),
            makePoolItem(surah: 2, ayah: 255, wordCount: 40),
        ]
        let vm = makeViewModel(ayahPoolService: pool, nudgeDefaults: nudgeDefaults)
        vm.targetRuleId = ruleId

        let eligible = await vm.resolveEligiblePool()

        XCTAssertEqual(eligible.count, 1)
        XCTAssertEqual(eligible.first?.surahNumber, 2)
        XCTAssertFalse(vm.showPoolNudge)
    }

    // MARK: - Hard Mode tier duration

    func testUnblockDurationMinutes_Tier3_HardMode_Is20() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        vm.tier = .tier3
        XCTAssertEqual(vm.unblockDurationMinutes, 20)
    }

    func testUnblockDurationMinutes_Tier3_NormalMode_Is15() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: false)
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        vm.tier = .tier3
        XCTAssertEqual(vm.unblockDurationMinutes, 15)
    }

    func testUnblockDurationMinutes_Tier1_HardMode_Is5() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        vm.tier = .tier1
        XCTAssertEqual(vm.unblockDurationMinutes, 5)
    }

    func testUnblockDurationMinutes_Tier2_HardMode_Is10() {
        let ruleId = UUID()
        mockService.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)
        let vm = makeViewModel()
        vm.targetRuleId = ruleId
        vm.tier = .tier2
        XCTAssertEqual(vm.unblockDurationMinutes, 10)
    }

    // MARK: - Helpers

    private func makeViewModel(
        ayahPoolService: AyahPoolService? = nil,
        nudgeDefaults: UserDefaults? = nil
    ) -> ReciteToUnblockViewModel {
        ReciteToUnblockViewModel(
            quranPreferences: MockQuranPreferencesServiceForRecite(),
            screenTimeService: mockService,
            sharedDefaults: testDefaults,
            ayahPoolService: ayahPoolService ?? MockAyahPoolServiceForRecite(),
            nudgeDefaults: nudgeDefaults ?? makeFreshNudgeDefaults()
        )
    }

    private var nudgeSuiteNames: [String] = []

    private func makeFreshNudgeDefaults() -> UserDefaults {
        let suiteName = "com.test.nudge-\(UUID().uuidString)"
        nudgeSuiteNames.append(suiteName)
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return defaults
    }

    private func makePoolItem(surah: Int, ayah: Int, wordCount: Int) -> AyahPoolItem {
        AyahPoolItem(
            surahNumber: surah,
            ayahNumberInSurah: ayah,
            arabicText: String(repeating: "word ", count: wordCount).trimmingCharacters(in: .whitespaces),
            transliteration: "",
            wordCount: wordCount
        )
    }

    /// A timeLimit rule active all day so isCurrentlyInBlockingPeriod returns true during tests.
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
    func deactivateRule(id: UUID) async throws {}
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
    func editAppLimitRule(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func editTimeLimitRule(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteRule(id: UUID) async throws {}
    func disableRule(id: UUID) async throws {}
    func disableHardMode(for ruleId: UUID) async {}
    func disableLockEditing(for ruleId: UUID) async {}
}

final class MockQuranPreferencesServiceForRecite: QuranPreferencesService {
    var selectedTranslation: TranslationLanguage = .english
    var selectedReciterId: Int = 1
    func getTranslation(for ayah: Ayah) -> String { "" }
    func getReciterAudio(for ayah: Ayah) -> ReciterAudio? { nil }
}

@MainActor
final class MockAyahPoolServiceForRecite: AyahPoolService {
    var poolToReturn: [AyahPoolItem] = []
    func fetchPool() async -> [AyahPoolItem] { poolToReturn }
    func addAyah(surahNumber: Int, ayahNumber: Int, arabicText: String, transliteration: String) async throws {}
    func removeAyah(id: UUID) async {}
    func poolCount() async -> Int { poolToReturn.count }
    func nextAyah(excludeShort: Bool) -> AyahPoolItem? { poolToReturn.first }
    func isEmpty() async -> Bool { poolToReturn.isEmpty }
}
