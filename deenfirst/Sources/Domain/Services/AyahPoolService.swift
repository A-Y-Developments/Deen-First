import Foundation

// MARK: - Errors

enum AyahPoolError: Error {
    case poolFull
    case alreadyInPool
}

// MARK: - Protocol

@MainActor
protocol AyahPoolService {
    func fetchPool() async -> [AyahPoolItem]
    func addAyah(surahNumber: Int, ayahNumber: Int, arabicText: String, transliteration: String) async throws
    func removeAyah(id: UUID) async
    func poolCount() async -> Int
    func nextAyah(excludeShort: Bool) -> AyahPoolItem?
    func isEmpty() async -> Bool
}

// MARK: - Implementation

@MainActor
final class AyahPoolServiceImpl: AyahPoolService {
    private static let maxPoolSize = 20

    private let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func fetchPool() async -> [AyahPoolItem] {
        (try? localDataSource.fetchAyahPool()) ?? []
    }

    func addAyah(
        surahNumber: Int,
        ayahNumber: Int,
        arabicText: String,
        transliteration: String
    ) async throws {
        let current = try localDataSource.fetchAyahPool()

        if current.count >= Self.maxPoolSize {
            throw AyahPoolError.poolFull
        }

        let isDuplicate = current.contains {
            $0.surahNumber == surahNumber && $0.ayahNumberInSurah == ayahNumber
        }
        if isDuplicate {
            throw AyahPoolError.alreadyInPool
        }

        let wordCount = arabicText
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .count

        let item = AyahPoolItem(
            surahNumber: surahNumber,
            ayahNumberInSurah: ayahNumber,
            arabicText: arabicText,
            transliteration: transliteration,
            wordCount: wordCount
        )
        try localDataSource.insertAyahPoolItem(item)
    }

    func removeAyah(id: UUID) async {
        let pool = (try? localDataSource.fetchAyahPool()) ?? []
        guard let item = pool.first(where: { $0.id == id }) else { return }
        try? localDataSource.deleteAyahPoolItem(item)
    }

    func poolCount() async -> Int {
        ((try? localDataSource.fetchAyahPool()) ?? []).count
    }

    func nextAyah(excludeShort: Bool) -> AyahPoolItem? {
        let pool = (try? localDataSource.fetchAyahPool()) ?? []
        let eligible = excludeShort ? pool.filter { $0.wordCount >= 5 } : pool
        return eligible.randomElement()
    }

    func isEmpty() async -> Bool {
        ((try? localDataSource.fetchAyahPool()) ?? []).isEmpty
    }
}
