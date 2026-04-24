import Foundation

/// Step 1 temporary inline transcriber. Step 2 of Track A replaces this with
/// `WhisperAPIDataSource` routed through `HTTPClient`. Callers depend on the
/// `Transcriber` protocol, not this concrete type — so the swap is a
/// DIContainer one-liner.
final class WhisperTranscriber: Transcriber {
    private static let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")

    func transcribe(audioURL: URL, apiKey: String) async throws -> String {
        guard let endpoint = Self.endpoint else {
            throw RecitationScoringError.transcriptionFailed("Invalid Whisper endpoint")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let audioData = try Data(contentsOf: audioURL)
        request.httpBody = Self.makeBody(boundary: boundary, audioData: audioData)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw RecitationScoringError.transcriptionFailed(errorText)
        }

        let text =
            String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if text.hasPrefix("{") {
            throw RecitationScoringError.transcriptionFailed(text)
        }

        return text
    }

    private static func makeBody(boundary: String, audioData: Data) -> Data {
        var body = Data()

        func append(_ string: String) {
            if let data = string.data(using: .utf8) {
                body.append(data)
            }
        }

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

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"recitation.m4a\"\r\n")
        append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        append("\r\n")
        append("--\(boundary)--\r\n")

        return body
    }
}
