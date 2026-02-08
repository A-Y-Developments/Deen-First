import XCTest
@testable import SurahFocus

final class AyahTests: XCTestCase {

    func testAyahInitialization() {
        let audioUrls = [
            ReciterAudio(
                reciterId: 1,
                reciterName: "Mishary Rashid Al Afasy",
                url: "https://example.com/audio1.mp3",
                originalUrl: "https://example.com/original1.mp3"
            )
        ]

        let ayah = Ayah(
            number: 1,
            text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            numberInSurah: 1,
            english: "In the name of Allah, the Entirely Merciful, the Especially Merciful",
            arabic1: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            arabic2: "بسم الله الرحمن الرحيم",
            audioUrls: audioUrls,
            surahNo: 1,
            surahName: "Al-Fatihah"
        )

        XCTAssertEqual(ayah.id, 1)
        XCTAssertEqual(ayah.number, 1)
        XCTAssertEqual(ayah.text, "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
        XCTAssertEqual(ayah.numberInSurah, 1)
        XCTAssertEqual(ayah.english, "In the name of Allah, the Entirely Merciful, the Especially Merciful")
        XCTAssertEqual(ayah.arabic1, "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
        XCTAssertEqual(ayah.arabic2, "بسم الله الرحمن الرحيم")
        XCTAssertEqual(ayah.audioUrls.count, 1)
        XCTAssertEqual(ayah.surahNo, 1)
        XCTAssertEqual(ayah.surahName, "Al-Fatihah")
    }

    func testAyahInitializationWithDefaults() {
        let ayah = Ayah(
            number: 1,
            text: "Test text",
            numberInSurah: 1
        )

        XCTAssertEqual(ayah.english, "")
        XCTAssertEqual(ayah.arabic1, "")
        XCTAssertEqual(ayah.arabic2, "")
        XCTAssertTrue(ayah.audioUrls.isEmpty)
        XCTAssertEqual(ayah.surahNo, 0)
        XCTAssertEqual(ayah.surahName, "")
    }

    func testAyahCodable() throws {
        let audioUrls = [
            ReciterAudio(
                reciterId: 1,
                reciterName: "Mishary Rashid Al Afasy",
                url: "https://example.com/audio1.mp3",
                originalUrl: "https://example.com/original1.mp3"
            )
        ]

        let ayah = Ayah(
            number: 1,
            text: "Test",
            numberInSurah: 1,
            english: "Translation",
            arabic1: "Arabic1",
            arabic2: "Arabic2",
            audioUrls: audioUrls,
            surahNo: 1,
            surahName: "Al-Fatihah"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(ayah)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Ayah.self, from: data)

        XCTAssertEqual(decoded.number, ayah.number)
        XCTAssertEqual(decoded.english, ayah.english)
        XCTAssertEqual(decoded.arabic1, ayah.arabic1)
        XCTAssertEqual(decoded.audioUrls.count, ayah.audioUrls.count)
    }

    func testAyahHashable() {
        let audioUrls = [
            ReciterAudio(
                reciterId: 1,
                reciterName: "Test",
                url: "https://example.com/audio.mp3",
                originalUrl: "https://example.com/original.mp3"
            )
        ]

        let ayah1 = Ayah(
            number: 1,
            text: "Test",
            numberInSurah: 1,
            english: "Translation",
            arabic1: "Arabic1",
            arabic2: "Arabic2",
            audioUrls: audioUrls,
            surahNo: 1,
            surahName: "Al-Fatihah"
        )

        let ayah2 = Ayah(
            number: 1,
            text: "Test",
            numberInSurah: 1,
            english: "Translation",
            arabic1: "Arabic1",
            arabic2: "Arabic2",
            audioUrls: audioUrls,
            surahNo: 1,
            surahName: "Al-Fatihah"
        )

        XCTAssertEqual(ayah1, ayah2)
    }
}
