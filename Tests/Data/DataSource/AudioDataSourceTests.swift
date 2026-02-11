import XCTest
@testable import SurahFocus

final class AudioDataSourceTests: XCTestCase {
    var dataSource: AudioDataSourceImpl!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        dataSource = AudioDataSourceImpl()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        dataSource = nil
        try await super.tearDown()
    }

    func testCheckCacheReturnsNilWhenNotCached() {
        let audio = AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        let url = dataSource.checkCache(for: audio)

        XCTAssertNil(url)
    }

    func testDownloadProgressFractionCompleted() {
        var progress = DownloadProgress(bytesReceived: 0, totalBytes: 100)
        XCTAssertEqual(progress.fractionCompleted, 0.0)

        progress.bytesReceived = 50
        XCTAssertEqual(progress.fractionCompleted, 0.5)

        progress.bytesReceived = 100
        XCTAssertEqual(progress.fractionCompleted, 1.0)
    }

    func testDownloadProgressFractionCompletedWithZeroTotal() {
        let progress = DownloadProgress(bytesReceived: 10, totalBytes: 0)
        XCTAssertEqual(progress.fractionCompleted, 0.0)
    }
}
