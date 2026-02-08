import XCTest
@testable import SurahFocus

final class QuranCacheManagerTests: XCTestCase {
    var cacheManager: QuranCacheManager!

    override func setUp() async throws {
        cacheManager = QuranCacheManager()
        await cacheManager.clearCache()
    }

    override func tearDown() async throws {
        await cacheManager.clearCache()
    }

    func testCacheSurahList() async throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(number: 2, name: "Al-Baqarah", englishName: "The Cow", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina")
        ]

        await cacheManager.cacheSurahList(surahs)
        let cached = await cacheManager.getCachedSurahList()

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 2)
        XCTAssertEqual(cached?[0].number, 1)
        XCTAssertEqual(cached?[1].number, 2)
    }

    func testCacheSurahWithAyahs() async throws {
        let surah = Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        let ayahs = [
            Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله"),
            Ayah(number: 2, text: "Verse 2", numberInSurah: 2, english: "Praise be to Allah", arabic1: "الحمد لله", arabic2: "الحمد لله")
        ]

        await cacheManager.cacheSurah(number: 1, surah: surah, ayahs: ayahs)
        let cached = await cacheManager.getCachedSurah(number: 1)

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.0.number, 1)
        XCTAssertEqual(cached?.1.count, 2)
        XCTAssertEqual(cached?.1[0].english, "In the name of Allah")
    }

    func testCacheVerse() async throws {
        let verse = Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله")

        await cacheManager.cacheVerse(surahNo: 1, ayahNo: 1, verse: verse)
        let cached = await cacheManager.getCachedVerse(surahNo: 1, ayahNo: 1)

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.english, "In the name of Allah")
        XCTAssertEqual(cached?.arabic1, "بسم الله")
    }

    func testCacheMissReturnsNil() async throws {
        let cached = await cacheManager.getCachedSurahList()
        XCTAssertNil(cached)
    }

    func testClearCache() async throws {
        let surahs = [Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")]

        await cacheManager.cacheSurahList(surahs)
        var cached = await cacheManager.getCachedSurahList()
        XCTAssertNotNil(cached)

        await cacheManager.clearCache()
        cached = await cacheManager.getCachedSurahList()
        XCTAssertNil(cached)
    }

    func testDifferentSurahsDontOverlap() async throws {
        let surah1 = Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        let ayahs1 = [Ayah(number: 1, text: "Verse 1", numberInSurah: 1)]

        let surah2 = Surah(number: 2, name: "Al-Baqarah", englishName: "The Cow", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina")
        let ayahs2 = [Ayah(number: 2, text: "Verse 2", numberInSurah: 1)]

        await cacheManager.cacheSurah(number: 1, surah: surah1, ayahs: ayahs1)
        await cacheManager.cacheSurah(number: 2, surah: surah2, ayahs: ayahs2)

        let cached1 = await cacheManager.getCachedSurah(number: 1)
        let cached2 = await cacheManager.getCachedSurah(number: 2)

        XCTAssertEqual(cached1?.0.number, 1)
        XCTAssertEqual(cached2?.0.number, 2)
    }

    func testConcurrentCacheAccess() async throws {
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    let surah = Surah(number: i, name: "Surah \(i)", englishName: "Surah \(i)", englishNameTranslation: "Surah \(i)", numberOfAyahs: 7, revelationPlace: "Mecca")
                    let ayahs = [Ayah(number: i, text: "Verse \(i)", numberInSurah: 1)]
                    await self.cacheManager.cacheSurah(number: i, surah: surah, ayahs: ayahs)
                }
            }
        }

        for i in 1...10 {
            let cached = await cacheManager.getCachedSurah(number: i)
            XCTAssertNotNil(cached)
            XCTAssertEqual(cached?.0.number, i)
        }
    }

    func testCachePersistsAcrossInstances() async throws {
        let surahs = [Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")]

        await cacheManager.cacheSurahList(surahs)

        let newCacheManager = QuranCacheManager()
        let cached = await newCacheManager.getCachedSurahList()

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }

    func testDifferentVersesDontOverlap() async throws {
        let verse1 = Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "First verse", arabic1: "آية 1", arabic2: "آية 1")
        let verse2 = Ayah(number: 2, text: "Verse 2", numberInSurah: 2, english: "Second verse", arabic1: "آية 2", arabic2: "آية 2")

        await cacheManager.cacheVerse(surahNo: 1, ayahNo: 1, verse: verse1)
        await cacheManager.cacheVerse(surahNo: 1, ayahNo: 2, verse: verse2)

        let cached1 = await cacheManager.getCachedVerse(surahNo: 1, ayahNo: 1)
        let cached2 = await cacheManager.getCachedVerse(surahNo: 1, ayahNo: 2)

        XCTAssertEqual(cached1?.english, "First verse")
        XCTAssertEqual(cached2?.english, "Second verse")
    }
}
