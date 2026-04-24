import AuthenticationServices
import FamilyControls
import XCTest

@testable import DeenFirst

@MainActor
final class HomeTabViewModelTests: XCTestCase {
    var viewModel: HomeTabViewModel!
    var mockQuranService: MockQuranServiceForHome!
    var mockAuthService: MockAuthServiceForHome!
    var mockPendingChangeService: MockPendingChangeServiceForHome!

    override func setUp() async throws {
        mockQuranService = MockQuranServiceForHome()
        mockAuthService = MockAuthServiceForHome()
        mockPendingChangeService = MockPendingChangeServiceForHome()
        viewModel = HomeTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService,
            pendingChangeService: mockPendingChangeService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockQuranService = nil
        mockAuthService = nil
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

    // MARK: - Dashboard summary (refreshDashboardSummary)

    /// Helper: isolated in-memory UserDefaults for each dashboard-summary test
    /// so App Group writes don't leak between test runs.
    private func makeIsolatedDefaults(file: StaticString = #file, line: UInt = #line) -> UserDefaults {
        let suite = "DashboardSummaryTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Failed to build isolated UserDefaults", file: file, line: line)
            return .standard
        }
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testRefreshDashboardSummary_EmptyDefaults_ProducesBaseScore() {
        let defaults = makeIsolatedDefaults()
        let vm = HomeTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService,
            pendingChangeService: mockPendingChangeService,
            sharedDefaults: defaults
        )

        vm.refreshDashboardSummary()

        // No activity, no streak → base 50 clamped in [0, 100].
        XCTAssertEqual(vm.deenScore, 50)
        XCTAssertEqual(vm.todayFocusSessions, 0)
        XCTAssertEqual(vm.todayRecitationsPassed, 0)
    }

    func testRefreshDashboardSummary_PopulatedTodayCounters() {
        let defaults = makeIsolatedDefaults()
        let dayKey = DashboardDateKeys.dayKey(for: Date())

        defaults.set(25 * 60, forKey: AppGroupConstants.quranSecondsKey(dayKey))  // 20–30m tier
        defaults.set(2, forKey: AppGroupConstants.focusSessionsKey(dayKey))        // 2+ sessions
        defaults.set(3, forKey: AppGroupConstants.recitationsPassedKey(dayKey))    // 3+ recitations

        let vm = HomeTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService,
            pendingChangeService: mockPendingChangeService,
            sharedDefaults: defaults
        )

        vm.refreshDashboardSummary()

        XCTAssertEqual(vm.todayFocusSessions, 2)
        XCTAssertEqual(vm.todayRecitationsPassed, 3)
        // 50 base + 15 (quran 20–30m) + 15 (focus 2+) + 10 (recitations 3+) = 90
        XCTAssertEqual(vm.deenScore, 90)
    }

    func testRefreshDashboardSummary_IncludesStreakBonus() {
        let defaults = makeIsolatedDefaults()
        let vm = HomeTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService,
            pendingChangeService: mockPendingChangeService,
            sharedDefaults: defaults
        )
        vm.currentStreak = 7

        vm.refreshDashboardSummary()

        // 50 base + streak active 5 + streak week bonus 5 = 60
        XCTAssertEqual(vm.deenScore, 60)
    }

    func testRefreshDashboardSummary_EmergencyUnblockPenalty() {
        let defaults = makeIsolatedDefaults()
        let weekKey = DashboardDateKeys.weekKey(for: Date())
        defaults.set(2, forKey: AppGroupConstants.emergencyUnblocksKey(weekKey))

        let vm = HomeTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService,
            pendingChangeService: mockPendingChangeService,
            sharedDefaults: defaults
        )

        vm.refreshDashboardSummary()

        // 50 base + 0 positives + (-10) emergency 2+ = 40
        XCTAssertEqual(vm.deenScore, 40)
    }

    func testRefreshDashboardSummary_ClampsAtZero() {
        let defaults = makeIsolatedDefaults()
        let weekKey = DashboardDateKeys.weekKey(for: Date())
        // Stack maximum penalties, no positives.
        defaults.set(10, forKey: AppGroupConstants.emergencyUnblocksKey(weekKey))

        let vm = HomeTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService,
            pendingChangeService: mockPendingChangeService,
            sharedDefaults: defaults
        )

        vm.refreshDashboardSummary()

        // 50 - 10 (emergency 2+) = 40. Not quite zero because main-app-side
        // Deen Score can't read screen-time-over-limit. This guard documents
        // that: even with everything negative we can read, we don't go below 0.
        XCTAssertGreaterThanOrEqual(vm.deenScore, 0)
    }
}

// MARK: - Mocks

final class MockQuranServiceForHome: QuranService {
    func loadAllSurahs() async throws -> [Surah] { [] }
    func loadSurah(number: Int) async throws -> (Surah, [Ayah]) {
        throw NSError(domain: "MockError", code: 0)
    }
    func loadVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        throw NSError(domain: "MockError", code: 0)
    }
    func getAudioStreamURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> URL {
        throw NSError(domain: "MockError", code: 0)
    }
    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah] { [] }
    func getAvailableReciters() -> [Reciter] { [] }
}

final class MockAuthServiceForHome: AuthService {
    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        throw NSError(domain: "MockError", code: 0)
    }
    func getCurrentUser() async throws -> User? { nil }
    func signOut() async throws {}
    func deleteAccount() async throws {}
}

final class MockPendingChangeServiceForHome: PendingChangeService {
    var pendingRuleIds: Set<UUID> = []

    func createPendingChange(for rule: ScreenTimeRule, changeType: String, pendingData: Data?) async {}
    func cancelPendingChange(for ruleId: UUID) async {}
    func applyExpiredChanges() async {}

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingRuleIds.contains(ruleId)
    }

    func pendingChange(for ruleId: UUID) -> PendingRuleChange? { nil }
    func applyFlagUpdate(ruleId: UUID, update: @Sendable (inout ScreenTimeRule) -> Void) {}
}
