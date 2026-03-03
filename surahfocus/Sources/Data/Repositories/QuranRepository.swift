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
    private let alQuranDataSource: AlQuranAPIDataSource

    init(apiDataSource: QuranAPIDataSource, alQuranDataSource: AlQuranAPIDataSource) {
        self.apiDataSource = apiDataSource
        self.alQuranDataSource = alQuranDataSource
    }

    func getAllSurahs() async throws -> [Surah] {
        return try await apiDataSource.fetchAllSurahs()
    }

    func getSurah(number: Int) async throws -> (Surah, [Ayah]) {
        async let surahResult = apiDataSource.fetchSurah(number: number)
        async let translitResult = alQuranDataSource.fetchSurahTransliteration(surahNo: number)
        let surahData = try await surahResult
        let transliterations = (try? await translitResult) ?? [:]
        let (surah, ayahs) = surahData
        let enriched = ayahs.map { $0.withTransliteration(transliterations[$0.numberInSurah] ?? "") }
        return (surah, enriched)
    }

    func getVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        async let verseResult = apiDataSource.fetchVerse(surahNo: surahNo, ayahNo: ayahNo)
        async let translitResult = alQuranDataSource.fetchVerseTransliteration(surahNo: surahNo, ayahNo: ayahNo)
        let verse = try await verseResult
        let translit = (try? await translitResult) ?? ""
        return verse.withTransliteration(translit)
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
