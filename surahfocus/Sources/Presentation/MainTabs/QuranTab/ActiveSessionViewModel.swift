import Foundation
import Combine

@MainActor
final class ActiveSessionViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentAyahIndex = 0
    @Published var sessionDuration: TimeInterval = 0
    @Published var showEndConfirmation = false

    @Published var errorMessage: String?

    private let ayahAudioPlayer: AyahAudioPlayerServiceImpl
    private let sessionService: SessionService
    private let screenTimeService: ScreenTimeService
    private let subscriptionService: SubscriptionService
    weak var router: Router?

    private var session: Session?
    private var cancellables = Set<AnyCancellable>()

    let surahs: [SurahWithRange]
    let ayahs: [Ayah]

    init(surahs: [SurahWithRange], ayahs: [Ayah], router: Router? = nil) {
        self.surahs = surahs
        self.ayahs = ayahs
        self.ayahAudioPlayer = DIContainer.shared.ayahAudioPlayerService as! AyahAudioPlayerServiceImpl
        self.sessionService = DIContainer.shared.sessionService
        self.screenTimeService = DIContainer.shared.screenTimeService
        self.subscriptionService = DIContainer.shared.subscriptionService
        self.router = router

        setupBindings()
    }

    private func setupBindings() {
        ayahAudioPlayer.$isPlaying
            .assign(to: &$isPlaying)

        ayahAudioPlayer.$currentAyahIndex
            .assign(to: &$currentAyahIndex)

        ayahAudioPlayer.$sessionDuration
            .assign(to: &$sessionDuration)

        ayahAudioPlayer.onQueueFinished = { [weak self] in
            Task { @MainActor in
                await self?.handleQueueFinished()
            }
        }
    }

    private func handleQueueFinished() async {
        ayahAudioPlayer.stop()
        if let session {
            try? await sessionService.endSession(session, durationSeconds: Int(sessionDuration))
        }
        try? await screenTimeService.removeShields()
        router?.navigate(to: .sessionFinish(duration: sessionDuration, surahCount: surahs.count))
    }

    func startSession() async {
        do {
            guard !ayahs.isEmpty else {
                errorMessage = "No ayahs to play"
                return
            }

            session = try await sessionService.startSession(
                type: .listening,
                surahNumbers: surahs.map { $0.surah.number },
                reciterId: 1
            )

            try await ayahAudioPlayer.loadQueue(ayahs, reciterId: 1)
            ayahAudioPlayer.play()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePlayPause() {
        if isPlaying {
            ayahAudioPlayer.pause()
        } else {
            ayahAudioPlayer.play()
        }
    }

    func nextAyah() async {
        try? await ayahAudioPlayer.nextAyah()
    }

    func previousAyah() async {
        try? await ayahAudioPlayer.previousAyah()
    }

    func endSession() async {
        showEndConfirmation = true
    }

    func confirmEndSession() async {
        showEndConfirmation = false

        ayahAudioPlayer.stop()

        if let session {
            try? await sessionService.endSession(session, durationSeconds: Int(sessionDuration))
        }

        let isPremium = try? await subscriptionService.checkSubscriptionStatus()

        if isPremium == true {
            try? await screenTimeService.removeShields()
        } else {
            try? await screenTimeService.removeShields()
        }

        router?.navigate(to: .sessionFinish(duration: sessionDuration, surahCount: surahs.count))
    }
}
