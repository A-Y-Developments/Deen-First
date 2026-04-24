import Foundation
import Alamofire

final class HTTPClient {
    static let shared = HTTPClient()

    private init() {}

    func fetch<T: Decodable>(url: URL) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func fetch<T: Decodable, U: Encodable>(
        url: URL,
        parameters: U
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, parameters: parameters)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    /// POSTs a pre-encoded multipart body to `url`. Returns the raw response body.
    /// Callers that need typed decoding should JSONDecode the returned data themselves.
    func uploadMultipart(
        url: URL,
        headers: [String: String],
        body: Data
    ) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            var afHeaders = HTTPHeaders()
            for (name, value) in headers {
                afHeaders.add(name: name, value: value)
            }
            AF.upload(body, to: url, method: .post, headers: afHeaders)
                .validate(statusCode: 200..<300)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        if let data = response.data {
                            let message = String(data: data, encoding: .utf8) ?? error.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(
                                response.response?.statusCode ?? 0,
                                message: message
                            ))
                        } else {
                            continuation.resume(throwing: error)
                        }
                    }
                }
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkUnavailable
    case timeout
    case serverError(Int, message: String = "")
    case requestFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError(let error): return "Failed to decode: \(error.localizedDescription)"
        case .networkUnavailable: return "Network unavailable. Check your connection."
        case .timeout: return "Request timed out. Please try again."
        case .serverError(let code, let message):
            return message.isEmpty ? "Server error (\(code)). Try again later." : message
        case .requestFailed(let error): return "Request failed: \(error.localizedDescription)"
        case .noData: return "No data received from server"
        }
    }
}
