import XCTest

@testable import DeenFirst

final class QuranAPIDataSourceTests: XCTestCase {
    var dataSource: QuranAPIDataSourceImpl!

    override func setUp() async throws {
        dataSource = QuranAPIDataSourceImpl(httpClient: .shared)
    }

    override func tearDown() {
        dataSource = nil
    }

    func testFetchAllSurahsReturns114Surahs() async throws {
        let surahs = try await dataSource.fetchAllSurahs()

        XCTAssertEqual(surahs.count, 114)
        XCTAssertEqual(surahs.first?.number, 1)
        XCTAssertEqual(surahs.first?.name, "Al-Faatiha")
        XCTAssertEqual(surahs.last?.number, 114)
        XCTAssertEqual(surahs.last?.name, "An-Naas")
    }

    func testFetchSurahWithValidNumber() async throws {
        let (surah, ayahs) = try await dataSource.fetchSurah(number: 1)

        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(surah.name, "Al-Faatiha")
        XCTAssertEqual(surah.numberOfAyahs, 7)
        XCTAssertFalse(ayahs.isEmpty)
        XCTAssertEqual(ayahs.count, 7)
        XCTAssertEqual(ayahs.first?.surahNo, 1)
    }

    func testFetchVerseWithValidNumbers() async throws {
        let ayah = try await dataSource.fetchVerse(surahNo: 1, ayahNo: 1)

        XCTAssertEqual(ayah.surahNo, 1)
        XCTAssertEqual(ayah.numberInSurah, 1)
        XCTAssertFalse(ayah.english.isEmpty)
        XCTAssertFalse(ayah.arabic1.isEmpty)
        XCTAssertFalse(ayah.audioUrls.isEmpty)
    }

    func testFetchVerseLargerSurah() async throws {
        let ayah = try await dataSource.fetchVerse(surahNo: 2, ayahNo: 255)

        XCTAssertEqual(ayah.surahNo, 2)
        XCTAssertEqual(ayah.numberInSurah, 255)
        XCTAssertEqual(ayah.surahName, "Al-Baqara")
    }

    func testInvalidSurahNumberThrowsError() async {
        do {
            _ = try await dataSource.fetchSurah(number: 0)
            XCTFail("Should throw error for invalid surah number")
        } catch QuranAPIError.invalidSurahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }

        do {
            _ = try await dataSource.fetchSurah(number: 115)
            XCTFail("Should throw error for invalid surah number")
        } catch QuranAPIError.invalidSurahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidVerseSurahNumberThrowsError() async {
        do {
            _ = try await dataSource.fetchVerse(surahNo: 0, ayahNo: 1)
            XCTFail("Should throw error for invalid surah number")
        } catch QuranAPIError.invalidSurahNumber {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testReciterListReturnsFiveReciters() {
        let reciters = dataSource.getReciters()

        XCTAssertEqual(reciters.count, 5)
        XCTAssertEqual(reciters[0].id, 1)
        XCTAssertEqual(reciters[0].name, "Mishary Rashid Al Afasy")
        XCTAssertEqual(reciters[1].id, 2)
        XCTAssertEqual(reciters[1].name, "Abu Bakr Al Shatri")
        XCTAssertEqual(reciters[2].id, 3)
        XCTAssertEqual(reciters[2].name, "Nasser Al Qatami")
        XCTAssertEqual(reciters[3].id, 4)
        XCTAssertEqual(reciters[3].name, "Yasser Al Dosari")
        XCTAssertEqual(reciters[4].id, 5)
        XCTAssertEqual(reciters[4].name, "Hani Ar Rifai")
    }

    func testVerseContainsAllFiveReciters() async throws {
        let ayah = try await dataSource.fetchVerse(surahNo: 1, ayahNo: 1)

        XCTAssertEqual(ayah.audioUrls.count, 5)

        let reciterIds = ayah.audioUrls.map { $0.reciterId }.sorted()
        XCTAssertEqual(reciterIds, [1, 2, 3, 4, 5])
    }

    func testSurahHasArabicNames() async throws {
        let (surah, _) = try await dataSource.fetchSurah(number: 1)

        XCTAssertFalse(surah.surahNameArabic.isEmpty)
        XCTAssertFalse(surah.surahNameArabicLong.isEmpty)
        // Check that it contains Arabic characters
        XCTAssertTrue(
            surah.surahNameArabic.unicodeScalars.contains {
                $0.value >= 0x0600 && $0.value <= 0x06FF
            })
    }

    func testSurahRevelationPlace() async throws {
        let meccanSurah = try await dataSource.fetchSurah(number: 1)
        XCTAssertEqual(meccanSurah.0.revelationPlace, "Mecca")

        let medinanSurah = try await dataSource.fetchSurah(number: 2)
        XCTAssertEqual(medinanSurah.0.revelationPlace, "Madina")
    }

    func testAyahHasEnglishTranslation() async throws {
        let ayah = try await dataSource.fetchVerse(surahNo: 1, ayahNo: 1)

        XCTAssertFalse(ayah.english.isEmpty)
        XCTAssertTrue(ayah.english.contains("Allah"))
    }

    func testAyahHasBothArabicScripts() async throws {
        let ayah = try await dataSource.fetchVerse(surahNo: 1, ayahNo: 1)

        XCTAssertFalse(ayah.arabic1.isEmpty)
        XCTAssertFalse(ayah.arabic2.isEmpty)
        XCTAssertNotEqual(ayah.arabic1, ayah.arabic2)
    }

    func testAudioUrlIsValid() async throws {
        let ayah = try await dataSource.fetchVerse(surahNo: 1, ayahNo: 1)

        for audio in ayah.audioUrls {
            XCTAssertTrue(audio.url.hasPrefix("http"))
            XCTAssertTrue(audio.originalUrl.hasPrefix("http"))
            XCTAssertTrue(audio.url.contains(".mp3"))
        }
    }
}
