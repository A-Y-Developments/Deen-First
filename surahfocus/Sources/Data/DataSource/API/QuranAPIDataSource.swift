import Foundation

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
        let endpoint = "\(baseURL)/surah.json"
        guard let url = URL(string: endpoint) else {
            throw QuranAPIError.invalidResponse
        }
        let response: SurahListResponse = try await httpClient.fetch(url: url)
        return response.surahs.map { $0.toSurahEntity() }
    }

    func fetchSurah(number: Int) async throws -> (Surah, [Ayah]) {
        guard number >= 1, number <= 114 else {
            throw QuranAPIError.invalidSurahNumber
        }

        let endpoint = "\(baseURL)/\(number).json"
        guard let url = URL(string: endpoint) else {
            throw QuranAPIError.invalidResponse
        }
        let response: SurahChapterResponse = try await httpClient.fetch(url: url)

        let verses = response.toVerses()
        guard !verses.isEmpty else {
            throw QuranAPIError.noVersesFound
        }

        let surah = response.toSurahEntity()
        let ayahs = verses.map { $0.toAyahEntity() }

        return (surah, ayahs)
    }

    func fetchVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        guard surahNo >= 1, surahNo <= 114 else {
            throw QuranAPIError.invalidSurahNumber
        }

        let endpoint = "\(baseURL)/\(surahNo)/\(ayahNo).json"
        guard let url = URL(string: endpoint) else {
            throw QuranAPIError.invalidResponse
        }
        let response: SingleVerseResponse = try await httpClient.fetch(url: url)
        return response.toAyahEntity()
    }

    func getReciters() -> [Reciter] {
        return [
            Reciter(id: 1, name: "Mishary Rashid Al Afasy", style: nil),
            Reciter(id: 2, name: "Abu Bakr Al Shatri", style: nil),
            Reciter(id: 3, name: "Nasser Al Qatami", style: nil),
            Reciter(id: 4, name: "Yasser Al Dosari", style: nil),
            Reciter(id: 5, name: "Hani Ar Rifai", style: nil)
        ]
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
