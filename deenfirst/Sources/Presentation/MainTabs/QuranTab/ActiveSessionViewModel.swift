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
    @Published var sessionDidEnd = false
    @Published var errorMessage: String?
    @Published var unblockGranted = false
    @Published var showUnblockFallback = false

    private let ayahAudioPlayer: AyahAudioPlayerServiceImpl
    private let sessionService: SessionService
    private let subscriptionService: SubscriptionService
    private let quranPreferences: QuranPreferencesService
    private let screenTimeRulesService: ScreenTimeRulesService
    // Internal so DF-41 integration tests can drive the queue-finished /
    // end-early / audio-failure paths without going through startSession.
    var session: Session?
    var isUnblockSession = false
    var unlockRuleId: UUID?
    private var cancellables = Set<AnyCancellable>()

    var surahs: [SurahWithRange] = []
    var ayahs: [Ayah] = []

    init(
        ayahAudioPlayer: AyahAudioPlayerServiceImpl = MainActor.assumeIsolated { DIContainer.shared.ayahAudioPlayerService },
        sessionService: SessionService = DIContainer.shared.sessionService,
        subscriptionService: SubscriptionService = DIContainer.shared.subscriptionService,
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService,
        screenTimeRulesService: ScreenTimeRulesService = MainActor.assumeIsolated { DIContainer.shared.screenTimeRulesService }
    ) {
        self.ayahAudioPlayer = ayahAudioPlayer
        self.sessionService = sessionService
        self.subscriptionService = subscriptionService
        self.quranPreferences = quranPreferences
        self.screenTimeRulesService = screenTimeRulesService

        setupBindings()
    }

    func configure(surahs: [SurahWithRange], ayahs: [Ayah], isUnblockSession: Bool = false, unlockRuleId: UUID? = nil) {
        self.surahs = surahs
        self.ayahs = ayahs
        self.isUnblockSession = isUnblockSession
        self.unlockRuleId = unlockRuleId
        self.unblockGranted = false
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

    /// Internal so DF-41 integration tests can simulate queue completion
    /// directly, bypassing the audio player's real playback timer.
    func handleQueueFinished() async {
        ayahAudioPlayer.stop()
        if let session {
            try? await sessionService.endSession(session, durationSeconds: Int(sessionDuration))
        }
        if isUnblockSession, let ruleId = unlockRuleId {
            let minutes = unblockMinutes(for: ruleId)
            await screenTimeRulesService.temporaryUnblock(minutes: minutes, ruleId: ruleId)
            unblockGranted = true
        }
        sessionDidEnd = true
    }

    /// Routes the audio-load failure path: in unblock sessions we surface the
    /// Tier 1/Tier 2 fallback prompt; in normal sessions we show an error.
    /// Internal for DF-41 integration tests.
    func handleAudioLoadError(_ error: Error) {
        if isUnblockSession {
            showUnblockFallback = true
        } else {
            errorMessage = error.localizedDescription
        }
    }

    private func unblockMinutes(for ruleId: UUID) -> Int {
        // DF-115: single source of truth — UnblockTier owns the tier-to-minutes mapping.
        let isHardMode = screenTimeRulesService.getRule(id: ruleId)?.isHardMode ?? false
        return UnblockTier.tier3.minutes(isHardMode: isHardMode)
    }

    func startSession() async {
        do {
            sessionDidEnd = false

            guard !ayahs.isEmpty else {
                errorMessage = "No ayahs to play"
                return
            }

            let reciterId = quranPreferences.selectedReciterId

            // DF-028: session type must be set BEFORE the repository save, not after.
            let sessionType: SessionType = isUnblockSession ? .unblock(ruleId: unlockRuleId) : .normal

            // SessionService handles shield application
            let newSession = try await sessionService.startSession(
                modality: .listening,
                surahNumbers: surahs.map { $0.surah.number },
                reciterId: reciterId,
                type: sessionType
            )
            session = newSession

            do {
                try await ayahAudioPlayer.loadQueue(ayahs, reciterId: reciterId)
                ayahAudioPlayer.play()
            } catch {
                handleAudioLoadError(error)
            }

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

        sessionDidEnd = true
    }

    func getTranslation(for ayah: Ayah) -> String {
        quranPreferences.getTranslation(for: ayah)
    }
}
