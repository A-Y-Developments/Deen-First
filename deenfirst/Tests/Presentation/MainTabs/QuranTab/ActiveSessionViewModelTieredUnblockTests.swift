import Combine
import FamilyControls
import Foundation
import RevenueCat
import XCTest

@testable import DeenFirst

// MARK: - Tier 3 Integration Tests (DF-41)
//
// Drives the ActiveSessionViewModel queue-finished / end-early / audio-failure
// flows through small test seams (`session`, `isUnblockSession`, `unlockRuleId`,
// `handleQueueFinished`, `handleAudioLoadError`) added in DF-41.

@MainActor
final class ActiveSessionViewModelTieredUnblockTests: XCTestCase {

    var mockSession: MockSessionServiceForActive!
    var mockScreenTime: MockScreenTimeRulesServiceForActive!

    override func setUp() async throws {
        mockSession = MockSessionServiceForActive()
        mockScreenTime = MockScreenTimeRulesServiceForActive()
    }

    override func tearDown() async throws {
        mockSession = nil
        mockScreenTime = nil
    }

    // MARK: - Tier 3 — complete session

    /// Tier 3 normal mode: queue finishes → 15-min unblock granted, session
    /// duration written to history via SessionService.endSession.
    func testTier3_CompleteSession_Grants15MinUnblockAndSavesSession() async {
        let ruleId = UUID()
        mockScreenTime.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: false)

        let vm = makeViewModel()
        vm.configure(surahs: [], ayahs: [], isUnblockSession: true, unlockRuleId: ruleId)
        vm.session = makeSession(unlockRuleId: ruleId)

        await vm.handleQueueFinished()

        XCTAssertTrue(mockSession.endSessionCalled, "Session must be saved to history on completion")
        XCTAssertEqual(mockScreenTime.unblockMinutes, 15, "Tier 3 normal mode grants 15 min")
        XCTAssertTrue(vm.unblockGranted)
        XCTAssertTrue(vm.sessionDidEnd)
    }

    /// Tier 3 hard mode: queue finishes → 20-min unblock granted.
    func testTier3_CompleteSession_HardMode_Grants20MinUnblock() async {
        let ruleId = UUID()
        mockScreenTime.ruleToReturn = makeTimeLimitRule(id: ruleId, isHardMode: true)

        let vm = makeViewModel()
        vm.configure(surahs: [], ayahs: [], isUnblockSession: true, unlockRuleId: ruleId)
        vm.session = makeSession(unlockRuleId: ruleId)

        await vm.handleQueueFinished()

        XCTAssertEqual(mockScreenTime.unblockMinutes, 20, "Tier 3 hard mode grants 20 min")
        XCTAssertTrue(vm.unblockGranted)
    }

    // MARK: - Tier 3 — end early

    /// User confirms ending early → no unblock granted, sessionDidEnd flips true,
    /// view returns to Blocking tab via the `sessionDidEnd` observer.
    func testTier3_EndEarly_NoUnblockGranted() async {
        let ruleId = UUID()
        mockScreenTime.ruleToReturn = makeTimeLimitRule(id: ruleId)

        let vm = makeViewModel()
        vm.configure(surahs: [], ayahs: [], isUnblockSession: true, unlockRuleId: ruleId)
        vm.session = makeSession(unlockRuleId: ruleId)

        await vm.confirmEndSession()

        XCTAssertTrue(vm.sessionDidEnd)
        XCTAssertFalse(vm.unblockGranted, "Ending early must NOT grant any unblock")
        XCTAssertFalse(mockScreenTime.temporaryUnblockCalled)
        XCTAssertTrue(mockSession.endSessionCalled, "Session row should still be closed out")
    }

    // MARK: - Tier 3 — audio failure

    /// Audio load fails during a Tier 3 session → showUnblockFallback flips true
    /// so the UI can offer the Tier 1/Tier 2 recitation fallback.
    func testTier3_AudioLoadFailure_OffersTier1Tier2Fallback() {
        let vm = makeViewModel()
        vm.configure(surahs: [], ayahs: [], isUnblockSession: true, unlockRuleId: UUID())

        vm.handleAudioLoadError(NSError(domain: "audio", code: -1))

        XCTAssertTrue(vm.showUnblockFallback, "Unblock sessions must offer the Tier 1/2 fallback on audio failure")
        XCTAssertNil(vm.errorMessage, "Fallback path must not surface a generic error message")
    }

    /// In a non-unblock session, an audio failure should surface as an error
    /// (no fallback) — guards against a regression of the unblock branch.
    func testNonUnblockSession_AudioFailure_ShowsErrorNoFallback() {
        let vm = makeViewModel()
        vm.configure(surahs: [], ayahs: [], isUnblockSession: false, unlockRuleId: nil)

        vm.handleAudioLoadError(NSError(domain: "audio", code: -1, userInfo: [NSLocalizedDescriptionKey: "boom"]))

        XCTAssertFalse(vm.showUnblockFallback)
        XCTAssertEqual(vm.errorMessage, "boom")
    }

    // MARK: - Helpers

    private func makeViewModel() -> ActiveSessionViewModel {
        ActiveSessionViewModel(
            ayahAudioPlayer: AyahAudioPlayerServiceImpl(audioPlayer: StubAudioPlayerForActive()),
            sessionService: mockSession,
            subscriptionService: StubSubscriptionServiceForActive(),
            quranPreferences: MockQuranPreferencesServiceForRecite(),
            screenTimeRulesService: mockScreenTime
        )
    }

    private func makeSession(unlockRuleId: UUID) -> Session {
        Session(
            userId: UUID(),
            modality: .listening,
            surahNumbers: [1],
            reciterId: 1,
            type: .unblock(ruleId: unlockRuleId)
        )
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

// MARK: - Mocks

final class MockSessionServiceForActive: SessionService {
    var endSessionCalled = false
    var savedDurationSeconds: Int?

    func startSession(
        modality: Session.SessionModality,
        surahNumbers: [Int],
        reciterId: Int?,
        type: SessionType
    ) async throws -> Session {
        Session(userId: UUID(), modality: modality, surahNumbers: surahNumbers, reciterId: reciterId, type: type)
    }

    func endSession(_ session: Session, durationSeconds: Int) async throws {
        endSessionCalled = true
        savedDurationSeconds = durationSeconds
    }

    func getTodaySession(for userId: UUID) async throws -> Session? { nil }
    func updateStreak(for userId: UUID) async throws {}
    func checkAndResetStreakIfNeeded() async throws {}
    func cleanupOrphanedSessions() async {}
}

final class MockScreenTimeRulesServiceForActive: ScreenTimeRulesService {
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

@MainActor
final class StubAudioPlayerForActive: NSObject, AudioPlayerService {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSurahName: String?
    @Published var currentReciterName: String?

    var onPlaybackFinished: (() -> Void)?
    var onPlaybackError: ((Error) -> Void)?

    func loadAudio(url: URL, surahName: String, reciterName: String) async throws {}
    func play() {}
    func pause() {}
    func stop() {}
    func seek(to time: TimeInterval) {}
}

final class StubSubscriptionServiceForActive: SubscriptionService {
    func checkSubscriptionStatus() async throws -> Bool { false }
    func fetchOfferings() async throws -> Offerings { throw NSError(domain: "stub", code: 0) }
    func purchase(package: Package) async throws -> Bool { false }
    func purchaseMonthly() async throws -> Bool { false }
    func purchaseYearly() async throws -> Bool { false }
    func restorePurchases() async throws -> Bool { false }
    func getCustomerInfo() async throws -> CustomerInfo { throw NSError(domain: "stub", code: 0) }
}
