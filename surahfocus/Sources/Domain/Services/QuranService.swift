import Foundation

protocol QuranService {
    func loadAllSurahs() async throws -> [Surah]
    func loadSurah(number: Int) async throws -> (Surah, [Ayah])
    func loadVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah
    func getAudioStreamURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> URL
    func getLocalAudioURL(reciterId: Int, surahNo: Int, ayahNo: Int) -> URL?
    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah]
    func getAvailableReciters() -> [Reciter]
}

final class QuranServiceImpl: QuranService {
    private let repository: QuranRepository

    init(repository: QuranRepository) {
        self.repository = repository
    }

    func loadAllSurahs() async throws -> [Surah] {
        return try await repository.getAllSurahs()
    }

    func loadSurah(number: Int) async throws -> (Surah, [Ayah]) {
        guard number >= 1, number <= 114 else {
            throw QuranServiceError.invalidSurahNumber
        }
        return try await repository.getSurah(number: number)
    }

    func loadVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        guard surahNo >= 1, surahNo <= 114 else {
            throw QuranServiceError.invalidSurahNumber
        }
        guard ayahNo >= 1 else {
            throw QuranServiceError.invalidAyahNumber
        }
        return try await repository.getVerse(surahNo: surahNo, ayahNo: ayahNo)
    }

    func getAudioStreamURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> URL {
        let urlString = try await repository.getAudioURL(reciterId: reciterId, surahNo: surahNo, ayahNo: ayahNo)
        guard let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" else {
            throw QuranServiceError.invalidAudioURL
        }
        return url
    }

    func getLocalAudioURL(reciterId: Int, surahNo: Int, ayahNo: Int) -> URL? {
        let audio = AyahAudio(reciterId: reciterId, surahNumber: surahNo, ayahNumber: ayahNo)
        let fileURL = AudioFileHelper.shared.fileURL(for: audio)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedQuery.isEmpty {
            return surahs
        }

        return surahs.filter { surah in
            matchesQuery(surah.name, query: trimmedQuery) ||
            matchesQuery(surah.englishNameTranslation, query: trimmedQuery) ||
            matchesQuery(String(surah.number), query: trimmedQuery)
        }
    }

    func getAvailableReciters() -> [Reciter] {
        return repository.getReciters()
    }

    private func matchesQuery(_ text: String, query: String) -> Bool {
        text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

enum QuranServiceError: LocalizedError {
    case invalidSurahNumber
    case invalidAyahNumber
    case invalidAudioURL
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidSurahNumber:
            return "Invalid surah number. Please enter a number between 1 and 114."
        case .invalidAyahNumber:
            return "Invalid ayah number."
        case .invalidAudioURL:
            return "Invalid audio URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
