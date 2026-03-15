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
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkUnavailable
    case timeout
    case serverError(Int)
    case requestFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError(let error): return "Failed to decode: \(error.localizedDescription)"
        case .networkUnavailable: return "Network unavailable. Check your connection."
        case .timeout: return "Request timed out. Please try again."
        case .serverError(let code): return "Server error (\(code)). Try again later."
        case .requestFailed(let error): return "Request failed: \(error.localizedDescription)"
        case .noData: return "No data received from server"
        }
    }
}
