import XCTest
@testable import SurahFocus

@MainActor
final class SurahDetailViewModelTests: XCTestCase {
    var viewModel: SurahDetailViewModel!
    var mockQuranService: MockQuranService!

    override func setUp() {
        mockQuranService = MockQuranService()
        viewModel = SurahDetailViewModel(
            surahNumber: 1,
            quranService: mockQuranService
        )
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.surahNumber, 1)
        XCTAssertNil(viewModel.surah)
        XCTAssertTrue(viewModel.ayahs.isEmpty)
        XCTAssertTrue(viewModel.showTranslation)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    func testLoadSurahDetailSuccess() async {
        let testSurah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Mecca"
        )
        let testAyahs = [
            Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah"),
            Ayah(number: 2, text: "Verse 2", numberInSurah: 2, english: "Allah, the Merciful")
        ]
        mockQuranService.surahToReturn = (testSurah, testAyahs)
        await viewModel.loadSurahDetail()
        XCTAssertNotNil(viewModel.surah)
        XCTAssertEqual(viewModel.surah?.number, 1)
        XCTAssertEqual(viewModel.ayahs.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testToggleTranslationChangesState() {
        XCTAssertTrue(viewModel.showTranslation)
        viewModel.toggleTranslation()
        XCTAssertFalse(viewModel.showTranslation)
        viewModel.toggleTranslation()
        XCTAssertTrue(viewModel.showTranslation)
    }
}
