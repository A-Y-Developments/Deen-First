import XCTest
@testable import SurahFocus

final class ReciterAudioTests: XCTestCase {

    func testReciterAudioInitialization() {
        let audio = ReciterAudio(
            reciterId: 1,
            reciterName: "Mishary Rashid Al Afasy",
            url: "https://example.com/audio.mp3",
            originalUrl: "https://example.com/original.mp3"
        )

        XCTAssertEqual(audio.reciterId, 1)
        XCTAssertEqual(audio.reciterName, "Mishary Rashid Al Afasy")
        XCTAssertEqual(audio.url, "https://example.com/audio.mp3")
        XCTAssertEqual(audio.originalUrl, "https://example.com/original.mp3")
    }

    func testReciterAudioCodable() throws {
        let audio = ReciterAudio(
            reciterId: 2,
            reciterName: "Abu Bakr Al Shatri",
            url: "https://example.com/audio2.mp3",
            originalUrl: "https://example.com/original2.mp3"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(audio)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ReciterAudio.self, from: data)

        XCTAssertEqual(decoded.reciterId, audio.reciterId)
        XCTAssertEqual(decoded.reciterName, audio.reciterName)
        XCTAssertEqual(decoded.url, audio.url)
        XCTAssertEqual(decoded.originalUrl, audio.originalUrl)
    }

    func testReciterAudioHashable() {
        let audio1 = ReciterAudio(
            reciterId: 1,
            reciterName: "Mishary Rashid Al Afasy",
            url: "https://example.com/audio.mp3",
            originalUrl: "https://example.com/original.mp3"
        )

        let audio2 = ReciterAudio(
            reciterId: 1,
            reciterName: "Mishary Rashid Al Afasy",
            url: "https://example.com/audio.mp3",
            originalUrl: "https://example.com/original.mp3"
        )

        XCTAssertEqual(audio1, audio2)

        let set: Set<ReciterAudio> = [audio1, audio2]
        XCTAssertEqual(set.count, 1)
    }

    func testReciterAudioDifferentIdsNotEqual() {
        let audio1 = ReciterAudio(
            reciterId: 1,
            reciterName: "Reciter 1",
            url: "https://example.com/audio1.mp3",
            originalUrl: "https://example.com/original1.mp3"
        )

        let audio2 = ReciterAudio(
            reciterId: 2,
            reciterName: "Reciter 2",
            url: "https://example.com/audio2.mp3",
            originalUrl: "https://example.com/original2.mp3"
        )

        XCTAssertNotEqual(audio1, audio2)
    }

    func testAllFiveReciters() {
        let reciters = [
            ReciterAudio(reciterId: 1, reciterName: "Mishary Rashid Al Afasy", url: "url1", originalUrl: "orig1"),
            ReciterAudio(reciterId: 2, reciterName: "Abu Bakr Al Shatri", url: "url2", originalUrl: "orig2"),
            ReciterAudio(reciterId: 3, reciterName: "Nasser Al Qatami", url: "url3", originalUrl: "orig3"),
            ReciterAudio(reciterId: 4, reciterName: "Yasser Al Dosari", url: "url4", originalUrl: "orig4"),
            ReciterAudio(reciterId: 5, reciterName: "Hani Ar Rifai", url: "url5", originalUrl: "orig5"),
        ]

        XCTAssertEqual(reciters.count, 5)
        for (index, reciter) in reciters.enumerated() {
            XCTAssertEqual(reciter.reciterId, index + 1)
        }
    }
}
