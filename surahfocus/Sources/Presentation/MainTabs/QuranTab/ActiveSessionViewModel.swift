import Foundation
import Combine
import SwiftUI

@MainActor
final class ActiveSessionViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentAyahIndex = 0
    @Published var currentAyah: Ayah?
    @Published var sessionDuration: TimeInterval = 0
    @Published var showEndConfirmation = false
    @Published var errorMessage: String?

    private let ayahAudioPlayer: AyahAudioPlayerServiceImpl
    private let sessionService: SessionService
    private let subscriptionService: SubscriptionService
    private let quranPreferences: QuranPreferencesService
    weak var router: Router?

    private var session: Session?
    private var cancellables = Set<AnyCancellable>()

    var surahs: [SurahWithRange] = []
    var ayahs: [Ayah] = []

    init(
        ayahAudioPlayer: AyahAudioPlayerServiceImpl? = nil,
        sessionService: SessionService = DIContainer.shared.sessionService,
        subscriptionService: SubscriptionService = DIContainer.shared.subscriptionService,
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService
    ) {
        self.ayahAudioPlayer = ayahAudioPlayer ?? DIContainer.shared.ayahAudioPlayerService as! AyahAudioPlayerServiceImpl
        self.sessionService = sessionService
        self.subscriptionService = subscriptionService
        self.quranPreferences = quranPreferences

        setupBindings()
    }

    func configure(surahs: [SurahWithRange], ayahs: [Ayah]) {
        self.surahs = surahs
        self.ayahs = ayahs
    }

    private func setupBindings() {
        ayahAudioPlayer.$isPlaying
            .assign(to: &$isPlaying)

        ayahAudioPlayer.$currentAyahIndex
            .assign(to: &$currentAyahIndex)

        ayahAudioPlayer.$sessionDuration
            .assign(to: &$sessionDuration)

        ayahAudioPlayer.$currentAyah
            .assign(to: &$currentAyah)

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
        // Shields are automatically removed by SessionService
        router?.navigate(to: .sessionFinish(duration: sessionDuration, surahCount: surahs.count))
    }

    func startSession() async {
        do {
            guard !ayahs.isEmpty else {
                errorMessage = "No ayahs to play"
                return
            }

            let reciterId = quranPreferences.selectedReciterId

            // SessionService handles shield application
            session = try await sessionService.startSession(
                type: .listening,
                surahNumbers: surahs.map { $0.surah.number },
                reciterId: reciterId
            )

            try await ayahAudioPlayer.loadQueue(ayahs, reciterId: reciterId)
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

    func endSession() async {
        showEndConfirmation = true
    }

    func confirmEndSession() async {
        showEndConfirmation = false
        ayahAudioPlayer.stop()

        if let session {
            // SessionService handles shield removal
            try? await sessionService.endSession(session, durationSeconds: Int(sessionDuration))
        }

        router?.navigate(to: .sessionFinish(duration: sessionDuration, surahCount: surahs.count))
    }

    func getTranslation(for ayah: Ayah) -> String {
        quranPreferences.getTranslation(for: ayah)
    }
}
