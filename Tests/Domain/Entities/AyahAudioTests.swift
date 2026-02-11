import XCTest
@testable import SurahFocus

final class AyahAudioTests: XCTestCase {
    func testInitialization() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)

        XCTAssertEqual(audio.id, "7_1_1")
        XCTAssertEqual(audio.reciterId, 7)
        XCTAssertEqual(audio.surahNumber, 1)
        XCTAssertEqual(audio.ayahNumber, 1)
        XCTAssertFalse(audio.isCached)
        XCTAssertEqual(audio.downloadURL.absoluteString, "https://quranaudio.pages.dev/7/1_1.mp3")
    }

    func testIDFormat() {
        let audio1 = AyahAudio(reciterId: 2, surahNumber: 114, ayahNumber: 6)
        XCTAssertEqual(audio1.id, "2_114_6")

        let audio2 = AyahAudio(reciterId: 5, surahNumber: 2, ayahNumber: 255)
        XCTAssertEqual(audio2.id, "5_2_255")
    }

    func testDownloadURLFormat() {
        let audio = AyahAudio(reciterId: 3, surahNumber: 3, ayahNumber: 15)
        XCTAssertTrue(audio.downloadURL.absoluteString.hasPrefix("https://quranaudio.pages.dev/"))
        XCTAssertTrue(audio.downloadURL.absoluteString.contains("/3/3_15.mp3"))
    }

    func testIsCachedWhenLocalURLNil() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        XCTAssertFalse(audio.isCached)
    }

    func testIsCachedWhenLocalURLSet() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        audio.localURL = URL(fileURLWithPath: "/tmp/test.mp3")
        XCTAssertTrue(audio.isCached)
    }

    func testAyahAudioDownloadProgressInitial() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        var progress = AyahAudioDownloadProgress(ayahAudio: audio, progress: 0)

        XCTAssertEqual(progress.ayahAudio, audio)
        XCTAssertEqual(progress.progress, 0)
        XCTAssertFalse(progress.isComplete)
        XCTAssertNil(progress.error)
    }

    func testAyahAudioDownloadProgressComplete() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        var progress = AyahAudioDownloadProgress(ayahAudio: audio, progress: 1.0)

        XCTAssertTrue(progress.isComplete)
    }

    func testAyahAudioDownloadProgressWithError() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        let testError = NSError(domain: "test", code: 1)
        var progress = AyahAudioDownloadProgress(ayahAudio: audio, progress: 0)
        progress.error = testError

        XCTAssertNotNil(progress.error)
        XCTAssertEqual(progress.error as? NSError, testError)
    }
}
