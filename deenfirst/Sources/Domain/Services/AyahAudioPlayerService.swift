import Foundation
import Combine

enum AudioPlayerError: LocalizedError {
    case loadFailed
    case playbackFailed(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .loadFailed: return "Failed to load audio"
        case .playbackFailed(let error): return "Playback failed: \(error.localizedDescription)"
        case .invalidURL: return "Invalid audio URL"
        }
    }
}

protocol AyahAudioPlayerService: ObservableObject {
    var isPlaying: Bool { get }
    var currentAyah: Ayah? { get }
    var currentAyahIndex: Int { get }
    var progress: Double { get }
    var sessionDuration: TimeInterval { get }

    func loadQueue(_ ayahs: [Ayah], reciterId: Int) async throws
    func play()
    func pause()
    func stop()
    func nextAyah() async throws
    func previousAyah() async throws
    func seekToAyah(index: Int) async throws

    var onAyahChanged: ((Ayah, Int) -> Void)? { get set }
    var onQueueFinished: (() -> Void)? { get set }
    var onPlaybackError: ((Error) -> Void)? { get set }
}

@MainActor
final class AyahAudioPlayerServiceImpl: NSObject, AyahAudioPlayerService {
    @Published var isPlaying: Bool = false
    @Published var currentAyah: Ayah?
    @Published var currentAyahIndex: Int = 0
    @Published var progress: Double = 0
    @Published var sessionDuration: TimeInterval = 0

    var onAyahChanged: ((Ayah, Int) -> Void)?
    var onQueueFinished: (() -> Void)?
    var onPlaybackError: ((Error) -> Void)?

    private var ayahQueue: [Ayah] = []
    private var reciterId: Int = 0
    private var audioPlayer: AudioPlayerService
    private var sessionStartTime: Date?
    private var timer: Timer?

    private var cancellables = Set<AnyCancellable>()

    init(audioPlayer: AudioPlayerService) {
        self.audioPlayer = audioPlayer
        super.init()

        audioPlayer.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                await self?.playNextAyah()
            }
        }

        audioPlayer.onPlaybackError = { [weak self] error in
            Task { @MainActor in
                self?.onPlaybackError?(error)
            }
        }
    }

    func loadQueue(_ ayahs: [Ayah], reciterId: Int) async throws {
        guard !ayahs.isEmpty else {
            throw NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty ayah queue"])
        }

        self.ayahQueue = ayahs
        self.reciterId = reciterId
        currentAyahIndex = 0
        currentAyah = ayahs.first
        sessionStartTime = nil
        sessionDuration = 0

        try await loadCurrentAyah()
    }

    private func loadCurrentAyah() async throws {
        guard let ayah = currentAyah else { return }

        let quranService = DIContainer.shared.quranService

        // Get remote URL
        let audioURL = try await quranService.getAudioStreamURL(
            reciterId: reciterId,
            surahNo: ayah.surahNo,
            ayahNo: ayah.numberInSurah
        )

        // Get reciter name from reciterId
        let reciters = quranService.getAvailableReciters()
        let reciterName = reciters.first { $0.id == reciterId }?.name ?? "Unknown"

        try? await audioPlayer.loadAudio(
            url: audioURL,
            surahName: ayah.surahName,
            reciterName: reciterName
        )

        onAyahChanged?(ayah, currentAyahIndex)
    }

    func play() {
        if sessionStartTime == nil {
            sessionStartTime = Date()
            startSessionTimer()
        }

        audioPlayer.play()
        isPlaying = true
    }

    func pause() {
        audioPlayer.pause()
        isPlaying = false
    }

    func stop() {
        audioPlayer.stop()
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentAyah = nil
        currentAyahIndex = 0
        progress = 0
    }

    func nextAyah() async throws {
        currentAyahIndex += 1

        guard currentAyahIndex < ayahQueue.count else {
            onQueueFinished?()
            return
        }

        currentAyah = ayahQueue[currentAyahIndex]
        try await loadCurrentAyah()

        if isPlaying {
            audioPlayer.play()
        }
    }

    func previousAyah() async throws {
        guard currentAyahIndex > 0 else { return }

        currentAyahIndex -= 1
        currentAyah = ayahQueue[currentAyahIndex]
        try await loadCurrentAyah()

        if isPlaying {
            audioPlayer.play()
        }
    }

    func seekToAyah(index: Int) async throws {
        guard index >= 0, index < ayahQueue.count else {
            throw NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid ayah index"])
        }

        currentAyahIndex = index
        currentAyah = ayahQueue[index]
        try await loadCurrentAyah()
    }

    private func playNextAyah() async {
        do {
            try await nextAyah()
        } catch {
            onPlaybackError?(error)
        }
    }

    private func startSessionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sessionDuration += 1.0
            }
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
        cancellables.removeAll()
    }
}
