//
//  HTTPClient.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation

enum HTTPError: Error, LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case timeout
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}

final class HTTPClient {
    static let shared: HTTPClient = HTTPClient()

    private let session: URLSession
    private let maxRetries: Int = 3
    private let timeoutInterval: TimeInterval = 30.0

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        self.session = URLSession(configuration: config)
    }

    func get<T: Decodable>(url: URL) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = timeoutInterval

                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPError.invalidResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw HTTPError.networkError(URLError(.badServerResponse))
                }

                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return decoded
                } catch {
                    throw HTTPError.decodingError(error)
                }

            } catch {
                lastError = error

                if attempt < maxRetries - 1 {
                    let backoffDelay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? HTTPError.networkError(URLError(.unknown))
    }
}
