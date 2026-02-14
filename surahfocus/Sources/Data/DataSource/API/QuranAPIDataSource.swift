import Foundation
import os

private let logger = Logger(subsystem: "com.surahfocus.api", category: "QuranAPIDataSource")

private enum LogLabel {
    static let info = "INFO"
    static let error = "ERROR"
    static let success = "SUCCESS"
}

protocol QuranAPIDataSource {
    func fetchAllSurahs() async throws -> [Surah]
    func fetchSurah(number: Int) async throws -> (Surah, [Ayah])
    func fetchVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah
    func getReciters() -> [Reciter]
}

final class QuranAPIDataSourceImpl: QuranAPIDataSource {
    private let httpClient: HTTPClient
    private let baseURL = "https://quranapi.pages.dev/api"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchAllSurahs() async throws -> [Surah] {
        logger.debug("\(LogLabel.info): Fetching all surahs")
        let endpoint = "\(baseURL)/surah.json"
        guard let url = URL(string: endpoint) else {
            logger.error("\(LogLabel.error): Invalid URL for surah list")
            throw QuranAPIError.invalidResponse
        }
        let response: SurahListResponse = try await httpClient.fetch(url: url)
        let surahs = response.surahs.map { $0.toSurahEntity() }
        logger.debug("\(LogLabel.success): Fetched \(surahs.count) surahs")
        return surahs
    }

    func fetchSurah(number: Int) async throws -> (Surah, [Ayah]) {
        logger.debug("\(LogLabel.info): Fetching surah \(number)")
        guard number >= 1, number <= 114 else {
            logger.error("\(LogLabel.error): Invalid surah number: \(number)")
            throw QuranAPIError.invalidSurahNumber
        }

        let endpoint = "\(baseURL)/\(number).json"
        guard let url = URL(string: endpoint) else {
            logger.error("\(LogLabel.error): Invalid URL for surah \(number)")
            throw QuranAPIError.invalidResponse
        }
        let response: SurahChapterResponse = try await httpClient.fetch(url: url)

        let verses = response.toVerses()
        guard !verses.isEmpty else {
            logger.error("\(LogLabel.error): No verses found for surah \(number)")
            throw QuranAPIError.noVersesFound
        }

        let surah = response.toSurahEntity()
        let ayahs = verses.map { $0.toAyahEntity() }

        logger.debug("\(LogLabel.success): Fetched surah \(number) with \(ayahs.count) ayahs")
        return (surah, ayahs)
    }

    func fetchVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        logger.debug("\(LogLabel.info): Fetching verse \(surahNo):\(ayahNo)")
        guard surahNo >= 1, surahNo <= 114 else {
            logger.error("\(LogLabel.error): Invalid surah number: \(surahNo)")
            throw QuranAPIError.invalidSurahNumber
        }

        let endpoint = "\(baseURL)/\(surahNo)/\(ayahNo).json"
        guard let url = URL(string: endpoint) else {
            logger.error("\(LogLabel.error): Invalid URL for verse \(surahNo):\(ayahNo)")
            throw QuranAPIError.invalidResponse
        }
        let response: SingleVerseResponse = try await httpClient.fetch(url: url)
        logger.debug("\(LogLabel.success): Fetched verse \(surahNo):\(ayahNo)")
        return response.toAyahEntity()
    }

    func getReciters() -> [Reciter] {
        logger.debug("\(LogLabel.info): Getting reciters list")
        let reciters = [
            Reciter(id: 1, name: "Mishary Rashid Al Afasy", style: nil),
            Reciter(id: 2, name: "Abu Bakr Al Shatri", style: nil),
            Reciter(id: 3, name: "Nasser Al Qatami", style: nil),
            Reciter(id: 4, name: "Yasser Al Dosari", style: nil),
            Reciter(id: 5, name: "Hani Ar Rifai", style: nil)
        ]
        logger.debug("\(LogLabel.success): Returning \(reciters.count) reciters")
        return reciters
    }
}

enum QuranAPIError: LocalizedError {
    case invalidSurahNumber
    case invalidAyahNumber
    case noVersesFound
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidSurahNumber:
            return "Invalid surah number. Must be between 1 and 114."
        case .invalidAyahNumber:
            return "Invalid ayah number."
        case .noVersesFound:
            return "No verses found for this surah."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}
