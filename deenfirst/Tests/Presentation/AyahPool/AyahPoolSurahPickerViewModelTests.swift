import XCTest

@testable import DeenFirst

@MainActor
final class AyahPoolSurahPickerViewModelTests: XCTestCase {
    var mockPool: MockAyahPoolService!
    var mockQuran: MockQuranServiceForPicker!
    var viewModel: AyahPoolSurahPickerViewModel!

    override func setUp() async throws {
        mockPool = MockAyahPoolService()
        mockQuran = MockQuranServiceForPicker()
        viewModel = AyahPoolSurahPickerViewModel(
            ayahPoolService: mockPool,
            quranService: mockQuran
        )
    }

    override func tearDown() async throws {
        mockPool = nil
        mockQuran = nil
        viewModel = nil
    }

    // MARK: - loadInitial

    func testLoadInitial_populatesSurahsAndPooledKeys() async {
        mockQuran.surahsToReturn = [
            makeSurah(number: 1, englishName: "Al-Fatihah"),
            makeSurah(number: 2, englishName: "Al-Baqarah"),
        ]
        mockPool.pool = [
            makeItem(surah: 1, ayah: 2),
            makeItem(surah: 2, ayah: 255),
        ]

        viewModel.loadInitial()
        await yield()

        XCTAssertEqual(viewModel.allSurahs.count, 2)
        XCTAssertEqual(viewModel.filteredSurahs.count, 2)
        XCTAssertEqual(viewModel.pooledCount, 2)
        XCTAssertTrue(viewModel.pooledKeys.contains(AyahKey(surah: 1, ayah: 2)))
        XCTAssertTrue(viewModel.pooledKeys.contains(AyahKey(surah: 2, ayah: 255)))
    }

    // MARK: - Search

    func testApplySearch_filtersByEnglishName() async {
        mockQuran.surahsToReturn = [
            makeSurah(number: 1, englishName: "Al-Fatihah"),
            makeSurah(number: 2, englishName: "Al-Baqarah"),
        ]
        viewModel.loadInitial()
        await yield()

        viewModel.searchText = "Baqarah"
        viewModel.applySearch()

        XCTAssertEqual(viewModel.filteredSurahs.count, 1)
        XCTAssertEqual(viewModel.filteredSurahs.first?.number, 2)
    }

    func testApplySearch_emptyQuery_returnsAll() async {
        mockQuran.surahsToReturn = [
            makeSurah(number: 1, englishName: "Al-Fatihah"),
            makeSurah(number: 2, englishName: "Al-Baqarah"),
        ]
        viewModel.loadInitial()
        await yield()

        viewModel.searchText = "   "
        viewModel.applySearch()

        XCTAssertEqual(viewModel.filteredSurahs.count, 2)
    }

    // MARK: - Surah selection

    func testSelectSurah_loadsAyahs() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1), makeAyah(number: 2)]
        viewModel.loadInitial()
        await yield()

        viewModel.selectSurah(surah)
        await yield()

        XCTAssertEqual(viewModel.selectedSurah?.number, 1)
        XCTAssertEqual(viewModel.ayahs.count, 2)
    }

    func testBackToSurahList_clearsState() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        viewModel.backToSurahList()

        XCTAssertNil(viewModel.selectedSurah)
        XCTAssertTrue(viewModel.ayahs.isEmpty)
    }

    // MARK: - Ayah selection

    func testToggleSelection_addsToNewlySelected() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        let added = viewModel.toggleSelection(viewModel.ayahs[0])

        XCTAssertTrue(added)
        XCTAssertTrue(viewModel.isSelected(viewModel.ayahs[0]))
    }

    func testToggleSelection_twice_removes() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        viewModel.toggleSelection(viewModel.ayahs[0])
        viewModel.toggleSelection(viewModel.ayahs[0])

        XCTAssertFalse(viewModel.isSelected(viewModel.ayahs[0]))
    }

    func testToggleSelection_pooledAyah_isBlocked() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 5)]
        mockPool.pool = [makeItem(surah: 1, ayah: 5)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        XCTAssertTrue(viewModel.isPooled(viewModel.ayahs[0]))
        let result = viewModel.toggleSelection(viewModel.ayahs[0])

        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isSelected(viewModel.ayahs[0]))
    }

    func testToggleSelection_atCapacity_triggersPoolFullAlert() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = (1...25).map { makeAyah(number: $0) }
        // Pool already has 19 items
        mockPool.pool = (100..<119).map { makeItem(surah: 99, ayah: $0) }
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        // Fill the remaining slot
        XCTAssertTrue(viewModel.toggleSelection(viewModel.ayahs[0]))
        // Next toggle should be blocked
        let blocked = viewModel.toggleSelection(viewModel.ayahs[1])

        XCTAssertFalse(blocked)
        XCTAssertTrue(viewModel.showPoolFullAlert)
    }

    // MARK: - addSelected

    func testAddSelected_callsServiceForEachSelection() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1), makeAyah(number: 2), makeAyah(number: 3)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        viewModel.toggleSelection(viewModel.ayahs[0])
        viewModel.toggleSelection(viewModel.ayahs[2])

        viewModel.addSelected()
        await yield()

        XCTAssertEqual(mockPool.addedCalls.count, 2)
        XCTAssertTrue(mockPool.addedCalls.contains { $0.surah == 1 && $0.ayah == 1 })
        XCTAssertTrue(mockPool.addedCalls.contains { $0.surah == 1 && $0.ayah == 3 })
        XCTAssertTrue(viewModel.didFinishAdding)
    }

    func testAddSelected_whenServiceReportsPoolFull_stopsAndShowsAlert() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1), makeAyah(number: 2)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        viewModel.toggleSelection(viewModel.ayahs[0])
        viewModel.toggleSelection(viewModel.ayahs[1])
        mockPool.throwPoolFullAfter = 1

        viewModel.addSelected()
        await yield()

        XCTAssertEqual(mockPool.addedCalls.count, 1)
        XCTAssertTrue(viewModel.showPoolFullAlert)
        XCTAssertFalse(viewModel.didFinishAdding)
    }

    func testAddSelected_noSelection_isNoop() async {
        let surah = makeSurah(number: 1, englishName: "Al-Fatihah")
        mockQuran.surahsToReturn = [surah]
        mockQuran.ayahsToReturn = [makeAyah(number: 1)]
        viewModel.loadInitial()
        await yield()
        viewModel.selectSurah(surah)
        await yield()

        viewModel.addSelected()
        await yield()

        XCTAssertEqual(mockPool.addedCalls.count, 0)
        XCTAssertFalse(viewModel.didFinishAdding)
    }

    // MARK: - Helpers

    private func yield() async {
        for _ in 0..<5 { await Task.yield() }
    }

    private func makeSurah(number: Int, englishName: String) -> Surah {
        Surah(
            number: number,
            name: englishName,
            englishName: englishName,
            englishNameTranslation: englishName,
            numberOfAyahs: 10,
            revelationPlace: "Meccan"
        )
    }

    private func makeAyah(number: Int) -> Ayah {
        Ayah(
            number: number,
            text: "نص \(number)",
            numberInSurah: number,
            transliteration: "nas \(number)"
        )
    }

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

final class MockQuranServiceForPicker: QuranService {
    var surahsToReturn: [Surah] = []
    var ayahsToReturn: [Ayah] = []
    var shouldThrowOnLoadAll = false
    var shouldThrowOnLoadSurah = false

    func loadAllSurahs() async throws -> [Surah] {
        if shouldThrowOnLoadAll { throw QuranServiceError.invalidSurahNumber }
        return surahsToReturn
    }

    func loadSurah(number: Int) async throws -> (Surah, [Ayah]) {
        if shouldThrowOnLoadSurah { throw QuranServiceError.invalidSurahNumber }
        guard let surah = surahsToReturn.first(where: { $0.number == number }) else {
            throw QuranServiceError.invalidSurahNumber
        }
        return (surah, ayahsToReturn)
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
