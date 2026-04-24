import AuthenticationServices
import XCTest

@testable import DeenFirst

@MainActor
final class QuranTabViewModelTests: XCTestCase {
    var mockQuran: MockQuranServiceForQuranTab!
    var mockAuth: MockAuthServiceForQuranTab!
    var mockNotif: MockNotificationPermissionServiceForQuranTab!
    var mockPool: MockAyahPoolService!
    var viewModel: QuranTabViewModel!

    override func setUp() async throws {
        mockQuran = MockQuranServiceForQuranTab()
        mockAuth = MockAuthServiceForQuranTab()
        mockNotif = MockNotificationPermissionServiceForQuranTab()
        mockPool = MockAyahPoolService()
        viewModel = QuranTabViewModel(
            quranService: mockQuran,
            authService: mockAuth,
            notificationPermissionService: mockNotif,
            ayahPoolService: mockPool
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockQuran = nil
        mockAuth = nil
        mockNotif = nil
        mockPool = nil
    }

    func testInitialAyahPoolCount_isZero() {
        XCTAssertEqual(viewModel.ayahPoolCount, 0)
    }

    func testLoadAyahPoolCount_reflectsServicePoolSize() async {
        mockPool.pool = [
            makeItem(surah: 1, ayah: 1),
            makeItem(surah: 2, ayah: 2),
            makeItem(surah: 3, ayah: 3),
        ]

        await viewModel.loadAyahPoolCount()

        XCTAssertEqual(viewModel.ayahPoolCount, 3)
    }

    func testLoadAyahPoolCount_whenEmpty_isZero() async {
        mockPool.pool = []

        await viewModel.loadAyahPoolCount()

        XCTAssertEqual(viewModel.ayahPoolCount, 0)
    }

    func testLoadAyahPoolCount_updatesAfterPoolChange() async {
        mockPool.pool = [makeItem(surah: 1, ayah: 1)]
        await viewModel.loadAyahPoolCount()
        XCTAssertEqual(viewModel.ayahPoolCount, 1)

        mockPool.pool.append(makeItem(surah: 2, ayah: 2))
        await viewModel.loadAyahPoolCount()
        XCTAssertEqual(viewModel.ayahPoolCount, 2)
    }

    func testAyahPoolMaxSize_matchesCanonicalConstant() {
        XCTAssertEqual(viewModel.ayahPoolMaxSize, AyahPoolServiceImpl.maxPoolSize)
    }

    // MARK: - Helpers

    private func makeItem(surah: Int, ayah: Int) -> AyahPoolItem {
        AyahPoolItem(
            surahNumber: surah,
            ayahNumberInSurah: ayah,
            arabicText: "نص",
            transliteration: "nas",
            wordCount: 1
        )
    }
}

// MARK: - Mocks

final class MockQuranServiceForQuranTab: QuranService {
    func loadAllSurahs() async throws -> [Surah] { [] }
    func loadSurah(number: Int) async throws -> (Surah, [Ayah]) {
        throw QuranServiceError.invalidSurahNumber
    }
    func loadVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        throw QuranServiceError.invalidAyahNumber
    }
    func getAudioStreamURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> URL {
        throw QuranServiceError.invalidAudioURL
    }
    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah] { surahs }
    func getAvailableReciters() -> [Reciter] { [] }
}

final class MockAuthServiceForQuranTab: AuthService {
    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        throw NSError(domain: "test", code: 0)
    }
    func getCurrentUser() async throws -> User? { nil }
    func signOut() async throws {}
    func deleteAccount() async throws {}
}

final class MockNotificationPermissionServiceForQuranTab: NotificationPermissionService {
    func requestAuthorizationIfNeeded() async -> Bool { false }
}
