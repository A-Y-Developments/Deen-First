import XCTest
@testable import SurahFocus

final class QuranRepositoryTests: XCTestCase {
    var repository: QuranRepositoryImpl!
    var mockAPIDataSource: MockQuranAPIDataSource!
    var cacheManager: QuranCacheManager!

    override func setUp() async throws {
        mockAPIDataSource = MockQuranAPIDataSource()
        cacheManager = QuranCacheManager()
        await cacheManager.clearCache()
        repository = QuranRepositoryImpl(apiDataSource: mockAPIDataSource, cacheManager: cacheManager)
    }

    override func tearDown() async throws {
        await cacheManager.clearCache()
        repository = nil
        mockAPIDataSource = nil
        cacheManager = nil
    }

    func testCacheHitReturnsCachedData() async throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        ]

        await cacheManager.cacheSurahList(surahs)
        mockAPIDataSource.shouldReturnError = false

        let result = try await repository.getAllSurahs()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIDataSource.fetchAllSurahsCallCount, 0)
    }

    func testCacheMissTriggersAPICall() async throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        ]
        mockAPIDataSource.surahsToReturn = surahs

        let result = try await repository.getAllSurahs()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIDataSource.fetchAllSurahsCallCount, 1)

        let cached = await cacheManager.getCachedSurahList()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }

    func testGetSurahCacheHit() async throws {
        let surah = Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        let ayahs = [Ayah(number: 1, text: "Verse 1", numberInSurah: 1)]

        await cacheManager.cacheSurah(number: 1, surah: surah, ayahs: ayahs)

        let (cachedSurah, cachedAyahs) = try await repository.getSurah(number: 1)

        XCTAssertEqual(cachedSurah.number, 1)
        XCTAssertEqual(cachedAyahs.count, 1)
        XCTAssertEqual(mockAPIDataSource.fetchSurahCallCount, 0)
    }

    func testGetSurahCacheMiss() async throws {
        let surah = Surah(number: 2, name: "Al-Baqarah", englishName: "The Cow", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina")
        let ayahs = [Ayah(number: 1, text: "Verse 1", numberInSurah: 1)]

        mockAPIDataSource.surahToReturn = (surah, ayahs)

        let (resultSurah, resultAyahs) = try await repository.getSurah(number: 2)

        XCTAssertEqual(resultSurah.number, 2)
        XCTAssertEqual(resultAyahs.count, 1)
        XCTAssertEqual(mockAPIDataSource.fetchSurahCallCount, 1)
    }

    func testGetVerseCacheHit() async throws {
        let verse = Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله")

        await cacheManager.cacheVerse(surahNo: 1, ayahNo: 1, verse: verse)

        let result = try await repository.getVerse(surahNo: 1, ayahNo: 1)

        XCTAssertEqual(result.english, "In the name of Allah")
        XCTAssertEqual(mockAPIDataSource.fetchVerseCallCount, 0)
    }

    func testGetVerseCacheMiss() async throws {
        let verse = Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله")

        mockAPIDataSource.verseToReturn = verse

        let result = try await repository.getVerse(surahNo: 1, ayahNo: 1)

        XCTAssertEqual(result.english, "In the name of Allah")
        XCTAssertEqual(mockAPIDataSource.fetchVerseCallCount, 1)
    }

    func testGetAudioURL() async throws {
        let audioUrls = [
            ReciterAudio(reciterId: 1, reciterName: "Mishary Rashid Al Afasy", url: "https://example.com/audio1.mp3", originalUrl: "https://example.com/orig1.mp3")
        ]
        let verse = Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله", audioUrls: audioUrls)

        await cacheManager.cacheVerse(surahNo: 1, ayahNo: 1, verse: verse)

        let url = try await repository.getAudioURL(reciterId: 1, surahNo: 1, ayahNo: 1)

        XCTAssertEqual(url, "https://example.com/audio1.mp3")
    }

    func testGetAudioURLReciterNotFound() async throws {
        let verse = Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله", audioUrls: [])

        await cacheManager.cacheVerse(surahNo: 1, ayahNo: 1, verse: verse)

        do {
            _ = try await repository.getAudioURL(reciterId: 1, surahNo: 1, ayahNo: 1)
            XCTFail("Should throw reciter not found error")
        } catch QuranRepositoryError.reciterNotFound {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGetReciters() {
        mockAPIDataSource.recitersToReturn = [
            Reciter(id: 1, name: "Test Reciter", style: nil)
        ]

        let reciters = repository.getReciters()

        XCTAssertEqual(reciters.count, 1)
        XCTAssertEqual(reciters.first?.name, "Test Reciter")
    }

    func testSpecificErrorMessageForNetworkError() async throws {
        mockAPIDataSource.shouldReturnError = true
        mockAPIDataSource.errorToReturn = QuranAPIError.invalidSurahNumber

        do {
            _ = try await repository.getAllSurahs()
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Mock

class MockQuranAPIDataSource: QuranAPIDataSource {
    var surahsToReturn: [Surah] = []
    var surahToReturn: (Surah, [Ayah])?
    var verseToReturn: Ayah?
    var recitersToReturn: [Reciter] = []

    var fetchAllSurahsCallCount = 0
    var fetchSurahCallCount = 0
    var fetchVerseCallCount = 0

    var shouldReturnError = false
    var errorToReturn: Error?

    func fetchAllSurahs() async throws -> [Surah] {
        fetchAllSurahsCallCount += 1
        if shouldReturnError { throw errorToReturn ?? QuranAPIError.invalidSurahNumber }
        return surahsToReturn
    }

    func fetchSurah(number: Int) async throws -> (Surah, [Ayah]) {
        fetchSurahCallCount += 1
        if shouldReturnError { throw errorToReturn ?? QuranAPIError.invalidSurahNumber }
        guard let result = surahToReturn else { throw QuranAPIError.noVersesFound }
        return result
    }

    func fetchVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        fetchVerseCallCount += 1
        if shouldReturnError { throw errorToReturn ?? QuranAPIError.invalidSurahNumber }
        guard let verse = verseToReturn else { throw QuranAPIError.noVersesFound }
        return verse
    }

    func getReciters() -> [Reciter] {
        return recitersToReturn
    }
}
