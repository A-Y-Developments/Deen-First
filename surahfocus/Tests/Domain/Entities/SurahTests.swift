import XCTest
@testable import SurahFocus

final class SurahTests: XCTestCase {

    func testSurahInitialization() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Mecca",
            surahNameArabic: "الفاتحة",
            surahNameArabicLong: "سورة الفاتحة"
        )

        XCTAssertEqual(surah.id, 1)
        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(surah.name, "Al-Fatihah")
        XCTAssertEqual(surah.englishName, "The Opening")
        XCTAssertEqual(surah.englishNameTranslation, "The Opening")
        XCTAssertEqual(surah.numberOfAyahs, 7)
        XCTAssertEqual(surah.revelationPlace, "Mecca")
        XCTAssertEqual(surah.surahNameArabic, "الفاتحة")
        XCTAssertEqual(surah.surahNameArabicLong, "سورة الفاتحة")
    }

    func testSurahInitializationWithDefaults() {
        let surah = Surah(
            number: 2,
            name: "Al-Baqarah",
            englishName: "The Cow",
            englishNameTranslation: "The Cow",
            numberOfAyahs: 286,
            revelationPlace: "Medina"
        )

        XCTAssertEqual(surah.surahNameArabic, "")
        XCTAssertEqual(surah.surahNameArabicLong, "")
    }

    func testSurahCodable() throws {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Mecca",
            surahNameArabic: "الفاتحة",
            surahNameArabicLong: "سورة الفاتحة"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(surah)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Surah.self, from: data)

        XCTAssertEqual(decoded.number, surah.number)
        XCTAssertEqual(decoded.name, surah.name)
        XCTAssertEqual(decoded.revelationPlace, surah.revelationPlace)
        XCTAssertEqual(decoded.surahNameArabic, surah.surahNameArabic)
    }

    func testSurahHashable() {
        let surah1 = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Mecca"
        )

        let surah2 = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Mecca"
        )

        XCTAssertEqual(surah1, surah2)
        let set: Set<Surah> = [surah1, surah2]
        XCTAssertEqual(set.count, 1)
    }
}
