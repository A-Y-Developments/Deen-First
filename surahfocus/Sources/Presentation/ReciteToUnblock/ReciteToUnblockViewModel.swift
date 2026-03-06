import AVFoundation
import Combine
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

// MARK: - Recite State

enum ReciteState: Equatable {
    case idle
    case loadingAyah
    case ready
    case recording
    case transcribing
    case result(passed: Bool, score: Int)
    case error(String)
}

// MARK: - ViewModel

@MainActor
final class ReciteToUnblockViewModel: ObservableObject {

    // MARK: - Published State

    @Published var state: ReciteState = .idle
    @Published var ayah: Ayah?
    @Published var transcript: String = ""
    @Published var unblockDurationMinutes: Int = 5
    @Published var isPlayingAudio: Bool = false

    // MARK: - Target Rule
    
    /// Set by BlockingTabView before navigating here — identifies which rule's apps to unblock.
    /// nil means the flow was triggered from the Shield screen (no specific rule context),
    /// in which case handlePass falls back to unblocking ALL currently blocking rules.
    var targetRuleId: UUID?

    // MARK: - Dependencies

    private let quranPreferences: QuranPreferencesService
    private var quranService: QuranService {
        DIContainer.shared.quranService
    }
    private var screenTimeService: ScreenTimeRulesService {
        DIContainer.shared.screenTimeRulesService
    }

    // MARK: - Private

    private var audioPlayer = AudioPlayerServiceImpl()
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    private let surahRange = 1...114
    private let maxAyahWordCount = 20

    // MARK: - Init

    init(
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService
    ) {
        self.quranPreferences = quranPreferences
    }

    // MARK: - Load Random Ayah

    func loadRandomAyah() async {
        state = .loadingAyah

        let surahNo = Int.random(in: surahRange)
        do {
            let (_, ayahs) = try await quranService.loadSurah(number: surahNo)
            guard !ayahs.isEmpty else {
                state = .error("Could not load ayah. Check your connection.")
                return
            }

            // Filter ayahs by word count
            let filteredAyahs = ayahs.filter { ayah in
                let wordCount = ayah.arabic2.split(separator: " ").count
                return wordCount <= maxAyahWordCount
            }

            guard !filteredAyahs.isEmpty else {
                // Surah has no short ayahs, try another surah
                await loadRandomAyah()
                return
            }

            let picked = filteredAyahs.randomElement()!
            self.ayah = picked
            state = .ready
            print("... \(picked.surahNo):\(picked.numberInSurah)")
            await playAyahAudio()
        } catch {
            state = .error("Could not load ayah: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Playback

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

            let score = calculateSimilarity(reference: ayah.arabic2, spoken: transcribed)

            print("[Recite Similarity]")
            print("  Ref: \(normalizeArabic(ayah.arabic2))")
            print("  Got: \(normalizeArabic(transcribed))")
            print("  Score: \(score)%")

            let passed = score >= 70

            if passed {
                await handlePass()
            }

            state = .result(passed: passed, score: score)

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

    private func calculateSimilarity(reference: String, spoken: String) -> Int {
        let refWords = Set(normalizeArabic(reference).split(separator: " ").map(String.init))
        let gotWords = Set(normalizeArabic(spoken).split(separator: " ").map(String.init))
        guard !refWords.isEmpty else { return 0 }
        let matched = refWords.intersection(gotWords).count
        return Int(Double(matched) / Double(refWords.count) * 100)
    }

    // MARK: - Unblock on Pass

    private func handlePass() async {
        sharedDefaults?.removeObject(forKey: AppGroupConstants.reciteRequested)
        sharedDefaults?.synchronize()

        if let ruleId = targetRuleId {
            // BlockingTabView path — unblock only the tapped rule
            await screenTimeService.temporaryUnblock(minutes: unblockDurationMinutes, ruleId: ruleId)
        } else {
            // Shield path — no specific rule, unblock all currently blocking rules
            await screenTimeService.temporaryUnblockAll(minutes: unblockDurationMinutes)
        }
    }

    // MARK: - Retry

    func retry() {
        transcript = ""
        Task { await loadRandomAyah() }
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