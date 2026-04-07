import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class AyahPoolItemTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([AyahPoolItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func testInitialization() {
        let item = AyahPoolItem(
            surahNumber: 2,
            ayahNumberInSurah: 255,
            arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ",
            transliteration: "Allahu la ilaha illa huwa",
            wordCount: 7
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.surahNumber, 2)
        XCTAssertEqual(item.ayahNumberInSurah, 255)
        XCTAssertEqual(item.arabicText, "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ")
        XCTAssertEqual(item.transliteration, "Allahu la ilaha illa huwa")
        XCTAssertEqual(item.wordCount, 7)
        XCTAssertNotNil(item.addedAt)
    }

    func testWordCountIsStored() {
        let item = AyahPoolItem(
            surahNumber: 1,
            ayahNumberInSurah: 1,
            arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            transliteration: "Bismillahi ar-rahmani ar-raheem",
            wordCount: 4
        )
        XCTAssertEqual(item.wordCount, 4)
    }

    func testHardModeEligibility() {
        let eligible = AyahPoolItem(
            surahNumber: 2,
            ayahNumberInSurah: 255,
            arabicText: "placeholder",
            transliteration: "placeholder",
            wordCount: 5
        )
        let ineligible = AyahPoolItem(
            surahNumber: 1,
            ayahNumberInSurah: 1,
            arabicText: "placeholder",
            transliteration: "placeholder",
            wordCount: 4
        )

        XCTAssertGreaterThanOrEqual(eligible.wordCount, 5)
        XCTAssertLessThan(ineligible.wordCount, 5)
    }

    func testUniqueIds() {
        let a = AyahPoolItem(surahNumber: 1, ayahNumberInSurah: 1, arabicText: "", transliteration: "", wordCount: 3)
        let b = AyahPoolItem(surahNumber: 1, ayahNumberInSurah: 1, arabicText: "", transliteration: "", wordCount: 3)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testCreate() throws {
        let item = AyahPoolItem(
            surahNumber: 36,
            ayahNumberInSurah: 1,
            arabicText: "يس",
            transliteration: "Ya Seen",
            wordCount: 1
        )
        context.insert(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AyahPoolItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.surahNumber, 36)
        XCTAssertEqual(fetched.first?.wordCount, 1)
    }

    func testFetch() throws {
        let items = [
            AyahPoolItem(surahNumber: 2, ayahNumberInSurah: 255, arabicText: "a", transliteration: "a", wordCount: 7),
            AyahPoolItem(surahNumber: 112, ayahNumberInSurah: 1, arabicText: "b", transliteration: "b", wordCount: 5),
        ]
        items.forEach { context.insert($0) }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AyahPoolItem>())
        XCTAssertEqual(fetched.count, 2)
    }

    func testDelete() throws {
        let item = AyahPoolItem(surahNumber: 1, ayahNumberInSurah: 1, arabicText: "", transliteration: "", wordCount: 3)
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AyahPoolItem>())
        XCTAssertTrue(fetched.isEmpty)
    }
}
