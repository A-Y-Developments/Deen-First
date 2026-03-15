import XCTest

@testable import DeenFirst

final class QuranServiceTests: XCTestCase {
    var service: QuranServiceImpl!
    var mockRepository: MockQuranRepository!

    override func setUp() {
        mockRepository = MockQuranRepository()
        service = QuranServiceImpl(repository: mockRepository)
    }

    override func tearDown() {
        service = nil
        mockRepository = nil
    }

    func testLoadAllSurahs() async throws {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
        ]
        mockRepository.surahsToReturn = surahs

        let result = try await service.loadAllSurahs()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(mockRepository.getAllSurahsCallCount, 1)
    }

    func testLoadSurahWithValidNumber() async throws {
        let surah = Surah(
            number: 1, name: "Al-Fatihah", englishName: "The Opening",
            englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        let ayahs = [Ayah(number: 1, text: "Verse 1", numberInSurah: 1)]

        mockRepository.surahToReturn = (surah, ayahs)

        let (resultSurah, resultAyahs) = try await service.loadSurah(number: 1)

        XCTAssertEqual(resultSurah.number, 1)
        XCTAssertEqual(resultAyahs.count, 1)
        XCTAssertEqual(mockRepository.getSurahCallCount, 1)
    }

    func testLoadSurahWithInvalidNumber() async {
        do {
            _ = try await service.loadSurah(number: 0)
            XCTFail("Should throw invalid surah number error")
        } catch QuranServiceError.invalidSurahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }

        do {
            _ = try await service.loadSurah(number: 115)
            XCTFail("Should throw invalid surah number error")
        } catch QuranServiceError.invalidSurahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testLoadVerseWithValidNumbers() async throws {
        let verse = Ayah(
            number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah",
            arabic1: "بسم الله", arabic2: "بسم الله")

        mockRepository.verseToReturn = verse

        let result = try await service.loadVerse(surahNo: 1, ayahNo: 1)

        XCTAssertEqual(result.english, "In the name of Allah")
        XCTAssertEqual(mockRepository.getVerseCallCount, 1)
    }

    func testLoadVerseWithInvalidSurahNumber() async {
        do {
            _ = try await service.loadVerse(surahNo: 0, ayahNo: 1)
            XCTFail("Should throw invalid surah number error")
        } catch QuranServiceError.invalidSurahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testLoadVerseWithInvalidAyahNumber() async {
        do {
            _ = try await service.loadVerse(surahNo: 1, ayahNo: 0)
            XCTFail("Should throw invalid ayah number error")
        } catch QuranServiceError.invalidAyahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGetAudioStreamURL() async throws {
        mockRepository.audioURLToReturn = "https://example.com/audio.mp3"

        let url = try await service.getAudioStreamURL(reciterId: 1, surahNo: 1, ayahNo: 1)

        XCTAssertEqual(url.absoluteString, "https://example.com/audio.mp3")
        XCTAssertEqual(mockRepository.getAudioURLCallCount, 1)
    }

    func testGetAudioStreamURLInvalidURL() async {
        mockRepository.audioURLToReturn = "invalid url"

        do {
            _ = try await service.getAudioStreamURL(reciterId: 1, surahNo: 1, ayahNo: 1)
            XCTFail("Should throw invalid URL error")
        } catch QuranServiceError.invalidAudioURL {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSearchSurahsByName() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
            Surah(
                number: 114, name: "An-Nas", englishName: "Mankind",
                englishNameTranslation: "Mankind", numberOfAyahs: 6, revelationPlace: "Mecca"),
        ]

        let results = service.searchSurahs(query: "fatihah", in: surahs)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.number, 1)
    }

    func testSearchSurahsByTranslation() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
            Surah(
                number: 114, name: "An-Nas", englishName: "Mankind",
                englishNameTranslation: "Mankind", numberOfAyahs: 6, revelationPlace: "Mecca"),
        ]

        let results = service.searchSurahs(query: "cow", in: surahs)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.number, 2)
    }

    func testSearchSurahsByNumber() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
        ]

        let results = service.searchSurahs(query: "2", in: surahs)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.number, 2)
    }

    func testSearchSurahsCaseInsensitive() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
        ]

        let results1 = service.searchSurahs(query: "FATIHAH", in: surahs)
        let results2 = service.searchSurahs(query: "fatihah", in: surahs)
        let results3 = service.searchSurahs(query: "FaTiHaH", in: surahs)

        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 1)
        XCTAssertEqual(results3.count, 1)
    }

    func testSearchSurahsPartialMatch() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
        ]

        let results = service.searchSurahs(query: "Fat", in: surahs)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Al-Fatihah")
    }

    func testSearchSurahsEmptyQueryReturnsAll() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca"),
            Surah(
                number: 2, name: "Al-Baqarah", englishName: "The Cow",
                englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationPlace: "Medina"),
        ]

        let results = service.searchSurahs(query: "", in: surahs)

        XCTAssertEqual(results.count, 2)
    }

    func testSearchSurahsWhitespaceOnlyQueryReturnsAll() {
        let surahs = [
            Surah(
                number: 1, name: "Al-Fatihah", englishName: "The Opening",
                englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Mecca")
        ]

        let results = service.searchSurahs(query: "   ", in: surahs)

        XCTAssertEqual(results.count, 1)
    }

    func testGetAvailableReciters() {
        mockRepository.recitersToReturn = [
            Reciter(id: 1, name: "Mishary Rashid Al Afasy", style: nil),
            Reciter(id: 2, name: "Abu Bakr Al Shatri", style: nil),
        ]

        let reciters = service.getAvailableReciters()

        XCTAssertEqual(reciters.count, 2)
        XCTAssertEqual(reciters[0].name, "Mishary Rashid Al Afasy")
    }

    func testErrorMessageForInvalidSurahNumber() async {
        do {
            _ = try await service.loadSurah(number: 0)
            XCTFail("Should throw error")
        } catch let error as QuranServiceError {
            XCTAssertEqual(
                error.errorDescription,
                "Invalid surah number. Please enter a number between 1 and 114.")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}

// MARK: - Mock

class MockQuranRepository: QuranRepository {
    var surahsToReturn: [Surah] = []
    var surahToReturn: (Surah, [Ayah])?
    var verseToReturn: Ayah?
    var audioURLToReturn: String = ""
    var recitersToReturn: [Reciter] = []

    var getAllSurahsCallCount = 0
    var getSurahCallCount = 0
    var getVerseCallCount = 0
    var getAudioURLCallCount = 0

    func getAllSurahs() async throws -> [Surah] {
        getAllSurahsCallCount += 1
        return surahsToReturn
    }

    func getSurah(number: Int) async throws -> (Surah, [Ayah]) {
        getSurahCallCount += 1
        guard let result = surahToReturn else { throw QuranRepositoryError.invalidResponse }
        return result
    }

    func getVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        getVerseCallCount += 1
        guard let verse = verseToReturn else { throw QuranRepositoryError.invalidResponse }
        return verse
    }

    func getAudioURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> String {
        getAudioURLCallCount += 1
        return audioURLToReturn
    }

    func getReciters() -> [Reciter] {
        return recitersToReturn
    }
}
