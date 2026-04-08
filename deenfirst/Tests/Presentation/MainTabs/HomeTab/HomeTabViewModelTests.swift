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
}
