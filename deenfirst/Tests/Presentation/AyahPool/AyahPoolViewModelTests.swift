import XCTest

@testable import DeenFirst

@MainActor
final class AyahPoolViewModelTests: XCTestCase {
    var mockPool: MockAyahPoolService!
    var mockQuran: MockQuranServiceForPool!
    var viewModel: AyahPoolViewModel!

    override func setUp() async throws {
        mockPool = MockAyahPoolService()
        mockQuran = MockQuranServiceForPool()
        viewModel = AyahPoolViewModel(ayahPoolService: mockPool, quranService: mockQuran)
    }

    override func tearDown() async throws {
        mockPool = nil
        mockQuran = nil
        viewModel = nil
    }

    // MARK: - Initial state

    func testInitialState_isEmpty() {
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertFalse(viewModel.isFull)
        XCTAssertEqual(viewModel.countLabel, "0 / 20")
    }

    // MARK: - load

    func testLoad_populatesItemsFromService() async {
        mockPool.pool = [
            makeItem(surah: 1, ayah: 2, addedAt: Date(timeIntervalSince1970: 1)),
            makeItem(surah: 2, ayah: 255, addedAt: Date(timeIntervalSince1970: 2)),
        ]
        viewModel.load()
        await waitForLoad()

        XCTAssertEqual(viewModel.count, 2)
        XCTAssertEqual(viewModel.countLabel, "2 / 20")
        XCTAssertFalse(viewModel.isEmpty)
    }

    func testLoad_sortsByAddedAtAscending() async {
        let earlier = makeItem(surah: 1, ayah: 1, addedAt: Date(timeIntervalSince1970: 100))
        let later = makeItem(surah: 2, ayah: 2, addedAt: Date(timeIntervalSince1970: 200))
        mockPool.pool = [later, earlier]
        viewModel.load()
        await waitForLoad()

        XCTAssertEqual(viewModel.items.first?.surahNumber, 1)
        XCTAssertEqual(viewModel.items.last?.surahNumber, 2)
    }

    func testLoad_populatesSurahNames() async {
        mockPool.pool = [makeItem(surah: 1, ayah: 1)]
        mockQuran.surahsToReturn = [
            makeSurah(number: 1, englishName: "Al-Fatihah"),
            makeSurah(number: 2, englishName: "Al-Baqarah"),
        ]
        viewModel.load()
        await waitForLoad()

        XCTAssertEqual(viewModel.displayLabel(for: viewModel.items[0]), "Al-Fatihah 1:1")
    }

    func testLoad_fallsBackToSurahNumberLabel_whenQuranServiceThrows() async {
        mockPool.pool = [makeItem(surah: 5, ayah: 10)]
        mockQuran.shouldThrow = true
        viewModel.load()
        await waitForLoad()

        XCTAssertEqual(viewModel.displayLabel(for: viewModel.items[0]), "Surah 5:10")
    }

    // MARK: - remove

    func testRemove_deletesFromServiceAndUpdatesList() async {
        let item1 = makeItem(surah: 1, ayah: 1, addedAt: Date(timeIntervalSince1970: 1))
        let item2 = makeItem(surah: 2, ayah: 2, addedAt: Date(timeIntervalSince1970: 2))
        mockPool.pool = [item1, item2]
        viewModel.load()
        await waitForLoad()

        viewModel.remove(id: item1.id)
        await waitForLoad()

        XCTAssertEqual(viewModel.count, 1)
        XCTAssertEqual(viewModel.items.first?.id, item2.id)
        XCTAssertEqual(mockPool.removedIds, [item1.id])
    }

    /// DF-050: Remove errors must surface to `errorMessage` instead of being swallowed.
    func testRemove_surfacesErrorMessage_whenServiceThrows() async {
        let item = makeItem(surah: 1, ayah: 1)
        mockPool.pool = [item]
        viewModel.load()
        await waitForLoad()

        mockPool.throwOnRemove = true
        viewModel.remove(id: item.id)
        await waitForLoad()

        XCTAssertNotNil(viewModel.errorMessage, "Remove failure must surface an error message to the user")
    }

    // MARK: - handleAddAyahsTap

    func testHandleAddAyahsTap_returnsTrue_whenNotFull() async {
        mockPool.pool = Array(repeating: (), count: 5).map { _ in makeItem(surah: 1, ayah: Int.random(in: 1...1000)) }
        viewModel.load()
        await waitForLoad()

        XCTAssertTrue(viewModel.handleAddAyahsTap())
        XCTAssertFalse(viewModel.showPoolFullAlert)
    }

    func testHandleAddAyahsTap_returnsFalseAndTriggersAlert_whenFull() async {
        mockPool.pool = (0..<20).map { i in makeItem(surah: 1, ayah: i + 1) }
        viewModel.load()
        await waitForLoad()

        XCTAssertTrue(viewModel.isFull)
        XCTAssertFalse(viewModel.handleAddAyahsTap())
        XCTAssertTrue(viewModel.showPoolFullAlert)
    }

    // MARK: - Helpers

    private func waitForLoad() async {
        // Yield a few times so the Task inside load()/remove() can run to completion.
        for _ in 0..<5 { await Task.yield() }
    }

    private func makeItem(
        surah: Int,
        ayah: Int,
        addedAt: Date = Date()
    ) -> AyahPoolItem {
        let item = AyahPoolItem(
            surahNumber: surah,
            ayahNumberInSurah: ayah,
            arabicText: "نص",
            transliteration: "nas",
            wordCount: 1
        )
        item.addedAt = addedAt
        return item
    }

    private func makeSurah(number: Int, englishName: String) -> Surah {
        Surah(
            number: number,
            name: englishName,
            englishName: englishName,
            englishNameTranslation: englishName,
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
    }
}

// MARK: - Mocks

@MainActor
final class MockAyahPoolService: AyahPoolService {
    struct AddCall {
        let surah: Int
        let ayah: Int
    }

    var pool: [AyahPoolItem] = []
    var removedIds: [UUID] = []
    var addedCalls: [AddCall] = []
    /// If set to N, the (N+1)th addAyah call throws `AyahPoolError.poolFull(max:)`.
    var throwPoolFullAfter: Int?
    /// If true, the next addAyah call throws `AyahPoolError.ayahTooShort(...)`.
    var throwAyahTooShortOnce = false
    /// Forces removeAyah to throw for error-surfacing tests.
    var throwOnRemove = false

    func fetchPool() async -> [AyahPoolItem] { pool }

    func addAyah(
        surahNumber: Int,
        ayahNumber: Int,
        arabicText: String,
        transliteration: String
    ) async throws {
        if throwAyahTooShortOnce {
            throwAyahTooShortOnce = false
            throw AyahPoolError.ayahTooShort(wordCount: 3, minimum: 5)
        }
        if let limit = throwPoolFullAfter, addedCalls.count >= limit {
            throw AyahPoolError.poolFull(max: 20)
        }
        addedCalls.append(AddCall(surah: surahNumber, ayah: ayahNumber))
    }

    func addAyahs(_ inputs: [AyahInput]) async -> AddAyahsResult {
        var added: [AyahPoolItem] = []
        var rejected: [AddAyahsResult.Rejection] = []
        for input in inputs {
            do {
                try await addAyah(
                    surahNumber: input.surahNumber,
                    ayahNumber: input.ayahNumber,
                    arabicText: input.arabicText,
                    transliteration: input.transliteration
                )
                let item = AyahPoolItem(
                    surahNumber: input.surahNumber,
                    ayahNumberInSurah: input.ayahNumber,
                    arabicText: input.arabicText,
                    transliteration: input.transliteration,
                    wordCount: 5
                )
                pool.append(item)
                added.append(item)
            } catch let error as AyahPoolError {
                rejected.append(
                    AddAyahsResult.Rejection(
                        surahNumber: input.surahNumber,
                        ayahNumberInSurah: input.ayahNumber,
                        reason: error
                    )
                )
                if case .poolFull = error { break }
            } catch {
                rejected.append(
                    AddAyahsResult.Rejection(
                        surahNumber: input.surahNumber,
                        ayahNumberInSurah: input.ayahNumber,
                        reason: .alreadyInPool
                    )
                )
            }
        }
        return AddAyahsResult(added: added, rejected: rejected)
    }

    func removeAyah(id: UUID) async throws {
        if throwOnRemove { throw MockRemoveError.forced }
        removedIds.append(id)
        pool.removeAll { $0.id == id }
    }

    func poolCount() async -> Int { pool.count }

    func nextAyah(excludeShort: Bool) -> AyahPoolItem? { nil }

    func isEmpty() async -> Bool { pool.isEmpty }
}

enum MockRemoveError: Error { case forced }

final class MockQuranServiceForPool: QuranService {
    var surahsToReturn: [Surah] = []
    var shouldThrow = false

    func loadAllSurahs() async throws -> [Surah] {
        if shouldThrow { throw QuranServiceError.invalidSurahNumber }
        return surahsToReturn
    }

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
