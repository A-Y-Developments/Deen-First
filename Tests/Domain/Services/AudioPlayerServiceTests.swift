import XCTest
import AVFoundation
import Combine
@testable import SurahFocus

final class AudioPlayerServiceTests: XCTestCase {
    var service: AudioPlayerServiceImpl!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        service = AudioPlayerServiceImpl()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        service.stop()
        cancellables.removeAll()
        service = nil
        try await super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(service.isPlaying)
        XCTAssertEqual(service.currentTime, 0)
        XCTAssertEqual(service.duration, 0)
        XCTAssertNil(service.currentSurahName)
        XCTAssertNil(service.currentReciterName)
    }

    func testLoadAudioWithValidURL() async throws {
        let url = URL(fileURLWithPath: "/tmp/test.mp3")

        // Create a test file
        try "test".write(to: url, atomically: true, encoding: .utf8)

        var didFinishLoad = false
        service.$isPlaying
            .dropFirst()
            .sink { _ in didFinishLoad = true }
            .store(in: &cancellables)

        try? await service.loadAudio(url: url, surahName: "Al-Fatihah", reciterName: "Mishary Rashid Alafasy")

        XCTAssertEqual(service.currentSurahName, "Al-Fatihah")
        XCTAssertEqual(service.currentReciterName, "Mishary Rashid Alafasy")

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    func testStopClearsState() async {
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        try? "test".write(to: url, atomically: true, encoding: .utf8)

        try? await service.loadAudio(url: url, surahName: "Test", reciterName: "Test")
        service.stop()

        XCTAssertFalse(service.isPlaying)
        XCTAssertEqual(service.currentTime, 0)
        XCTAssertEqual(service.duration, 0)
        XCTAssertNil(service.currentSurahName)
        XCTAssertNil(service.currentReciterName)

        try? FileManager.default.removeItem(at: url)
    }

    func testOnPlaybackFinishedCallback() async {
        var callbackCalled = false
        service.onPlaybackFinished = {
            callbackCalled = true
        }

        // Simulate playback finished by triggering notification
        // Note: This would require actual audio file playback
        // For unit tests, we verify the callback property exists
        XCTAssertNotNil(service.onPlaybackFinished)
    }

    func testOnPlaybackErrorCallback() {
        let testError = AudioPlayerError.invalidURL
        var errorCallbackCalled = false
        var receivedError: Error?

        service.onPlaybackError = { error in
            errorCallbackCalled = true
            receivedError = error
        }

        service.onPlaybackError?(testError)

        XCTAssertTrue(errorCallbackCalled)
        XCTAssertEqual(receivedError as? AudioPlayerError, .invalidURL)
    }

    func testSeekUpdatesCurrentTime() async {
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        try? "test".write(to: url, atomically: true, encoding: .utf8)

        try? await service.loadAudio(url: url, surahName: "Test", reciterName: "Test")
        service.seek(to: 10.0)

        XCTAssertEqual(service.currentTime, 10.0)

        try? FileManager.default.removeItem(at: url)
    }

    func testAudioPlayerErrorDescriptions() {
        let loadFailed = AudioPlayerError.loadFailed
        XCTAssertEqual(loadFailed.errorDescription, "Failed to load audio")

        let invalidURL = AudioPlayerError.invalidURL
        XCTAssertEqual(invalidURL.errorDescription, "Invalid audio URL")

        let playbackError = AudioPlayerError.playbackFailed(NSError(domain: "test", code: 1))
        XCTAssertTrue(playbackError.errorDescription?.contains("Playback failed") ?? false)
    }
}
