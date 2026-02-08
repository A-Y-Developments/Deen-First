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
    private let cacheManager: QuranCacheManager

    init(apiDataSource: QuranAPIDataSource, cacheManager: QuranCacheManager) {
        self.apiDataSource = apiDataSource
        self.cacheManager = cacheManager
    }

    func getAllSurahs() async throws -> [Surah] {
        if let cached = await cacheManager.getCachedSurahList() {
            return cached
        }

        let surahs = try await apiDataSource.fetchAllSurahs()
        await cacheManager.cacheSurahList(surahs)
        return surahs
    }

    func getSurah(number: Int) async throws -> (Surah, [Ayah]) {
        if let cached = await cacheManager.getCachedSurah(number: number) {
            return cached
        }

        let (surah, ayahs) = try await apiDataSource.fetchSurah(number: number)
        await cacheManager.cacheSurah(number: number, surah: surah, ayahs: ayahs)
        return (surah, ayahs)
    }

    func getVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        if let cached = await cacheManager.getCachedVerse(surahNo: surahNo, ayahNo: ayahNo) {
            return cached
        }

        let verse = try await apiDataSource.fetchVerse(surahNo: surahNo, ayahNo: ayahNo)
        await cacheManager.cacheVerse(surahNo: surahNo, ayahNo: ayahNo, verse: verse)
        return verse
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
