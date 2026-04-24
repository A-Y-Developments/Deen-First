import CoreFoundation
import Foundation

// MARK: - Result

struct RecitationScore: Equatable {
    let passed: Bool
    let score: Int
    let transcript: String
}

// MARK: - Transcriber seam
//
// Temporary protocol that lets `RecitationScoringService` take a dependency
// on transcription without binding to the Whisper implementation details.
// Step 2 of Track A replaces the inline impl with `WhisperAPIDataSource`.

protocol Transcriber {
    func transcribe(audioURL: URL, apiKey: String) async throws -> String
}

// MARK: - Errors

enum RecitationScoringError: LocalizedError {
    case apiKeyMissing
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "OpenAI API key not configured. Add it in Settings."
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        }
    }
}

// MARK: - Protocol

protocol RecitationScoringService {
    /// Transcribes the audio at `audioURL`, compares it against `reference`,
    /// and returns a pass/fail verdict using the given similarity `threshold`.
    func score(audioURL: URL, reference: Ayah, threshold: Double) async throws -> RecitationScore
}

// MARK: - Thresholds

enum RecitationThreshold {
    static let normal: Double = 0.70
    static let hardMode: Double = 0.85
}

// MARK: - Implementation

final class RecitationScoringServiceImpl: RecitationScoringService {
    private let transcriber: Transcriber
    private let apiKeyProvider: () -> String?

    init(
        transcriber: Transcriber,
        apiKeyProvider: @escaping () -> String? = { Bundle.main.openAIApiKey.isEmpty ? nil : Bundle.main.openAIApiKey }
    ) {
        self.transcriber = transcriber
        self.apiKeyProvider = apiKeyProvider
    }

    func score(audioURL: URL, reference: Ayah, threshold: Double) async throws -> RecitationScore {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw RecitationScoringError.apiKeyMissing
        }

        let transcript: String
        do {
            transcript = try await transcriber.transcribe(audioURL: audioURL, apiKey: apiKey)
        } catch {
            throw RecitationScoringError.transcriptionFailed(error.localizedDescription)
        }

        let spokenTransliteration = Self.transliterateArabic(transcript)
        let score = Self.calculateSimilarity(
            reference: reference.arabic2,
            referenceTransliteration: reference.transliteration,
            spoken: transcript,
            spokenTransliteration: spokenTransliteration
        )

        let passed = score >= Int((threshold * 100).rounded())
        return RecitationScore(passed: passed, score: score, transcript: transcript)
    }

    // MARK: - Similarity (pure, internal for test visibility)

    static func calculateSimilarity(
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
        let finalScore = baseScore + wordMatchRatio * (100 - baseScore)
        return Int(finalScore)
    }

    private static func baseScore(for wordCount: Int) -> Double {
        switch wordCount {
        case 1...2: return 30
        case 3...4: return 20
        default:    return 0
        }
    }

    // MARK: - Normalization (pure, internal for test visibility)

    static func normalizeArabic(_ text: String) -> String {
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

    static func transliterateArabic(_ text: String) -> String {
        let mutable = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
        return mutable as String
    }

    static func normalizeTransliteration(_ text: String) -> String {
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
}
