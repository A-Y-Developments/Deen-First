import XCTest
import Combine
@testable import SurahFocus

final class AyahAudioPlayerServiceTests: XCTestCase {
    var service: AyahAudioPlayerServiceImpl!
    var mockAudioPlayer: MockAudioPlayer!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockAudioPlayer = MockAudioPlayer()
        service = AyahAudioPlayerServiceImpl(audioPlayer: mockAudioPlayer)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        service.stop()
        cancellables.removeAll()
        service = nil
        mockAudioPlayer = nil
        try await super.tearDown()
    }

    func testInitialState() async throws {
        let surah = Surah(
            number: 1,
            name: "Al-Fatihah",
            englishName: "The Opening",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationPlace: "Meccan"
        )
        let ayahs = [
            Ayah(number: 1, text: "Verse 1", numberInSurah: 1, english: "In the name of Allah", arabic1: "بسم الله", arabic2: "بسم الله", surahNo: 1, surahName: "Al-Fatihah"),
            Ayah(number: 2, text: "Verse 2", numberInSurah: 2, english: "Praise be to Allah", arabic1: "الحمد", arabic2: "الحمد", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)

        XCTAssertEqual(service.currentAyahIndex, 0)
        XCTAssertEqual(service.currentAyah?.numberInSurah, 1)
        XCTAssertFalse(service.isPlaying)
        XCTAssertEqual(service.sessionDuration, 0)
    }

    func testLoadQueueEmpty() async {
        var didThrow = false
        do {
            try await service.loadQueue([], reciterId: 7)
        } catch {
            didThrow = true
        }
        XCTAssertTrue(didThrow)
    }

    func testNextAyah() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah"),
            Ayah(number: 2, text: "V2", numberInSurah: 2, english: "E2", arabic1: "A2", arabic2: "A2", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        try await service.nextAyah()

        XCTAssertEqual(service.currentAyahIndex, 1)
        XCTAssertEqual(service.currentAyah?.numberInSurah, 2)
    }

    func testPreviousAyah() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah"),
            Ayah(number: 2, text: "V2", numberInSurah: 2, english: "E2", arabic1: "A2", arabic2: "A2", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        service.currentAyahIndex = 1

        try await service.previousAyah()

        XCTAssertEqual(service.currentAyahIndex, 0)
        XCTAssertEqual(service.currentAyah?.numberInSurah, 1)
    }

    func testPreviousAyahAtStart() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        let beforeIndex = service.currentAyahIndex
        try await service.previousAyah()

        XCTAssertEqual(service.currentAyahIndex, beforeIndex)
    }

    func testSeekToAyah() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah"),
            Ayah(number: 2, text: "V2", numberInSurah: 2, english: "E2", arabic1: "A2", arabic2: "A2", surahNo: 1, surahName: "Al-Fatihah"),
            Ayah(number: 3, text: "V3", numberInSurah: 3, english: "E3", arabic1: "A3", arabic2: "A3", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        try await service.seekToAyah(index: 2)

        XCTAssertEqual(service.currentAyahIndex, 2)
        XCTAssertEqual(service.currentAyah?.numberInSurah, 3)
    }

    func testSeekToAyahInvalid() async {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)

        var didThrow = false
        do {
            try await service.seekToAyah(index: 5)
        } catch {
            didThrow = true
        }
        XCTAssertTrue(didThrow)
    }

    func testOnAyahChangedCallback() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah"),
            Ayah(number: 2, text: "V2", numberInSurah: 2, english: "E2", arabic1: "A2", arabic2: "A2", surahNo: 1, surahName: "Al-Fatihah")
        ]

        var callbackCalled = false
        var receivedAyah: Ayah?
        var receivedIndex: Int?

        service.onAyahChanged = { ayah, index in
            callbackCalled = true
            receivedAyah = ayah
            receivedIndex = index
        }

        try await service.loadQueue(ayahs, reciterId: 7)

        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(receivedIndex, 0)
        XCTAssertEqual(receivedAyah?.numberInSurah, 1)
    }

    func testPlayStartsTimer() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        service.play()

        XCTAssertNotNil(service.sessionStartTime)
        XCTAssertTrue(service.isPlaying)
    }

    func testSessionTimerIncrements() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        service.play()

        let beforeDuration = service.sessionDuration
        Thread.sleep(forTimeInterval: 1.1)
        let afterDuration = service.sessionDuration

        XCTAssertTrue(afterDuration > beforeDuration)
    }

    func testStopClearsState() async throws {
        let ayahs = [
            Ayah(number: 1, text: "V1", numberInSurah: 1, english: "E1", arabic1: "A1", arabic2: "A1", surahNo: 1, surahName: "Al-Fatihah")
        ]

        try await service.loadQueue(ayahs, reciterId: 7)
        service.play()
        service.stop()

        XCTAssertFalse(service.isPlaying)
        XCTAssertEqual(service.sessionDuration, 0)
        XCTAssertNil(service.currentAyah)
        XCTAssertEqual(service.currentAyahIndex, 0)
    }
}

class MockAudioPlayer: AudioPlayerService {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSurahName: String?
    @Published var currentReciterName: String?

    var onPlaybackFinished: (() -> Void)?
    var onPlaybackError: ((Error) -> Void)?

    func loadAudio(url: URL, surahName: String, reciterName: String) async throws {
        currentSurahName = surahName
        currentReciterName = reciterName
        duration = 10
    }

    func play() { isPlaying = true }
    func pause() { isPlaying = false }
    func stop() {
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    func seek(to time: TimeInterval) { currentTime = time }
}
