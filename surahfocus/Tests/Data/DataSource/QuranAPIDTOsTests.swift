import XCTest
@testable import SurahFocus

final class QuranAPIDTOsTests: XCTestCase {

    func testSingleVerseResponseDecoding() throws {
        let json = """
        {
            "surahName": "Al-Fatihah",
            "surahNameArabic": "الفاتحة",
            "surahNameArabicLong": "سورة الفاتحة",
            "surahNameTranslation": "The Opening",
            "revelationPlace": "Mecca",
            "totalAyah": 7,
            "surahNo": 1,
            "ayahNo": 1,
            "audio": {
                "1": {
                    "reciter": "Mishary Rashid Al Afasy",
                    "url": "https://example.com/audio1.mp3",
                    "originalUrl": "https://example.com/original1.mp3"
                },
                "2": {
                    "reciter": "Abu Bakr Al Shatri",
                    "url": "https://example.com/audio2.mp3",
                    "originalUrl": "https://example.com/original2.mp3"
                }
            },
            "english": "In the name of Allah, the Entirely Merciful, the Especially Merciful",
            "arabic1": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            "arabic2": "بسم الله الرحمن الرحيم"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SingleVerseResponse.self, from: data)

        XCTAssertEqual(response.surahName, "Al-Fatihah")
        XCTAssertEqual(response.surahNameArabic, "الفاتحة")
        XCTAssertEqual(response.surahNameArabicLong, "سورة الفاتحة")
        XCTAssertEqual(response.surahNameTranslation, "The Opening")
        XCTAssertEqual(response.revelationPlace, "Mecca")
        XCTAssertEqual(response.totalAyah, 7)
        XCTAssertEqual(response.surahNo, 1)
        XCTAssertEqual(response.ayahNo, 1)
        XCTAssertEqual(response.english, "In the name of Allah, the Entirely Merciful, the Especially Merciful")
        XCTAssertEqual(response.arabic1, "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
        XCTAssertEqual(response.arabic2, "بسم الله الرحمن الرحيم")
        XCTAssertEqual(response.audio.count, 2)
    }

    func testAudioDictionaryParsing() throws {
        let json = """
        {
            "surahName": "Al-Fatihah",
            "surahNameArabic": "الفاتحة",
            "surahNameArabicLong": "سورة الفاتحة",
            "surahNameTranslation": "The Opening",
            "revelationPlace": "Mecca",
            "totalAyah": 7,
            "surahNo": 1,
            "ayahNo": 1,
            "audio": {
                "1": {
                    "reciter": "Mishary Rashid Al Afasy",
                    "url": "url1",
                    "originalUrl": "orig1"
                },
                "3": {
                    "reciter": "Nasser Al Qatami",
                    "url": "url3",
                    "originalUrl": "orig3"
                }
            },
            "english": "In the name of Allah",
            "arabic1": "بسم الله",
            "arabic2": "بسم الله"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SingleVerseResponse.self, from: data)

        XCTAssertEqual(response.audio.count, 2)
        XCTAssertEqual(response.audio["1"]?.reciter, "Mishary Rashid Al Afasy")
        XCTAssertEqual(response.audio["3"]?.reciter, "Nasser Al Qatami")
        XCTAssertNil(response.audio["2"])
    }

    func testSurahListResponseDecoding() throws {
        let json = """
        [
            {
                "surahNo": 1,
                "surahName": "Al-Fatihah",
                "surahNameArabic": "الفاتحة",
                "surahNameArabicLong": "سورة الفاتحة",
                "surahNameTranslation": "The Opening",
                "revelationPlace": "Mecca",
                "totalAyah": 7
            },
            {
                "surahNo": 2,
                "surahName": "Al-Baqarah",
                "surahNameArabic": "البقرة",
                "surahNameArabicLong": "سورة البقرة",
                "surahNameTranslation": "The Cow",
                "revelationPlace": "Medina",
                "totalAyah": 286
            }
        ]
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SurahListResponse.self, from: data)

        XCTAssertEqual(response.surahs.count, 2)
        XCTAssertEqual(response.surahs[0].surahNo, 1)
        XCTAssertEqual(response.surahs[0].surahName, "Al-Fatihah")
        XCTAssertEqual(response.surahs[1].surahNo, 2)
        XCTAssertEqual(response.surahs[1].surahName, "Al-Baqarah")
    }

    func testSingleVerseToAyahEntityMapping() {
        let dto = SingleVerseResponse(
            surahName: "Al-Fatihah",
            surahNameArabic: "الفاتحة",
            surahNameArabicLong: "سورة الفاتحة",
            surahNameTranslation: "The Opening",
            revelationPlace: "Mecca",
            totalAyah: 7,
            surahNo: 1,
            ayahNo: 1,
            audio: [
                "1": ReciterAudioDTO(reciter: "Mishary Rashid Al Afasy", url: "url1", originalUrl: "orig1"),
                "2": ReciterAudioDTO(reciter: "Abu Bakr Al Shatri", url: "url2", originalUrl: "orig2")
            ],
            english: "In the name of Allah",
            arabic1: "بِسْمِ اللَّهِ",
            arabic2: "بسم الله"
        )

        let ayah = dto.toAyahEntity()

        XCTAssertEqual(ayah.number, 1)
        XCTAssertEqual(ayah.numberInSurah, 1)
        XCTAssertEqual(ayah.english, "In the name of Allah")
        XCTAssertEqual(ayah.arabic1, "بِسْمِ اللَّهِ")
        XCTAssertEqual(ayah.arabic2, "بسم الله")
        XCTAssertEqual(ayah.surahNo, 1)
        XCTAssertEqual(ayah.surahName, "Al-Fatihah")
        XCTAssertEqual(ayah.audioUrls.count, 2)
        XCTAssertEqual(ayah.audioUrls[0].reciterId, 1)
        XCTAssertEqual(ayah.audioUrls[1].reciterId, 2)
    }

    func testSingleVerseToSurahEntityMapping() {
        let dto = SingleVerseResponse(
            surahName: "Al-Fatihah",
            surahNameArabic: "الفاتحة",
            surahNameArabicLong: "سورة الفاتحة",
            surahNameTranslation: "The Opening",
            revelationPlace: "Mecca",
            totalAyah: 7,
            surahNo: 1,
            ayahNo: 1,
            audio: [:],
            english: "In the name of Allah",
            arabic1: "بسم الله",
            arabic2: "بسم الله"
        )

        let surah = dto.toSurahEntity()

        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(surah.name, "Al-Fatihah")
        XCTAssertEqual(surah.englishNameTranslation, "The Opening")
        XCTAssertEqual(surah.numberOfAyahs, 7)
        XCTAssertEqual(surah.revelationPlace, "Mecca")
        XCTAssertEqual(surah.surahNameArabic, "الفاتحة")
        XCTAssertEqual(surah.surahNameArabicLong, "سورة الفاتحة")
    }

    func testSurahMetadataToSurahEntityMapping() {
        let dto = SurahMetadataDTO(
            surahNo: 114,
            surahName: "An-Nas",
            surahNameArabic: "الناس",
            surahNameArabicLong: "سورة الناس",
            surahNameTranslation: "Mankind",
            revelationPlace: "Mecca",
            totalAyah: 6
        )

        let surah = dto.toSurahEntity()

        XCTAssertEqual(surah.number, 114)
        XCTAssertEqual(surah.name, "An-Nas")
        XCTAssertEqual(surah.englishNameTranslation, "Mankind")
        XCTAssertEqual(surah.numberOfAyahs, 6)
        XCTAssertEqual(surah.revelationPlace, "Mecca")
        XCTAssertEqual(surah.surahNameArabic, "الناس")
        XCTAssertEqual(surah.surahNameArabicLong, "سورة الناس")
    }

    func testReciterAudioDTODecoding() throws {
        let json = """
        {
            "reciter": "Mishary Rashid Al Afasy",
            "url": "https://example.com/audio.mp3",
            "originalUrl": "https://example.com/original.mp3"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let dto = try decoder.decode(ReciterAudioDTO.self, from: data)

        XCTAssertEqual(dto.reciter, "Mishary Rashid Al Afasy")
        XCTAssertEqual(dto.url, "https://example.com/audio.mp3")
        XCTAssertEqual(dto.originalUrl, "https://example.com/original.mp3")
    }

    func testAllFiveRecitersMapping() {
        var audioDict: [String: ReciterAudioDTO] = [:]
        let reciters = [
            (1, "Mishary Rashid Al Afasy"),
            (2, "Abu Bakr Al Shatri"),
            (3, "Nasser Al Qatami"),
            (4, "Yasser Al Dosari"),
            (5, "Hani Ar Rifai")
        ]

        for (id, name) in reciters {
            audioDict[String(id)] = ReciterAudioDTO(
                reciter: name,
                url: "url\(id)",
                originalUrl: "orig\(id)"
            )
        }

        let dto = SingleVerseResponse(
            surahName: "Al-Fatihah",
            surahNameArabic: "الفاتحة",
            surahNameArabicLong: "سورة الفاتحة",
            surahNameTranslation: "The Opening",
            revelationPlace: "Mecca",
            totalAyah: 7,
            surahNo: 1,
            ayahNo: 1,
            audio: audioDict,
            english: "In the name of Allah",
            arabic1: "بسم الله",
            arabic2: "بسم الله"
        )

        let ayah = dto.toAyahEntity()

        XCTAssertEqual(ayah.audioUrls.count, 5)
        for (index, audio) in ayah.audioUrls.enumerated() {
            XCTAssertEqual(audio.reciterId, index + 1)
        }
    }
}
