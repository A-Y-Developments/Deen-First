import XCTest
import Combine
@testable import SurahFocus

final class AudioDownloadServiceTests: XCTestCase {
    var service: AudioDownloadServiceImpl!
    var mockDataSource: MockAudioDataSource!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockDataSource = MockAudioDataSource()
        service = AudioDownloadServiceImpl(audioDataSource: mockDataSource)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        service.cancelDownloads()
        cancellables.removeAll()
        service = nil
        mockDataSource = nil
        try await super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(service.isDownloading)
        XCTAssertEqual(service.overallProgress, 0.0)
        XCTAssertEqual(service.downloadedCount, 0)
        XCTAssertEqual(service.totalCount, 0)
        XCTAssertTrue(service.downloadQueue.isEmpty)
    }

    func testDownloadAyahsUpdatesProgress() async throws {
        let ayahs = [
            AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1),
            AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 2)
        ]

        mockDataSource.shouldSucceed = true

        let progressUpdated = expectation(description: "Progress updated")
        let downloadFinished = expectation(description: "Download finished")

        service.$downloadedCount
            .dropFirst()
            .sink { count in
                if count == 2 {
                    progressUpdated.fulfill()
                }
            }
            .store(in: &cancellables)

        service.$isDownloading
            .dropFirst()
            .filter { !$0 }
            .sink { _ in downloadFinished.fulfill() }
            .store(in: &cancellables)

        try await service.downloadAyahs(ayahs)

        await fulfillment(of: [progressUpdated, downloadFinished], timeout: 1.0)

        XCTAssertEqual(service.downloadedCount, 2)
        XCTAssertEqual(service.totalCount, 2)
        XCTAssertEqual(service.overallProgress, 1.0)
        XCTAssertFalse(service.isDownloading)
    }

    func testCancelDownloadsClearsState() async {
        let ayahs = [
            AyahAudio(reciterId: 7, surahNumber: 1, ayahNumber: 1)
        ]

        Task {
            try? await service.downloadAyahs(ayahs)
        }

        await MainActor.run {
            service.cancelDownloads()
        }

        XCTAssertFalse(service.isDownloading)
        XCTAssertTrue(service.downloadQueue.isEmpty)
    }
}

class MockAudioDataSource: AudioDataSource {
    var shouldSucceed = true
    var downloadCallCount = 0

    func downloadAudio(from url: URL, to destinationURL: URL) async throws -> DownloadProgress {
        downloadCallCount += 1
        if shouldSucceed {
            return DownloadProgress(bytesReceived: 100, totalBytes: 100)
        } else {
            throw NSError(domain: "test", code: -1)
        }
    }

    func checkCache(for audio: AyahAudio) -> URL? {
        return nil
    }
}
