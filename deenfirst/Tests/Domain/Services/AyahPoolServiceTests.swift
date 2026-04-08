import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class AyahPoolServiceTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var service: AyahPoolServiceImpl!

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
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "بِسْمِ اللَّهِ", transliteration: "Bismillah")
        try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: "اللَّهُ لَا إِلَٰهَ", transliteration: "Allahu la ilaha")
        let pool = await service.fetchPool()
        XCTAssertEqual(pool.count, 2)
    }

    // MARK: - addAyah

    func testAddAyah_storesWordCount() async throws {
        let arabic = "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ"
        let expectedCount = arabic.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: arabic, transliteration: "test")
        let pool = await service.fetchPool()
        XCTAssertEqual(pool.first?.wordCount, expectedCount)
    }

    func testAddAyah_wordCountNotRecomputed() async throws {
        let arabic = "كلمة كلمة كلمة"
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: arabic, transliteration: "t")
        let pool = await service.fetchPool()
        XCTAssertEqual(pool.first?.wordCount, 3)
    }

    func testAddAyah_throwsPoolFullAtMax() async throws {
        for i in 1...20 {
            try await service.addAyah(surahNumber: i, ayahNumber: 1, arabicText: "word", transliteration: "t")
        }
        do {
            try await service.addAyah(surahNumber: 21, ayahNumber: 1, arabicText: "word", transliteration: "t")
            XCTFail("Expected poolFull error")
        } catch AyahPoolError.poolFull {
            // expected
        }
    }

    func testAddAyah_doesNotExceedMaxAfterFull() async throws {
        for i in 1...20 {
            try await service.addAyah(surahNumber: i, ayahNumber: 1, arabicText: "word", transliteration: "t")
        }
        try? await service.addAyah(surahNumber: 21, ayahNumber: 1, arabicText: "word", transliteration: "t")
        let count = await service.poolCount()
        XCTAssertEqual(count, 20)
    }

    func testAddAyah_throwsAlreadyInPool() async throws {
        try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: "test", transliteration: "test")
        do {
            try await service.addAyah(surahNumber: 2, ayahNumber: 255, arabicText: "other", transliteration: "other")
            XCTFail("Expected alreadyInPool error")
        } catch AyahPoolError.alreadyInPool {
            // expected
        }
    }

    func testAddAyah_allowsDifferentAyahSameSurah() async throws {
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: "a", transliteration: "a")
        try await service.addAyah(surahNumber: 2, ayahNumber: 2, arabicText: "b", transliteration: "b")
        let count = await service.poolCount()
        XCTAssertEqual(count, 2)
    }

    func testAddAyah_allowsSameAyahDifferentSurah() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a", transliteration: "a")
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: "b", transliteration: "b")
        let count = await service.poolCount()
        XCTAssertEqual(count, 2)
    }

    // MARK: - removeAyah

    func testRemoveAyah_removesCorrectItem() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a", transliteration: "a")
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: "b", transliteration: "b")
        let pool = await service.fetchPool()
        guard let target = pool.first(where: { $0.surahNumber == 1 }) else {
            return XCTFail("Could not find item to remove")
        }
        await service.removeAyah(id: target.id)
        let remaining = await service.fetchPool()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.surahNumber, 2)
    }

    func testRemoveAyah_noOpForUnknownId() async {
        await service.removeAyah(id: UUID())
        let count = await service.poolCount()
        XCTAssertEqual(count, 0)
    }

    // MARK: - poolCount

    func testPoolCount_returnsZeroWhenEmpty() async {
        let count = await service.poolCount()
        XCTAssertEqual(count, 0)
    }

    func testPoolCount_incrementsOnAdd() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a", transliteration: "a")
        let count1 = await service.poolCount()
        XCTAssertEqual(count1, 1)
        try await service.addAyah(surahNumber: 2, ayahNumber: 1, arabicText: "b", transliteration: "b")
        let count2 = await service.poolCount()
        XCTAssertEqual(count2, 2)
    }

    // MARK: - isEmpty

    func testIsEmpty_trueWhenEmpty() async {
        let empty = await service.isEmpty()
        XCTAssertTrue(empty)
    }

    func testIsEmpty_falseAfterAdd() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a", transliteration: "a")
        let empty = await service.isEmpty()
        XCTAssertFalse(empty)
    }

    func testIsEmpty_trueAfterRemoveLast() async throws {
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a", transliteration: "a")
        let pool = await service.fetchPool()
        guard let item = pool.first else { return XCTFail("No item") }
        await service.removeAyah(id: item.id)
        let empty = await service.isEmpty()
        XCTAssertTrue(empty)
    }

    // MARK: - nextAyah

    func testNextAyah_returnsNilWhenEmpty() {
        XCTAssertNil(service.nextAyah(excludeShort: false))
        XCTAssertNil(service.nextAyah(excludeShort: true))
    }

    func testNextAyah_excludeShortFiltersShortAyah() async throws {
        // wordCount 3 — short
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a b c", transliteration: "abc")
        XCTAssertNil(service.nextAyah(excludeShort: true))
        XCTAssertNotNil(service.nextAyah(excludeShort: false))
    }

    func testNextAyah_excludeShortIncludesLongAyah() async throws {
        // wordCount >= 5
        try await service.addAyah(
            surahNumber: 2, ayahNumber: 255,
            arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ",
            transliteration: "Allahu la ilaha illa huwa"
        )
        XCTAssertNotNil(service.nextAyah(excludeShort: true))
    }

    func testNextAyah_returnsItemFromPool() async throws {
        try await service.addAyah(surahNumber: 36, ayahNumber: 1, arabicText: "يس", transliteration: "Ya Seen")
        let result = service.nextAyah(excludeShort: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.surahNumber, 36)
    }

    func testNextAyah_boundaryWordCountFive_includedWhenExcludeShort() async throws {
        // Exactly 5 words — eligible
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a b c d e", transliteration: "t")
        XCTAssertNotNil(service.nextAyah(excludeShort: true))
    }

    func testNextAyah_boundaryWordCountFour_excludedWhenExcludeShort() async throws {
        // Exactly 4 words — not eligible
        try await service.addAyah(surahNumber: 1, ayahNumber: 1, arabicText: "a b c d", transliteration: "t")
        XCTAssertNil(service.nextAyah(excludeShort: true))
    }
}
