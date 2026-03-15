import Foundation
import os

private let logger = Logger(subsystem: "com.deenfirst.api", category: "AlQuranAPIDataSource")

protocol AlQuranAPIDataSource {
    func fetchSurahTransliteration(surahNo: Int) async throws -> [Int: String]
    func fetchVerseTransliteration(surahNo: Int, ayahNo: Int) async throws -> String
}

final class AlQuranAPIDataSourceImpl: AlQuranAPIDataSource {
    private let httpClient: HTTPClient
    private let baseURL = "https://api.alquran.cloud/v1"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchSurahTransliteration(surahNo: Int) async throws -> [Int: String] {
        let endpoint = "\(baseURL)/surah/\(surahNo)/en.transliteration"
        guard let url = URL(string: endpoint) else {
            throw QuranAPIError.invalidResponse
        }
        let response: AlQuranSurahResponse = try await httpClient.fetch(url: url)
        let map = Dictionary(
            uniqueKeysWithValues: response.data.ayahs.map { ($0.numberInSurah, $0.text) })
        logger.debug("Fetched transliteration for surah \(surahNo): \(map.count) ayahs")
        return map
    }

    func fetchVerseTransliteration(surahNo: Int, ayahNo: Int) async throws -> String {
        let endpoint = "\(baseURL)/ayah/\(surahNo):\(ayahNo)/en.transliteration"
        guard let url = URL(string: endpoint) else {
            throw QuranAPIError.invalidResponse
        }
        let response: AlQuranVerseResponse = try await httpClient.fetch(url: url)
        return response.data.text
    }
}
