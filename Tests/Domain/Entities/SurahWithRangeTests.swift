import XCTest
@testable import SurahFocus

final class SurahWithRangeTests: XCTestCase {
    func testInitialization() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 1, endAyah: 7)

        XCTAssertEqual(surahWithRange.id, 1)
        XCTAssertEqual(surahWithRange.surah.number, 1)
        XCTAssertEqual(surahWithRange.startAyah, 1)
        XCTAssertEqual(surahWithRange.endAyah, 7)
    }

    func testAyahRange() {
        let surah = Surah(
            number: 2,
            name: "Al-Baqarah",
            englishName: "The Cow",
            englishNameTranslation: "The Cow",
            numberOfAyahs: 286,
            revelationPlace: "Medinan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 100, endAyah: 200)

        XCTAssertEqual(surahWithRange.ayahRange.lowerBound, 100)
        XCTAssertEqual(surahWithRange.ayahRange.upperBound, 200)
        XCTAssertEqual(surahWithRange.ayahCount, 101)
    }

    func testAyahRangeReversed() {
        let surah = Surah(
            number: 2,
            name: "Al-Baqarah",
            englishName: "The Cow",
            englishNameTranslation: "The Cow",
            numberOfAyahs: 286,
            revelationPlace: "Medinan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 200, endAyah: 100)

        XCTAssertEqual(surahWithRange.ayahRange.lowerBound, 100)
        XCTAssertEqual(surahWithRange.ayahRange.upperBound, 200)
        XCTAssertEqual(surahWithRange.ayahCount, 101)
    }

    func testAyahNumbers() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 3, endAyah: 5)

        let numbers = surahWithRange.ayahNumbers()
        XCTAssertEqual(numbers, [3, 4, 5])
    }

    func testIsValidTrue() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 1, endAyah: 7)

        XCTAssertTrue(surahWithRange.isValid)
    }

    func testIsValidFalseStartGreaterThanEnd() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 5, endAyah: 2)

        XCTAssertFalse(surahWithRange.isValid)
    }

    func testIsValidFalseStartLessThanOne() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 0, endAyah: 7)

        XCTAssertFalse(surahWithRange.isValid)
    }

    func testIsValidFalseEndGreaterThanTotal() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 1, endAyah: 10)

        XCTAssertFalse(surahWithRange.isValid)
    }

    func testTotalAyahs() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let surahWithRange = SurahWithRange(surah: surah, startAyah: 1, endAyah: 7)

        XCTAssertEqual(surahWithRange.totalAyahs, 7)
    }

    func testHashable() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let range1 = SurahWithRange(surah: surah, startAyah: 1, endAyah: 7)
        let range2 = SurahWithRange(surah: surah, startAyah: 1, endAyah: 7)

        XCTAssertEqual(range1, range2)
        XCTAssertEqual(range1.hashValue, range2.hashValue)
    }

    func testHashableDifferentRange() {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let range1 = SurahWithRange(surah: surah, startAyah: 1, endAyah: 3)
        let range2 = SurahWithRange(surah: surah, startAyah: 1, endAyah: 7)

        XCTAssertNotEqual(range1, range2)
    }
}
