import XCTest
@testable import SurahFocus

final class AudioFileHelperTests: XCTestCase {
    var helper: AudioFileHelper!
    var testAudio: AyahAudio!

    override func setUp() {
        super.setUp()
        helper = AudioFileHelper.shared
        testAudio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
    }

    override func tearDown() async throws {
        // Clean up test files
        try? helper.removeFile(for: testAudio)
        super.tearDown()
    }

    func testFileURLFormat() {
        let url = helper.fileURL(for: testAudio)
        XCTAssertTrue(url.lastPathComponent.hasPrefix("7_1_1."))
        XCTAssertTrue(url.lastPathComponent.hasSuffix(".mp3"))
        XCTAssertTrue(url.path.contains("AudioCache"))
    }

    func testIsCachedInitiallyFalse() {
        XCTAssertFalse(helper.isCached(testAudio))
    }

    func testCacheDirectoryExists() {
        let url = helper.fileURL(for: testAudio)
        let parentDir = url.deletingLastPathComponent()
        XCTAssertTrue(FileManager.default.fileExists(atPath: parentDir.path))
    }

    func testRemoveFileWhenNotExists() {
        // Should not throw even if file doesn't exist
        XCTAssertNoThrow(try helper.removeFile(for: testAudio))
    }

    func testCacheSizeReturnsZeroWhenEmpty() {
        let size = helper.cacheSize()
        XCTAssertEqual(size, 0)
    }

    func testFileURLConsistent() {
        let url1 = helper.fileURL(for: testAudio)
        let url2 = helper.fileURL(for: testAudio)
        XCTAssertEqual(url1, url2)
    }

    func testDifferentAyahsDifferentURLs() {
        let audio1 = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        let audio2 = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 2)

        let url1 = helper.fileURL(for: audio1)
        let url2 = helper.fileURL(for: audio2)

        XCTAssertNotEqual(url1, url2)
    }

    func testFileURLForAllReciters() {
        for reciter in AudioConstants.Reciter.allCases {
            let audio = AyahAudio(reciterId: reciter.id, surahNumber: 1, ayahNumber: 1)
            let url = helper.fileURL(for: audio)
            XCTAssertTrue(url.path.contains("AudioCache"))
        }
    }
}
