import DeviceActivity
import FamilyControls
import Foundation
import XCTest

@testable import DeenFirst

/// Verifies SessionService correctly forwards qualifying events to
/// `DashboardDataWriter` (focus session completion + streak updates).
@MainActor
final class SessionServiceDashboardTests: XCTestCase {
    private var sessionRepo: StubSessionRepository!
    private var userRepo: StubUserRepository!
    private var screenTime: StubScreenTimeRulesService!
    private var spyWriter: SpyDashboardDataWriter!
    private var service: SessionServiceImpl!

    override func setUp() {
        super.setUp()
        sessionRepo = StubSessionRepository()
        userRepo = StubUserRepository()
        screenTime = StubScreenTimeRulesService()
        spyWriter = SpyDashboardDataWriter()
        service = SessionServiceImpl(
            sessionRepository: sessionRepo,
            userRepository: userRepo,
            screenTimeRulesService: screenTime,
            dashboardDataWriter: spyWriter
        )
    }

    override func tearDown() {
        sessionRepo = nil
        userRepo = nil
        screenTime = nil
        spyWriter = nil
        service = nil
        super.tearDown()
    }

    // MARK: - endSession

    func testEndSession_listening_recordsFocusSession() async throws {
        let session = Session(userId: UUID(), modality: .listening, surahNumbers: [1])

        try await service.endSession(session, durationSeconds: 300)

        XCTAssertEqual(spyWriter.focusDurations, [300])
    }

    func testEndSession_reading_doesNotRecordFocusSession() async throws {
        let session = Session(userId: UUID(), modality: .reading, surahNumbers: [1])

        try await service.endSession(session, durationSeconds: 300)

        XCTAssertTrue(spyWriter.focusDurations.isEmpty)
    }

    func testEndSession_zeroDuration_doesNotRecord() async throws {
        let session = Session(userId: UUID(), modality: .listening, surahNumbers: [1])

        try await service.endSession(session, durationSeconds: 0)

        XCTAssertTrue(spyWriter.focusDurations.isEmpty)
    }

    // MARK: - updateStreak

    func testUpdateStreak_firstActivity_writesStreakOne() async throws {
        let user = User(appleUserId: "u1")
        user.lastActiveDate = nil
        user.currentStreak = 0
        user.longestStreak = 0
        userRepo.user = user

        try await service.updateStreak(for: user.id)

        XCTAssertEqual(spyWriter.streakUpdates.count, 1)
        XCTAssertEqual(spyWriter.streakUpdates.first?.current, 1)
        XCTAssertEqual(spyWriter.streakUpdates.first?.longest, 1)
    }

    func testUpdateStreak_sameDay_doesNotWrite() async throws {
        let user = User(appleUserId: "u1")
        user.lastActiveDate = Date()
        user.currentStreak = 3
        user.longestStreak = 3
        userRepo.user = user

        try await service.updateStreak(for: user.id)

        XCTAssertTrue(spyWriter.streakUpdates.isEmpty)
    }
}

// MARK: - Spy / Stubs

private final class SpyDashboardDataWriter: DashboardDataWriter {
    var focusDurations: [TimeInterval] = []
    var quranReadingDurations: [TimeInterval] = []
    var passedCalls = 0
    var attemptCalls = 0
    var emergencyCalls = 0
    var streakUpdates: [(current: Int, longest: Int)] = []
    var flushCalls = 0

    func recordFocusSession(duration: TimeInterval) { focusDurations.append(duration) }
    func recordQuranReading(duration: TimeInterval) { quranReadingDurations.append(duration) }
    func recordRecitationPassed() { passedCalls += 1 }
    func recordRecitationAttempt() { attemptCalls += 1 }
    func recordEmergencyUnblock() { emergencyCalls += 1 }
    func updateStreak(current: Int, longest: Int) {
        streakUpdates.append((current, longest))
    }
    func flush() { flushCalls += 1 }
}

private final class StubSessionRepository: SessionRepository {
    var saved: [Session] = []
    var updated: [Session] = []

    func save(_ session: Session) async throws { saved.append(session) }
    func getActiveSessions() async throws -> [Session] { [] }
    func updateSession(_ session: Session) async throws { updated.append(session) }
    func getSessions(for userId: UUID, startDate: Date, endDate: Date) async throws -> [Session] { [] }
    func getTodaySession(for userId: UUID) async throws -> Session? { nil }
}

private final class StubUserRepository: UserRepository {
    var user: User?

    func createUser(_ user: User) async throws { self.user = user }
    func getUser(byAppleUserId appleUserId: String) async throws -> User? { user }
    func getCurrentUser() async throws -> User? { user }
    func updateUser(_ user: User) async throws { self.user = user }
    func deleteCurrentUser() async throws { user = nil }
}

@MainActor
private final class StubScreenTimeRulesService: ScreenTimeRulesService {
    func requestAuthorization() async throws {}
    func setAppLimitBlock(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func deleteAppLimit(id: UUID) async throws {}
    func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteTimeLimit(id: UUID) async throws {}
    func editAppLimitRule(for selection: FamilyActivitySelection, config: AppLimitConfig) async throws {}
    func editTimeLimitRule(for selection: FamilyActivitySelection, config: TimeLimitConfig) async throws {}
    func deleteRule(id: UUID) async throws {}
    func disableRule(id: UUID) async throws {}
    func disableHardMode(for ruleId: UUID) async {}
    func disableLockEditing(for ruleId: UUID) async {}
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
    func isTemporarilyUnblocked(ruleId: UUID) -> Bool { false }
    func unblockRemainingSeconds(ruleId: UUID) -> Int? { nil }
    func activateEmergencyUnblock() async {}
    func deactivateEmergencyUnblock() async {}
    func reblockEmergencyIfExpired() async {}
    var isEmergencyUnblockActive: Bool { false }
    func emergencyUnblockQuotaRemaining() -> Int { 0 }
}
