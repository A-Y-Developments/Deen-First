import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class AyahPoolServiceTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var service: AyahPoolServiceImpl!

    /// Five-word Arabic ayah snippet — passes `minWordCountForEligibility`.
    private let eligibleArabic = "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ"

    override func setUp() async throws {
        let schema = Schema([AyahPoolItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        service = AyahPoolServiceImpl(localDataSource: localDataSource)
    }

    override func tearDown() async throws {
        container = nil
        localDataSource = nil
        service = nil
    }

    // MARK: - fetchPool

    func testFetchPool_returnsEmptyWhenNoItems() async {
        let pool = await service.fetchPool()
        XCTAssertTrue(pool.isEmpty)
    }

    func testFetchPool_returnsAllItems() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "Bismillah")
        try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: eligibleArabic, transliteration: "Allahu la ilaha")
        let pool = await service.fetchPool()
        XCTAssertEqual(pool.count, 2)
    }

    // MARK: - addAyah

    func testAddAyah_storesWordCount() async throws {
        let expectedCount = eligibleArabic.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: eligibleArabic, transliteration: "test")
        let pool = await service.fetchPool()
        XCTAssertEqual(pool.first?.wordCount, expectedCount)
    }

    func testAddAyah_rejectsAyahShorterThanMinimum() async {
        do {
            try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "كلمة كلمة كلمة", transliteration: "t")
            XCTFail("Expected ayahTooShort error")
        } catch AyahPoolError.ayahTooShort(let wordCount, let minimum) {
            XCTAssertEqual(wordCount, 3)
            XCTAssertEqual(minimum, 5)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        let count = await service.poolCount()
        XCTAssertEqual(count, 0, "Rejected ayahs must not be persisted")
    }

    func testAddAyah_acceptsExactlyFiveWords() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a b c d e", transliteration: "t")
        let count = await service.poolCount()
        XCTAssertEqual(count, 1)
    }

    func testAddAyah_throwsPoolFullAtMax() async throws {
        for i in 1...20 {
            try await service.addAyah(surahNumber: i, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "t")
        }
        do {
            try await service.addAyah(surahNumber: 21, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "t")
            XCTFail("Expected poolFull error")
        } catch AyahPoolError.poolFull(let max) {
            XCTAssertEqual(max, 20)
        }
    }

    func testAddAyah_doesNotExceedMaxAfterFull() async throws {
        for i in 1...20 {
            try await service.addAyah(surahNumber: i, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "t")
        }
        try? await service.addAyah(surahNumber: 21, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "t")
        let count = await service.poolCount()
        XCTAssertEqual(count, 20)
    }

    func testAddAyah_throwsAlreadyInPool() async throws {
        try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: eligibleArabic, transliteration: "test")
        do {
            try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: eligibleArabic, transliteration: "other")
            XCTFail("Expected alreadyInPool error")
        } catch AyahPoolError.alreadyInPool {
            // expected
        }
    }

    func testAddAyah_allowsDifferentAyahSameSurah() async throws {
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a")
        try await service.addAyah(surahNumber: 2, ayahNumber: 2, arabicText: eligibleArabic, transliteration: "b")
        let count = await service.poolCount()
        XCTAssertEqual(count, 2)
    }

    func testAddAyah_allowsSameAyahDifferentSurah() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a")
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "b")
        let count = await service.poolCount()
        XCTAssertEqual(count, 2)
    }

    // MARK: - removeAyah

    func testRemoveAyah_removesCorrectItem() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a")
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "b")
        let pool = await service.fetchPool()
        guard let target = pool.first(where: { $0.surahNumber == 1 }) else {
            return XCTFail("Could not find item to remove")
        }
        try await service.removeAyah(id: target.id)
        let remaining = await service.fetchPool()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.surahNumber, 2)
    }

    func testRemoveAyah_noOpForUnknownId() async throws {
        try await service.removeAyah(id: UUID())
        let count = await service.poolCount()
        XCTAssertEqual(count, 0)
    }

    // MARK: - poolCount

    func testPoolCount_returnsZeroWhenEmpty() async {
        let count = await service.poolCount()
        XCTAssertEqual(count, 0)
    }

    func testPoolCount_incrementsOnAdd() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a")
        let count1 = await service.poolCount()
        XCTAssertEqual(count1, 1)
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "b")
        let count2 = await service.poolCount()
        XCTAssertEqual(count2, 2)
    }

    // MARK: - isEmpty

    func testIsEmpty_trueWhenEmpty() async {
        let empty = await service.isEmpty()
        XCTAssertTrue(empty)
    }

    func testIsEmpty_falseAfterAdd() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a")
        let empty = await service.isEmpty()
        XCTAssertFalse(empty)
    }

    func testIsEmpty_trueAfterRemoveLast() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a")
        let pool = await service.fetchPool()
        guard let item = pool.first else { return XCTFail("No item") }
        try await service.removeAyah(id: item.id)
        let empty = await service.isEmpty()
        XCTAssertTrue(empty)
    }

    // MARK: - nextAyah

    func testNextAyah_returnsNilWhenEmpty() {
        XCTAssertNil(service.nextAyah(excludeShort: false))
        XCTAssertNil(service.nextAyah(excludeShort: true))
    }

    /// Defense-in-depth: even if a short ayah ends up in the store (migration, older data),
    /// `nextAyah(excludeShort: true)` must filter it out.
    func testNextAyah_excludeShortFiltersShortAyah() throws {
        let short = AyahPoolItem(
            surahNumber: 1, ayahNumberInSurah: 1,
            arabicText: "a b c", transliteration: "abc", wordCount: 3
        )
        try localDataSource.insertAyahPoolItem(short)
        XCTAssertNil(service.nextAyah(excludeShort: true))
        XCTAssertNotNil(service.nextAyah(excludeShort: false))
    }

    func testNextAyah_excludeShortIncludesLongAyah() async throws {
        try await service.addAyah(
            surahNumber: 2, ayahNumber: 255,
            arabicText: eligibleArabic,
            transliteration: "Allahu la ilaha illa huwa"
        )
        XCTAssertNotNil(service.nextAyah(excludeShort: true))
    }

    func testNextAyah_boundaryWordCountFive_includedWhenExcludeShort() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a b c d e", transliteration: "t")
        XCTAssertNotNil(service.nextAyah(excludeShort: true))
    }

    func testNextAyah_boundaryWordCountFour_excludedWhenExcludeShort() throws {
        let fourWord = AyahPoolItem(
            surahNumber: 1, ayahNumberInSurah: 1,
            arabicText: "a b c d", transliteration: "t", wordCount: 4
        )
        try localDataSource.insertAyahPoolItem(fourWord)
        XCTAssertNil(service.nextAyah(excludeShort: true))
    }

    // MARK: - addAyahs (batch)

    /// DF-054: addAyahs must return per-input add/reject outcomes for mixed batches.
    func testAddAyahs_mixedBatch_returnsAddedAndRejectedPerInput() async {
        let inputs = [
            AyahInput(surahNumber: 1, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a"),
            AyahInput(surahNumber: 2, ayahNumber: 1, arabicText: "a b c", transliteration: "short"),
            AyahInput(surahNumber: 3, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "c"),
        ]

        let result = await service.addAyahs(inputs)

        XCTAssertEqual(result.added.count, 2, "Two eligible ayahs must be added")
        XCTAssertEqual(result.rejected.count, 1, "One short ayah must be rejected")
        XCTAssertEqual(result.rejected.first?.surahNumber, 2)
        if case .ayahTooShort(let wc, let min) = result.rejected.first?.reason {
            XCTAssertEqual(wc, 3)
            XCTAssertEqual(min, 5)
        } else {
            XCTFail("Expected ayahTooShort rejection, got \(String(describing: result.rejected.first?.reason))")
        }
        XCTAssertFalse(result.didHitPoolFull)
    }

    /// DF-054: addAyahs stops on first poolFull and reports partial success.
    func testAddAyahs_stopsOnPoolFull_reportsPartial() async throws {
        for i in 1...19 {
            try await service.addAyah(surahNumber: i, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "t")
        }
        let inputs = [
            AyahInput(surahNumber: 100, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "a"),
            AyahInput(surahNumber: 101, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "b"),
            AyahInput(surahNumber: 102, ayahNumber: 1, arabicText: eligibleArabic, transliteration: "c"),
        ]

        let result = await service.addAyahs(inputs)

        XCTAssertEqual(result.added.count, 1, "Only one slot remained")
        XCTAssertTrue(result.didHitPoolFull)
    }

    // MARK: - Canonical constant access via protocol

    /// DF-051: Track A and other clients must be able to read the cap through the
    /// protocol name (not only `AyahPoolServiceImpl`).
    func testProtocolExposesCanonicalMaxPoolSize() {
        XCTAssertEqual(AyahPoolServiceImpl.maxPoolSize, 20)
        let impl: AyahPoolService = service
        XCTAssertEqual(type(of: impl).maxPoolSize, 20)
    }
}
