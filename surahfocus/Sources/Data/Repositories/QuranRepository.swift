import Foundation

protocol QuranRepository {
    func getAllSurahs() async throws -> [Surah]
    func getSurah(number: Int) async throws -> (Surah, [Ayah])
    func getVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah
    func getAudioURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> String
    func getReciters() -> [Reciter]
}

final class QuranRepositoryImpl: QuranRepository {
    private let apiDataSource: QuranAPIDataSource

    init(apiDataSource: QuranAPIDataSource) {
        self.apiDataSource = apiDataSource
    }

    func getAllSurahs() async throws -> [Surah] {
        return try await apiDataSource.fetchAllSurahs()
    }

    func getSurah(number: Int) async throws -> (Surah, [Ayah]) {
        return try await apiDataSource.fetchSurah(number: number)
    }

    func getVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        return try await apiDataSource.fetchVerse(surahNo: surahNo, ayahNo: ayahNo)
    }

    func getAudioURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> String {
        let verse = try await getVerse(surahNo: surahNo, ayahNo: ayahNo)

        guard let audio = verse.audioUrls.first(where: { $0.reciterId == reciterId }) else {
            throw QuranRepositoryError.reciterNotFound
        }

        return audio.url
    }

    func getReciters() -> [Reciter] {
        return apiDataSource.getReciters()
    }
}

enum QuranRepositoryError: LocalizedError {
    case reciterNotFound
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .reciterNotFound:
            return "Reciter not found."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}
