import AVFoundation
import Combine
import CoreFoundation
import Foundation

private func normalizeArabic(_ text: String) -> String {
    let decomposed = text.decomposedStringWithCompatibilityMapping
    let arabicLetters = CharacterSet(
        charactersIn:
            "\u{0621}\u{0622}\u{0623}\u{0624}\u{0625}\u{0626}\u{0627}\u{0628}\u{0629}\u{062A}\u{062B}\u{062C}\u{062D}\u{062E}\u{062F}\u{0630}\u{0631}\u{0632}\u{0633}\u{0634}\u{0635}\u{0636}\u{0637}\u{0638}\u{0639}\u{063A}\u{0641}\u{0642}\u{0643}\u{0644}\u{0645}\u{0646}\u{0647}\u{0648}\u{0649}\u{064A}"
    )
    let allowed = arabicLetters.union(.whitespaces)
    var result = decomposed.unicodeScalars
        .filter { allowed.contains($0) }
        .map { String($0) }
        .joined()
    result = result.replacingOccurrences(of: "إ", with: "ا")
    result = result.replacingOccurrences(of: "أ", with: "ا")
    result = result.replacingOccurrences(of: "آ", with: "ا")
    result = result.replacingOccurrences(of: "ة", with: "ه")
    result = result.replacingOccurrences(of: "ى", with: "ي")
    return result
        .components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
}

private func transliterateArabic(_ text: String) -> String {
    let mutable = NSMutableString(string: text) as CFMutableString
    CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
    return mutable as String
}

private func normalizeTransliteration(_ text: String) -> String {
    let latin = transliterateArabic(text).lowercased()
    let allowed = CharacterSet.alphanumerics.union(.whitespacesAndNewlines)
    let sanitized = latin.unicodeScalars
        .map { allowed.contains($0) ? String($0) : " " }
        .joined()

    return sanitized
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
}

// MARK: - Recite State

enum ReciteState: Equatable {
    case idle
    case loadingAyah
    case ready
    case recording
    case transcribing
    case result(passed: Bool, score: Int)
    /// Tier 2 only: Ayah 1 passed — show score, prompt user to proceed to Ayah 2.
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
    var unblockDurationMinutes: Int { tier.minutes }

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
    private var quranService: QuranService {
        DIContainer.shared.quranService
    }

    // MARK: - Private

    private var audioPlayer = AudioPlayerServiceImpl()
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let sharedDefaults: UserDefaults?

    private let surahRange = 1...114
    private let maxAyahWordCount = 20

    // Tier 2 sequence state
    private var ayahSequence: [Ayah] = []
    private var currentAyahIndex: Int = 0
    private var failureCountForCurrentAyah: Int = 0

    // MARK: - Computed

    private var isHardMode: Bool {
        guard let ruleId = targetRuleId else { return false }
        return screenTimeService.getRule(id: ruleId)?.isHardMode ?? false
    }

    private var recitationThreshold: Int { isHardMode ? 85 : 70 }
    private var minAyahWordCount: Int { isHardMode ? 5 : 1 }
    private var ayahCount: Int { tier == .tier2 ? 2 : 1 }

    // MARK: - Init

    init(
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService,
        screenTimeService: ScreenTimeRulesService = DIContainer.shared.screenTimeRulesService,
        sharedDefaults: UserDefaults? = UserDefaults(suiteName: AppGroupConstants.suiteName)
    ) {
        self.quranPreferences = quranPreferences
        self.screenTimeService = screenTimeService
        self.sharedDefaults = sharedDefaults
    }

    // MARK: - Load Ayah(s)

    func loadRandomAyah() async {
        state = .loadingAyah
        currentAyahIndex = 0
        failureCountForCurrentAyah = 0
        ayahSequence = []
        progressText = nil

        do {
            let sequence = try await loadAyahSequence(count: ayahCount)
            guard !sequence.isEmpty else {
                state = .error("Could not load ayah. Check your connection.")
                return
            }
            ayahSequence = sequence
            ayah = sequence[0]
            progressText = tier == .tier2 ? "Ayah 1 of 2" : nil
            state = .ready
            print("... \(sequence[0].surahNo):\(sequence[0].numberInSurah)")
            await playAyahAudio()
        } catch {
            state = .error("Could not load ayah: \(error.localizedDescription)")
        }
    }

    private func loadAyahSequence(count: Int) async throws -> [Ayah] {
        var result: [Ayah] = []
        var usedSurahs = Set<Int>()
        var attempts = 0
        let maxAttempts = 30

        while result.count < count && attempts < maxAttempts {
            attempts += 1
            var surahNo: Int
            var pickAttempts = 0
            repeat {
                surahNo = Int.random(in: surahRange)
                pickAttempts += 1
            } while usedSurahs.contains(surahNo) && pickAttempts < surahRange.count

            let (_, ayahs) = try await quranService.loadSurah(number: surahNo)
            let filtered = ayahs.filter { a in
                let wordCount = a.arabic2.split(separator: " ").count
                return wordCount >= minAyahWordCount && wordCount <= maxAyahWordCount
            }
            guard let picked = filtered.randomElement() else { continue }
            result.append(picked)
            usedSurahs.insert(surahNo)
        }
        return result
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

    // MARK: - Whisper API

    private func transcribeAndEvaluate(audioURL: URL) async {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            state = .error("OpenAI API key not configured. Add it in Settings.")
            return
        }

        guard let ayah = ayah else {
            state = .error("No ayah loaded.")
            return
        }

        do {
            let transcribed = try await callWhisperAPI(audioURL: audioURL, apiKey: apiKey)
            self.transcript = transcribed
            let spokenTransliteration = transliterateArabic(transcribed)

            let score = calculateSimilarity(
                reference: ayah.arabic2,
                referenceTransliteration: ayah.transliteration,
                spoken: transcribed,
                spokenTransliteration: spokenTransliteration
            )

            let normalizedReferenceTransliteration = normalizeTransliteration(ayah.transliteration)
            let usesTransliteration = !normalizedReferenceTransliteration.isEmpty

            print("[Recite Similarity]")
            print("  Mode: \(usesTransliteration ? "transliteration" : "arabic")")
            print(
                "  Ref: \(usesTransliteration ? normalizedReferenceTransliteration : normalizeArabic(ayah.arabic2))"
            )
            print(
                "  Got: \(usesTransliteration ? normalizeTransliteration(spokenTransliteration) : normalizeArabic(transcribed))"
            )
            print("  Score: \(score)%")

            let passed = score >= recitationThreshold

            if passed {
                if tier == .tier2 && currentAyahIndex == 0 {
                    // Ayah 1 passed in Tier 2 — advance to Ayah 2
                    currentAyahIndex = 1
                    if ayahSequence.count > 1 { self.ayah = ayahSequence[1] }
                    failureCountForCurrentAyah = 0
                    progressText = "Ayah 2 of 2"
                    state = .awaitingNextAyah(score: score)
                } else {
                    // Final pass (Tier 1, or Tier 2 Ayah 2)
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

        } catch {
            state = .error("Transcription failed: \(error.localizedDescription)")
        }
    }

    private func callWhisperAPI(audioURL: URL, apiKey: String) async throws -> String {
        var request = URLRequest(
            url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        func append(_ string: String) { body.append(string.data(using: .utf8)!) }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append("gpt-4o-mini-transcribe\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
        append("ar\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
        append("بسم الله الرحمن الرحيم، القرآن الكريم\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        append("text\r\n")

        let audioData = try Data(contentsOf: audioURL)
        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"recitation.m4a\"\r\n")
        append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        append("\r\n")
        append("--\(boundary)--\r\n")

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ReciteError.apiError(errorText)
        }

        let text =
            String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if text.hasPrefix("{") {
            throw ReciteError.apiError(text)
        }

        return text
    }

    // MARK: - Similarity

    private func calculateSimilarity(
        reference: String,
        referenceTransliteration: String,
        spoken: String,
        spokenTransliteration: String
    ) -> Int {
        let normalizedReferenceTransliteration = normalizeTransliteration(referenceTransliteration)
        let refWords: Set<String>
        let gotWords: Set<String>

        if !normalizedReferenceTransliteration.isEmpty {
            refWords = Set(normalizedReferenceTransliteration.split(separator: " ").map(String.init))
            gotWords = Set(
                normalizeTransliteration(spokenTransliteration).split(separator: " ").map(String.init)
            )
        } else {
            refWords = Set(normalizeArabic(reference).split(separator: " ").map(String.init))
            gotWords = Set(normalizeArabic(spoken).split(separator: " ").map(String.init))
        }

        guard !refWords.isEmpty else { return 0 }
        let matched = refWords.intersection(gotWords).count
        let baseScore = baseScore(for: refWords.count)
        let wordMatchRatio = Double(matched) / Double(refWords.count)
        let score = baseScore + wordMatchRatio * (100 - baseScore)
        return Int(score)
    }

    private func baseScore(for wordCount: Int) -> Double {
        switch wordCount {
        case 1...2:
            return 30
        case 3...4:
            return 20
        default:
            return 0
        }
    }

    // MARK: - Unblock on Pass

    func handlePass() async {
        sharedDefaults?.removeObject(forKey: AppGroupConstants.reciteRequested)
        sharedDefaults?.synchronize()

        if let ruleId = targetRuleId {
            // Validate rule is still blocking — user may have finished reciting after the block window ended
            guard let rule = screenTimeService.getRule(id: ruleId),
                  isRuleStillBlocking(rule) else {
                print("⏭️ [Recite] Rule \(ruleId) no longer blocking at recitation completion — skipping unblock")
                return
            }

            // Shorter-wins: don't replace an existing unblock that has more time remaining
            let expiryKey = AppGroupConstants.unblockExpiryKey(for: ruleId)
            let existingExpiry = sharedDefaults?.double(forKey: expiryKey) ?? 0
            let remainingSeconds = existingExpiry - Date().timeIntervalSince1970
            if existingExpiry > 0 && remainingSeconds > Double(tier.minutes * 60) {
                print("⏭️ [Recite] Shorter-wins: \(tier.minutes) min grant < \(Int(remainingSeconds))s remaining — not replacing")
                return
            }

            await screenTimeService.temporaryUnblock(minutes: tier.minutes, ruleId: ruleId)
        } else {
            // Shield path — temporaryUnblockAll already filters by currently blocking
            await screenTimeService.temporaryUnblockAll(minutes: tier.minutes)
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

    /// Called when user taps "Next Ayah" after Ayah 1 passes in Tier 2.
    func proceedToNextAyah() {
        transcript = ""
        state = .ready
        Task { await playAyahAudio() }
    }

    /// Hard Mode downgrade: accept Tier 1 (5 min) instead of continuing Tier 2.
    func acceptTier1Downgrade() async {
        tier = .tier1
        failureCountForCurrentAyah = 0
        progressText = nil
        if currentAyahIndex == 1 {
            // Ayah 1 already passed — grant 5 min immediately
            await handlePass()
            state = .result(passed: true, score: 0)
        } else {
            // Still on Ayah 1 — retry current ayah for Tier 1 access
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

    // MARK: - API Key

    private func getAPIKey() -> String? {
        let key = Bundle.main.openAIApiKey
        return key.isEmpty ? nil : key
    }

    // MARK: - Translation

    func getTranslation(for ayah: Ayah) -> String {
        quranPreferences.getTranslation(for: ayah)
    }
}

// MARK: - Errors

enum ReciteError: LocalizedError {
    case apiError(String)
    case noAudio

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "API Error: \(msg)"
        case .noAudio: return "No audio recorded"
        }
    }
}
