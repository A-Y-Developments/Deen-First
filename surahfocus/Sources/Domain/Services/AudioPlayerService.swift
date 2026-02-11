import Foundation
import AVFoundation
import MediaPlayer
import Combine

protocol AudioPlayerService: ObservableObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var currentSurahName: String? { get }
    var currentReciterName: String? { get }

    func loadAudio(url: URL, surahName: String, reciterName: String) async throws
    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval)

    var onPlaybackFinished: (() -> Void)? { get set }
    var onPlaybackError: ((Error) -> Void)? { get set }
}

@MainActor
final class AudioPlayerServiceImpl: NSObject, AudioPlayerService {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSurahName: String?
    @Published var currentReciterName: String?

    var onPlaybackFinished: (() -> Void)?
    var onPlaybackError: ((Error) -> Void)?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var itemObserver: NSObjectProtocol?

    private let progressUpdateInterval: TimeInterval = 0.5

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }

        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
    }

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSurahName ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentReciterName ?? ""
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func loadAudio(url: URL, surahName: String, reciterName: String) async throws {
        stop()

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        self.currentSurahName = surahName
        self.currentReciterName = reciterName

        await playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"])
        if playerItem.status == .readyToPlay {
            self.duration = CMTimeGetSeconds(playerItem.asset.duration)
        }

        setupTimeObserver()
        setupItemFinishObserver(for: playerItem)
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        let interval = CMTime(seconds: progressUpdateInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
            self?.updateNowPlayingInfo()
        }
    }

    private func setupItemFinishObserver(for item: AVPlayerItem) {
        itemObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.onPlaybackFinished?()
        }
    }

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func stop() {
        pause()

        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        if let observer = itemObserver {
            NotificationCenter.default.removeObserver(observer)
            itemObserver = nil
        }

        player = nil
        currentTime = 0
        duration = 0
        isPlaying = false

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        currentTime = time
        updateNowPlayingInfo()
    }

    deinit {
        // Clean up without calling stop() due to actor isolation
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        if let observer = itemObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
