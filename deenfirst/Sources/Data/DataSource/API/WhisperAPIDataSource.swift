import Foundation

// MARK: - Protocol

protocol WhisperAPIDataSource {
    /// Posts the audio at `audioURL` to the Whisper transcription endpoint and
    /// returns the transcribed Arabic text.
    func transcribe(audioURL: URL, apiKey: String) async throws -> String
}

// MARK: - Errors

enum WhisperAPIError: LocalizedError {
    case invalidEndpoint
    case invalidResponse(String)
    case audioUnreadable(Error)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "Invalid Whisper endpoint."
        case .invalidResponse(let msg): return msg
        case .audioUnreadable(let err): return "Could not read audio file: \(err.localizedDescription)"
        }
    }
}

// MARK: - Implementation

final class WhisperAPIDataSourceImpl: WhisperAPIDataSource {
    private static let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient = .shared) {
        self.httpClient = httpClient
    }

    func transcribe(audioURL: URL, apiKey: String) async throws -> String {
        guard let endpoint = Self.endpoint else {
            throw WhisperAPIError.invalidEndpoint
        }

        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
        } catch {
            throw WhisperAPIError.audioUnreadable(error)
        }

        let boundary = UUID().uuidString
        let body = Self.makeMultipartBody(boundary: boundary, audioData: audioData)
        let headers: [String: String] = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "multipart/form-data; boundary=\(boundary)",
        ]

        let responseData = try await httpClient.uploadMultipart(
            url: endpoint,
            headers: headers,
            body: body
        )

        let text = String(data: responseData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if text.hasPrefix("{") {
            throw WhisperAPIError.invalidResponse(text)
        }

        return text
    }

    // MARK: - Multipart body

    private static func makeMultipartBody(boundary: String, audioData: Data) -> Data {
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
