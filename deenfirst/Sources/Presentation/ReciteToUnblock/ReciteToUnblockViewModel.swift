import AVFoundation
import Combine
import Foundation

// MARK: - Recite State

enum ReciteState: Equatable {
    case idle
    case loadingAyah
    case ready
    case recording
    case transcribing
    case result(passed: Bool, score: Int)
    /// Tier 2 only: a non-final ayah passed — show score, prompt user to proceed.
    case awaitingNextAyah(score: Int)
    /// Hard Mode only: 3 consecutive failures on the same ayah — offer Tier 1 downgrade.
    case downgradeOffered
    case error(String)
}

// MARK: - ViewModel

@MainActor
final class ReciteToUnblockViewModel: ObservableObject {

    // MARK: - Published State

    @Published var state: ReciteState = .idle
    @Published var ayah: Ayah?
    @Published var transcript: String = ""
    @Published var isPlayingAudio: Bool = false
    /// Non-nil for multi-ayah tiers (e.g. "Ayah 1 of 2"). Nil for Tier 1.
    @Published var progressText: String?
    /// True when Hard Mode is active but the ayah pool is empty — shown max once/day.
    @Published var showPoolNudge: Bool = false
    var unblockDurationMinutes: Int {
        get { tier.minutes(isHardMode: isHardMode) }
        set {
            if newValue <= 5 { tier = .tier1 }
            else if newValue <= 10 { tier = .tier2 }
            else { tier = .tier3 }
        }
    }

    // MARK: - Target Rule

    /// Set by UnblockDurationSelectionView before navigating here.
    var tier: UnblockTier = .tier1

    /// Set by UnblockDurationSelectionView before navigating here — identifies which rule's apps to unblock.
    /// nil means the flow was triggered from the Shield screen (no specific rule context),
    /// in which case handlePass falls back to unblocking ALL currently blocking rules.
    var targetRuleId: UUID?

    // MARK: - Dependencies

    private let quranPreferences: QuranPreferencesService
    private let screenTimeService: ScreenTimeRulesService
    private let scoringService: RecitationScoringService
    private let sequenceProvider: AyahSequenceProvider
    private let dashboardDataWriter: DashboardDataWriter?
    private var quranService: QuranService {
        DIContainer.shared.quranService
    }

    // MARK: - Private

    private var audioPlayer = AudioPlayerServiceImpl()
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let sharedDefaults: UserDefaults?
    private let nudgeDefaults: UserDefaults
    private let poolNudgeDateKey = AppGroupConstants.poolNudgeDateKey

    // Tier 2 sequence state — internal for test-driven state setup.
    var ayahSequence: [Ayah] = []
    var currentAyahIndex: Int = 0
    var failureCountForCurrentAyah: Int = 0

    // MARK: - Computed

    private var isHardMode: Bool {
        guard let ruleId = targetRuleId else { return false }
        return screenTimeService.getRule(id: ruleId)?.isHardMode ?? false
    }

    var similarityThreshold: Double {
        isHardMode ? RecitationThreshold.hardMode : RecitationThreshold.normal
    }
    var canRefreshAyah: Bool { !isHardMode }

    private var ayahCount: Int { tier.ayahCount(isHardMode: isHardMode) }

    // MARK: - Init

    init(
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService,
        screenTimeService: ScreenTimeRulesService = MainActor.assumeIsolated { DIContainer.shared.screenTimeRulesService },
        scoringService: RecitationScoringService = DIContainer.shared.recitationScoringService,
        sequenceProvider: AyahSequenceProvider = MainActor.assumeIsolated { DIContainer.shared.ayahSequenceProvider },
        sharedDefaults: UserDefaults? = UserDefaults(suiteName: AppGroupConstants.suiteName),
        nudgeDefaults: UserDefaults = AppGroupConstants.sharedDefaults ?? .standard,
        dashboardDataWriter: DashboardDataWriter? = DIContainer.shared.dashboardDataWriter
    ) {
        self.quranPreferences = quranPreferences
        self.screenTimeService = screenTimeService
        self.scoringService = scoringService
        self.sequenceProvider = sequenceProvider
        self.sharedDefaults = sharedDefaults
        self.nudgeDefaults = nudgeDefaults
        self.dashboardDataWriter = dashboardDataWriter
    }

    // MARK: - Load Ayah(s)

    func loadRandomAyah() async {
        state = .loadingAyah
        currentAyahIndex = 0
        failureCountForCurrentAyah = 0
        ayahSequence = []
        progressText = nil

        do {
            let result = try await sequenceProvider.makeSequence(count: ayahCount, isHardMode: isHardMode)
            guard !result.sequence.isEmpty else {
                state = .error("Could not load ayah. Check your connection.")
                return
            }
            ayahSequence = result.sequence
            ayah = result.sequence[0]
            let total = ayahCount
            progressText = total > 1 ? "Ayah 1 of \(total)" : nil
            if result.poolWasEmpty && isHardMode {
                maybeShowPoolNudge()
            }
            state = .ready
            await playAyahAudio()
        } catch {
            state = .error("Could not load ayah: \(error.localizedDescription)")
        }
    }

    private func maybeShowPoolNudge() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = nudgeDefaults.object(forKey: poolNudgeDateKey) as? Date,
           Calendar.current.isDate(last, inSameDayAs: today) {
            return
        }
        nudgeDefaults.set(today, forKey: poolNudgeDateKey)
        showPoolNudge = true
    }

    // MARK: - Audio Playback

    func toggleAudio() async {
        if isPlayingAudio {
            audioPlayer.pause()
            isPlayingAudio = false
            return
        }

        await playAyahAudio()
    }

    func playAyahAudio() async {
        guard let ayah else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let reciterId = quranPreferences.selectedReciterId
            let url = try await quranService.getAudioStreamURL(
                reciterId: reciterId, surahNo: ayah.surahNo, ayahNo: ayah.numberInSurah)
            try await audioPlayer.loadAudio(url: url, surahName: ayah.surahName, reciterName: "")
            audioPlayer.onPlaybackFinished = { [weak self] in
                Task { @MainActor in self?.isPlayingAudio = false }
            }
            audioPlayer.play()
            isPlayingAudio = true
        } catch {
            isPlayingAudio = false
        }
    }

    func stopAudio() {
        audioPlayer.stop()
        isPlayingAudio = false
    }

    // MARK: - Recording

    func startRecording() {
        stopAudio()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            state = .error("Microphone error: \(error.localizedDescription)")
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recitation_\(Date().timeIntervalSince1970).m4a")
        audioFileURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            state = .recording
        } catch {
            state = .error("Could not start recording: \(error.localizedDescription)")
        }
    }

    func stopRecordingAndTranscribe() {
        audioRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = audioFileURL else {
            state = .error("No audio recorded")
            return
        }

        state = .transcribing

        Task {
            await transcribeAndEvaluate(audioURL: url)
        }
    }

    // MARK: - Scoring orchestration

    private func transcribeAndEvaluate(audioURL: URL) async {
        guard let ayah = ayah else {
            state = .error("No ayah loaded.")
            return
        }

        // Dashboard: every submission counts as an attempt, regardless of outcome.
        dashboardDataWriter?.recordRecitationAttempt()

        do {
            let result = try await scoringService.score(
                audioURL: audioURL,
                reference: ayah,
                threshold: similarityThreshold
            )
            transcript = result.transcript
            await processRecitationOutcome(passed: result.passed, score: result.score)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Drives the tiered-unblock state machine after a recitation attempt.
    /// Public seam so `TieredUnblockIntegrationTests` can exercise the flow
    /// without the scoring service or Whisper.
    func processRecitationOutcome(passed: Bool, score: Int) async {
        if passed {
            dashboardDataWriter?.recordRecitationPassed()
            let total = ayahCount
            if currentAyahIndex < total - 1 {
                currentAyahIndex += 1
                if ayahSequence.count > currentAyahIndex { self.ayah = ayahSequence[currentAyahIndex] }
                failureCountForCurrentAyah = 0
                progressText = "Ayah \(currentAyahIndex + 1) of \(total)"
                state = .awaitingNextAyah(score: score)
            } else {
                await handlePass()
                state = .result(passed: true, score: score)
            }
        } else {
            failureCountForCurrentAyah += 1
            if isHardMode && failureCountForCurrentAyah >= 3 {
                state = .downgradeOffered
            } else {
                state = .result(passed: false, score: score)
            }
        }
    }

    // MARK: - Unblock on Pass

    func handlePass() async {
        sharedDefaults?.removeObject(forKey: AppGroupConstants.reciteRequested)
        sharedDefaults?.synchronize()

        // DF-024: Hard Mode Tier 3 grants 20 minutes (not 15). Always derive minutes via the
        // hard-mode-aware accessor so no tier silently falls back to the non-HM default.
        let grantMinutes = tier.minutes(isHardMode: isHardMode)

        if let ruleId = targetRuleId {
            guard let rule = screenTimeService.getRule(id: ruleId),
                  isRuleStillBlocking(rule) else {
                return
            }

            // Shorter-wins: don't replace an existing unblock that has more time remaining.
            let expiryKey = AppGroupConstants.unblockExpiryKey(for: ruleId)
            let existingExpiry = sharedDefaults?.double(forKey: expiryKey) ?? 0
            let remainingSeconds = existingExpiry - Date().timeIntervalSince1970
            if existingExpiry > 0 && remainingSeconds > Double(grantMinutes * 60) {
                return
            }

            await screenTimeService.temporaryUnblock(minutes: grantMinutes, ruleId: ruleId)
            // DF-022 / DF-023: record that this tier has been used in the current block window.
            UsedTiersStore.mark(tier, ruleId: ruleId, defaults: sharedDefaults)
        } else {
            await screenTimeService.temporaryUnblockAll(minutes: grantMinutes)
        }
    }

    private func isRuleStillBlocking(_ rule: ScreenTimeRule) -> Bool {
        guard DayHelper.isActiveToday(daysActive: rule.daysActive) else { return false }
        switch rule.type {
        case .appLimit:
            return ScreenTimeEvents.getTriggeredRuleIds().contains(rule.id.uuidString)
        case .timeLimit:
            return rule.isCurrentlyInBlockingPeriod
        }
    }

    // MARK: - Tier 2 Actions

    /// Called when user taps "Next Ayah" after a non-final ayah passes.
    func proceedToNextAyah() {
        transcript = ""
        state = .ready
        Task { await playAyahAudio() }
    }

    /// Hard Mode downgrade: accept Tier 1 (5 min) instead of continuing.
    func acceptTier1Downgrade() async {
        let hadPriorPass = currentAyahIndex > 0
        tier = .tier1
        failureCountForCurrentAyah = 0
        progressText = nil
        if hadPriorPass {
            // Leniency: user passed at least one ayah — grant tier1 immediately
            // even though Hard Mode tier1 normally requires 2 ayahs.
            await handlePass()
            state = .result(passed: true, score: 0)
        } else {
            state = .ready
        }
    }

    /// Hard Mode downgrade: decline and retry the same ayah (failure counter resets).
    func declineTier1Downgrade() {
        failureCountForCurrentAyah = 0
        state = .ready
    }

    // MARK: - Retry

    func retry() {
        transcript = ""
        state = .ready
    }

    // MARK: - Translation

    func getTranslation(for ayah: Ayah) -> String {
        quranPreferences.getTranslation(for: ayah)
    }
}
