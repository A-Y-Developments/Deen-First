import FamilyControls
import Foundation
import SwiftData
import XCTest

@testable import DeenFirst

// DF-42 — Integration tests for Hard Mode + Lock Editing interaction.
//
// Wires real ScreenTimeRulesServiceImpl + real PendingChangeServiceImpl with
// in-memory SwiftData for PendingRuleChange. ReciteToUnblockViewModel tests
// use an injected lightweight rules service mock because the VM only needs
// getRule to derive Hard Mode state.
//
// Mocks reused from sibling test files (same test target):
// - MockLockEditingRepository
// - MockDeviceActivityManagerForLockEditing
// - MockNotificationSchedulingServiceForLockEditing
// - MockScreenTimeRulesServiceForRecite
// - MockAyahPoolServiceForRecite
// - MockQuranPreferencesServiceForRecite

@MainActor
final class HardModeLockEditingIntegrationTests: XCTestCase {

    // Real collaborators
    var repository: MockLockEditingRepository!
    var deviceActivityManager: MockDeviceActivityManagerForLockEditing!
    var notificationService: MockNotificationSchedulingServiceForLockEditing!
    var rulesService: ScreenTimeRulesServiceImpl!

    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var pendingChangeService: PendingChangeServiceImpl!

    override func setUp() async throws {
        repository = MockLockEditingRepository()
        deviceActivityManager = MockDeviceActivityManagerForLockEditing()
        notificationService = MockNotificationSchedulingServiceForLockEditing()

        rulesService = ScreenTimeRulesServiceImpl(
            repository: repository,
            deviceActivityManager: deviceActivityManager,
            notificationSchedulingService: notificationService
        )

        let schema = Schema([PendingRuleChange.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)

        pendingChangeService = PendingChangeServiceImpl(
            localDataSource: localDataSource,
            screenTimeRulesService: rulesService,
            screenTimeRulesRepository: repository,
            notificationSchedulingService: notificationService
        )
        rulesService.pendingChangeService = pendingChangeService

        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownDateKey)
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownMonotonicKey)
    }

    override func tearDown() async throws {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownDateKey)
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastKnownMonotonicKey)
        repository = nil
        deviceActivityManager = nil
        notificationService = nil
        rulesService = nil
        container = nil
        localDataSource = nil
        pendingChangeService = nil
    }

    // MARK: - Hard Mode — (1) Enabling Hard Mode sets isLockEditingEnabled = true

    // DF-044: Hard Mode no longer force-enables Lock Editing in the config
    // layer. Coupling is now explicit at the ViewModel — user confirms the
    // pre-save dialog, then the VM sets both flags and saves. This test
    // verifies the persisted result of that confirmed save.
    func testHardMode_SaveWithConfirmedHardModeAndLockEditing_PersistsBothFlags() async throws {
        let ruleId = UUID()
        let config = AppLimitConfig(
            id: ruleId,
            name: "Social",
            timeLimit: .thirtyMin,
            isHardMode: true,
            isLockEditingEnabled: true
        )

        try await rulesService.setAppLimitBlock(for: FamilyActivitySelection(), config: config)

        let stored = repository.rules[ruleId]
        XCTAssertNotNil(stored)
        XCTAssertTrue(stored?.isHardMode ?? false)
        XCTAssertTrue(stored?.isLockEditingEnabled ?? false, "Persisted rule must carry both flags after confirmed save")
    }

    // MARK: - Hard Mode — (2) 85% threshold enforced, 75% fails

    func testHardMode_ReciteVM_Enforces85PercentThreshold() {
        let ruleId = UUID()
        let mockRecite = MockScreenTimeRulesServiceForRecite()
        mockRecite.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)

        let vm = makeReciteVM(service: mockRecite)
        vm.targetRuleId = ruleId

        XCTAssertEqual(vm.similarityThreshold, 0.85, accuracy: 0.001)
        // Implication: a score of 75 (0.75) < 0.85 → would not pass.
        let passingAtSeventyFive = 75 >= Int((vm.similarityThreshold * 100).rounded())
        XCTAssertFalse(passingAtSeventyFive, "75% must be treated as a failure in Hard Mode")
    }

    // MARK: - Hard Mode — (3) Refresh Ayah button absent in Hard Mode

    func testHardMode_ReciteVM_CanRefreshAyahIsFalse() {
        let ruleId = UUID()
        let mockRecite = MockScreenTimeRulesServiceForRecite()
        mockRecite.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)

        let vm = makeReciteVM(service: mockRecite)
        vm.targetRuleId = ruleId

        XCTAssertFalse(vm.canRefreshAyah, "Refresh Ayah button must be hidden (canRefreshAyah == false) in Hard Mode")
    }

    // MARK: - Hard Mode — (4) Ayahs with < 5 words never surfaced in Hard Mode
    //
    // Pool filtering now lives in AyahSequenceProvider; QA covers the full
    // word-count filter matrix in AyahSequenceProviderTests. The VM-level
    // smoke test below just verifies the Hard Mode derivation still works
    // after the 113 split.

    func testHardMode_ReciteVM_DerivesHardModeFromRule() {
        let ruleId = UUID()
        let mockRecite = MockScreenTimeRulesServiceForRecite()
        mockRecite.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)

        let vm = makeReciteVM(service: mockRecite)
        vm.targetRuleId = ruleId

        XCTAssertEqual(vm.similarityThreshold, RecitationThreshold.hardMode, accuracy: 0.001)
    }

    // MARK: - Hard Mode — (5) Tier 1 requires 2 ayahs in Hard Mode

    func testHardMode_Tier1_RequiresTwoAyahs() {
        XCTAssertEqual(UnblockTier.tier1.ayahCount(isHardMode: true), 2)
        XCTAssertEqual(UnblockTier.tier1.ayahCount(isHardMode: false), 1)
    }

    // MARK: - Lock Editing — (6) Edit attempt on locked rule queues pending change

    func testLockEditing_EditAttempt_QueuesPendingChange() async throws {
        let ruleId = UUID()
        let rule = makeLockedAppLimitRule(id: ruleId)
        repository.rules[ruleId] = rule

        let edited = AppLimitConfig(
            id: ruleId,
            name: "Renamed",
            timeLimit: .oneHour,
            isHardMode: false,
            isLockEditingEnabled: true
        )

        try await rulesService.editAppLimitRule(for: FamilyActivitySelection(), config: edited)

        XCTAssertTrue(pendingChangeService.hasPendingChange(for: ruleId), "Edit on locked rule must queue a pending change")

        let pending = pendingChangeService.pendingChange(for: ruleId)
        XCTAssertEqual(pending?.changeType, PendingChangeType.edit.rawValue)
        XCTAssertNotNil(pending?.pendingData, "Edit pending change must carry the encoded updated rule")

        // Underlying rule must remain unchanged until the delay elapses.
        XCTAssertEqual(repository.rules[ruleId]?.name, "Locked Rule", "Rule must not be edited immediately")
    }

    // MARK: - Lock Editing — (7) Delete attempt on locked rule creates pending change

    func testLockEditing_DeleteAttempt_QueuesPendingChange() async throws {
        let ruleId = UUID()
        let rule = makeLockedAppLimitRule(id: ruleId)
        repository.rules[ruleId] = rule

        try await rulesService.deleteRule(id: ruleId)

        XCTAssertTrue(pendingChangeService.hasPendingChange(for: ruleId))
        XCTAssertEqual(pendingChangeService.pendingChange(for: ruleId)?.changeType, PendingChangeType.delete.rawValue)
        XCTAssertNotNil(repository.rules[ruleId], "Locked rule must not be deleted immediately")
    }

    // MARK: - Lock Editing — (8) Cancel pending change removes it

    func testLockEditing_CancelPendingChange_RemovesIt() async throws {
        let ruleId = UUID()
        let rule = makeLockedAppLimitRule(id: ruleId)
        repository.rules[ruleId] = rule

        try await rulesService.deleteRule(id: ruleId)
        XCTAssertTrue(pendingChangeService.hasPendingChange(for: ruleId))

        await pendingChangeService.cancelPendingChange(for: ruleId)

        XCTAssertFalse(pendingChangeService.hasPendingChange(for: ruleId))
        let raw = try localDataSource.fetchPendingChanges()
        XCTAssertTrue(raw.first?.isCancelled ?? false, "Cancelled change must be flagged isCancelled")
    }

    // MARK: - Lock Editing — (9) After 24hr expiry (mocked time) the change is applied

    func testLockEditing_ExpiredPendingChange_AppliedOnForeground() async throws {
        let ruleId = UUID()
        var rule = makeLockedAppLimitRule(id: ruleId)
        rule.isLockEditingEnabled = true
        repository.rules[ruleId] = rule

        // Simulate an older-than-24h pending change by inserting it directly with a backdated requestedAt.
        let backdated = Date().addingTimeInterval(-90_000) // 25h ago
        let expiredChange = PendingRuleChange(
            ruleId: ruleId,
            changeType: .disableLockEditing,
            requestedAt: backdated
        )
        try localDataSource.insertPendingChange(expiredChange)

        // DF-040: Clock guard is now monotonic-aware. With neither baseline
        // seeded, the guard block is skipped entirely and the apply proceeds.
        await pendingChangeService.applyExpiredChanges()

        let stored = try localDataSource.fetchPendingChanges()
        XCTAssertTrue(stored.first?.isApplied ?? false, "Expired change must be marked applied")
        XCTAssertFalse(repository.rules[ruleId]?.isLockEditingEnabled ?? true, "Lock Editing must be disabled after 24h delay")
    }

    // MARK: - Lock Editing — (10) Turning Lock Editing OFF goes through the 24hr delay

    func testLockEditing_DisableLockEditing_GoesThrough24HrDelay() async {
        let ruleId = UUID()
        let rule = makeLockedAppLimitRule(id: ruleId)
        repository.rules[ruleId] = rule

        await rulesService.disableLockEditing(for: ruleId)

        // Flag must NOT flip immediately.
        XCTAssertTrue(repository.rules[ruleId]?.isLockEditingEnabled ?? false, "Disable must not take effect immediately")

        // Pending change must exist with the disableLockEditing type.
        let pending = pendingChangeService.pendingChange(for: ruleId)
        XCTAssertNotNil(pending)
        XCTAssertEqual(pending?.changeType, PendingChangeType.disableLockEditing.rawValue)

        // appliesAt must be ~24h in the future.
        if let requested = pending?.requestedAt, let applies = pending?.appliesAt {
            let delta = applies.timeIntervalSince(requested)
            XCTAssertEqual(delta, 86_400, accuracy: 1, "Delay must be exactly 24 hours")
        } else {
            XCTFail("Pending change missing required timestamps")
        }
    }

    // MARK: - Combined — (11) Hard Mode ON → Lock Editing auto-ON end-to-end

    func testCombined_HardModeOn_ResultsInLockedRule() async throws {
        let ruleId = UUID()
        // DF-044: ViewModel now passes both flags explicitly after the user
        // confirms the pre-save Hard Mode dialog.
        let config = AppLimitConfig(
            id: ruleId,
            name: "Focus",
            timeLimit: .oneHour,
            isHardMode: true,
            isLockEditingEnabled: true
        )

        try await rulesService.setAppLimitBlock(for: FamilyActivitySelection(), config: config)

        let stored = repository.rules[ruleId]
        XCTAssertTrue(stored?.isHardMode ?? false)
        XCTAssertTrue(stored?.isLockEditingEnabled ?? false)

        // Follow-through: a subsequent edit must now go through the Lock Editing gate.
        let edited = AppLimitConfig(
            id: ruleId,
            name: "Focus v2",
            timeLimit: .twoHours,
            isHardMode: true,
            isLockEditingEnabled: true
        )
        try await rulesService.editAppLimitRule(for: FamilyActivitySelection(), config: edited)

        XCTAssertTrue(pendingChangeService.hasPendingChange(for: ruleId), "Edits on a Hard Mode rule must be gated by Lock Editing")
        XCTAssertEqual(repository.rules[ruleId]?.name, "Focus", "Name must not change until the pending change applies")
    }

    // MARK: - Combined — (12) Hard Mode OFF attempt blocked by Lock Editing delay

    func testCombined_DisableHardModeAttempt_BlockedByLockEditingDelay() async {
        let ruleId = UUID()
        var rule = makeLockedAppLimitRule(id: ruleId)
        rule.isHardMode = true
        rule.isLockEditingEnabled = true
        repository.rules[ruleId] = rule

        await rulesService.disableHardMode(for: ruleId)

        // Must not flip immediately — goes through the pending change flow.
        XCTAssertTrue(repository.rules[ruleId]?.isHardMode ?? false, "Hard Mode must remain ON until the 24h delay elapses")

        let pending = pendingChangeService.pendingChange(for: ruleId)
        XCTAssertNotNil(pending)
        XCTAssertEqual(pending?.changeType, PendingChangeType.disableHardMode.rawValue)

        // Now simulate the 24h passing and apply — only then should Hard Mode flip off.
        if let change = pending {
            change.requestedAt = Date().addingTimeInterval(-90_000)
            change.appliesAt = change.requestedAt.addingTimeInterval(86_400)
        }

        await pendingChangeService.applyExpiredChanges()

        XCTAssertFalse(repository.rules[ruleId]?.isHardMode ?? true, "Hard Mode must be disabled once the delay elapses")
        // DF-16: disabling Hard Mode must NOT auto-clear Lock Editing — the user
        // turns it off separately via .disableLockEditing (preserves accountability friction).
        XCTAssertTrue(repository.rules[ruleId]?.isLockEditingEnabled ?? false, "Lock Editing must remain ON when only Hard Mode is disabled")
    }

    // MARK: - Helpers

    private func makeLockedAppLimitRule(id: UUID) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Locked Rule",
            selection: FamilyActivitySelection(),
            type: .appLimit,
            limitSeconds: 3600,
            isLockEditingEnabled: true
        )
    }

    private func makeTimeLimitRule(id: UUID, isHardMode: Bool) -> ScreenTimeRule {
        ScreenTimeRule(
            id: id,
            name: "Timed Rule",
            selection: FamilyActivitySelection(),
            type: .timeLimit,
            startTime: DateComponents(hour: 0, minute: 0),
            endTime: DateComponents(hour: 23, minute: 59),
            isHardMode: isHardMode
        )
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

    private func makeReciteVM(
        service: MockScreenTimeRulesServiceForRecite
    ) -> ReciteToUnblockViewModel {
        let nudgeSuite = "com.test.df42-nudge-\(UUID().uuidString)"
        let nudgeDefaults = UserDefaults(suiteName: nudgeSuite) ?? .standard
        let sharedSuite = "com.test.df42-shared-\(UUID().uuidString)"
        let sharedDefaults = UserDefaults(suiteName: sharedSuite)
        return ReciteToUnblockViewModel(
            quranPreferences: MockQuranPreferencesServiceForRecite(),
            screenTimeService: service,
            scoringService: MockRecitationScoringService(),
            sequenceProvider: MockAyahSequenceProvider(),
            sharedDefaults: sharedDefaults,
            nudgeDefaults: nudgeDefaults
        )
    }
}
