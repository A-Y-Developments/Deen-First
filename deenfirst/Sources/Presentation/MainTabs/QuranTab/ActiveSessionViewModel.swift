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
    private var session: Session?
    private var isUnblockSession = false
    private var unlockRuleId: UUID?
    private var cancellables = Set<AnyCancellable>()

    var surahs: [SurahWithRange] = []
    var ayahs: [Ayah] = []

    init(
        ayahAudioPlayer: AyahAudioPlayerServiceImpl? = nil,
        sessionService: SessionService = DIContainer.shared.sessionService,
        subscriptionService: SubscriptionService = DIContainer.shared.subscriptionService,
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService,
        screenTimeRulesService: ScreenTimeRulesService? = nil
    ) {
        self.ayahAudioPlayer = ayahAudioPlayer ?? DIContainer.shared.ayahAudioPlayerService as! AyahAudioPlayerServiceImpl
        self.sessionService = sessionService
        self.subscriptionService = subscriptionService
        self.quranPreferences = quranPreferences
        self.screenTimeRulesService = screenTimeRulesService ?? DIContainer.shared.screenTimeRulesService

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

    private func handleQueueFinished() async {
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

    private func unblockMinutes(for ruleId: UUID) -> Int {
        guard let rule = screenTimeRulesService.getRule(id: ruleId) else { return 15 }
        return rule.isHardMode ? 20 : 15
    }

    func startSession() async {
        do {
            sessionDidEnd = false

            guard !ayahs.isEmpty else {
                errorMessage = "No ayahs to play"
                return
            }

            let reciterId = quranPreferences.selectedReciterId

            // SessionService handles shield application
            let newSession = try await sessionService.startSession(
                type: .listening,
                surahNumbers: surahs.map { $0.surah.number },
                reciterId: reciterId
            )
            newSession.isUnblockSession = isUnblockSession
            newSession.unlockRuleId = unlockRuleId
            session = newSession

            do {
                try await ayahAudioPlayer.loadQueue(ayahs, reciterId: reciterId)
                ayahAudioPlayer.play()
            } catch {
                if isUnblockSession {
                    showUnblockFallback = true
                } else {
                    errorMessage = error.localizedDescription
                }
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
