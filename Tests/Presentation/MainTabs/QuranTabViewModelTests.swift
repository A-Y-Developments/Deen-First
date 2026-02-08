import XCTest
@testable import SurahFocus

@MainActor
final class QuranTabViewModelTests: XCTestCase {
    var viewModel: QuranTabViewModel!
    var mockQuranService: MockQuranService!
    var mockAuthService: MockAuthService!

    override func setUp() {
        mockQuranService = MockQuranService()
        mockAuthService = MockAuthService()
        viewModel = QuranTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService
        )
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.surahs.isEmpty)
        XCTAssertTrue(viewModel.filteredSurahs.isEmpty)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertNil(viewModel.user)
    }

    func testLoadSurahsSuccess() async {
        let testSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        ]
        mockQuranService.surahsToReturn = testSurahs
        await viewModel.loadSurahs()
        XCTAssertEqual(viewModel.surahs.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showError)
    }

    func testLoadSurahsLoadsUserStreak() async {
        let mockUser = User(appleUserId: "test123")
        mockUser.currentStreak = 5
        mockAuthService.userToReturn = mockUser
        await viewModel.loadSurahs()
        XCTAssertEqual(viewModel.currentStreak, 5)
    }

    func testSearchSurahsFiltersResults() async {
        let testSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(number: 2, name: "Al-Baqarah", englishName: "The Cow", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina")
        ]
        mockQuranService.surahsToReturn = testSurahs
        await viewModel.loadSurahs()
        viewModel.searchQuery = "fatihah"
        viewModel.searchSurahs()
        XCTAssertEqual(viewModel.filteredSurahs.count, 1)
        XCTAssertEqual(viewModel.filteredSurahs.first?.number, 1)
    }

    func testClearSearchRestoresAllSurahs() async {
        let testSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        ]
        mockQuranService.surahsToReturn = testSurahs
        await viewModel.loadSurahs()
        viewModel.searchQuery = "test"
        viewModel.searchSurahs()
        viewModel.clearSearch()
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.filteredSurahs.count, 1)
    }
}

class MockQuranService: QuranService {
    var surahsToReturn: [Surah] = []
    var surahToReturn: (Surah, [Ayah])?

    func loadAllSurahs() async throws -> [Surah] {
        return surahsToReturn
    }

    func loadSurah(number: Int) async throws -> (Surah, [Ayah]) {
        guard let result = surahToReturn else {
            throw QuranServiceError.invalidSurahNumber
        }
        return result
    }

    func loadVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        throw QuranServiceError.invalidAyahNumber
    }

    func getAudioStreamURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> URL {
        throw QuranServiceError.invalidAudioURL
    }

    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return surahs
        }
        return surahs.filter { surah in
            surah.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
            surah.englishNameTranslation.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
            String(surah.number).range(of: query, options: [.caseInsensitive]) != nil
        }
    }

    func getAvailableReciters() -> [Reciter] {
        return []
    }
}

class MockAuthService: AuthService {
    var userToReturn: User?

    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        throw AuthError.invalidCredential
    }

    func getCurrentUser() async throws -> User? {
        return userToReturn
    }

    func signOut() async throws {
        userToReturn = nil
    }
}
