import Foundation

// MARK: - Result

struct AyahSequenceResult: Equatable {
    let sequence: [Ayah]
    /// True when the user's ayah pool is empty (or, in Hard Mode, contained no
    /// eligible items). Callers use this to trigger the once-per-day nudge.
    let poolWasEmpty: Bool
}

// MARK: - Protocol

@MainActor
protocol AyahSequenceProvider {
    /// Builds a sequence of `count` ayahs for a recitation tier.
    ///
    /// In Hard Mode with a non-empty eligible pool, draws from the pool first
    /// and falls back to random selection only if the pool runs short. In
    /// Normal Mode, uses the pool when available, otherwise random.
    ///
    /// - Parameters:
    ///   - count: Number of ayahs to produce.
    ///   - isHardMode: When true, filters pool + random picks to `wordCount >= 5`.
    func makeSequence(count: Int, isHardMode: Bool) async throws -> AyahSequenceResult
}

// MARK: - Implementation

@MainActor
final class AyahSequenceProviderImpl: AyahSequenceProvider {
    private let ayahPoolService: AyahPoolService
    private let quranService: QuranService

    private let surahRange = 1...114
    private let maxAyahWordCount = 20
    private let hardModeMinWordCount = 5

    init(
        ayahPoolService: AyahPoolService = MainActor.assumeIsolated { DIContainer.shared.ayahPoolService },
        quranService: QuranService = DIContainer.shared.quranService
    ) {
        self.ayahPoolService = ayahPoolService
        self.quranService = quranService
    }

    func makeSequence(count: Int, isHardMode: Bool) async throws -> AyahSequenceResult {
        let eligible = await resolveEligiblePool(isHardMode: isHardMode)
        let poolWasEmpty = eligible.isEmpty

        if eligible.isEmpty {
            let fallback = try await loadRandomSequence(count: count, isHardMode: isHardMode)
            return AyahSequenceResult(sequence: fallback, poolWasEmpty: true)
        }

        var result: [Ayah] = []
        for item in eligible.shuffled() {
            guard result.count < count else { break }
            guard let ayah = try? await fetchAyah(surahNo: item.surahNumber, ayahNo: item.ayahNumberInSurah) else { continue }
            result.append(ayah)
        }

        if result.count < count {
            let remaining = count - result.count
            let fallback = try await loadRandomSequence(count: remaining, isHardMode: isHardMode)
            result.append(contentsOf: fallback)
        }

        return AyahSequenceResult(sequence: result, poolWasEmpty: poolWasEmpty)
    }

    // MARK: - Private

    private func resolveEligiblePool(isHardMode: Bool) async -> [AyahPoolItem] {
        let pool = await ayahPoolService.fetchPool()
        return isHardMode ? pool.filter { $0.wordCount >= hardModeMinWordCount } : pool
    }

    private func fetchAyah(surahNo: Int, ayahNo: Int) async throws -> Ayah? {
        let (_, ayahs) = try await quranService.loadSurah(number: surahNo)
        return ayahs.first { $0.numberInSurah == ayahNo }
    }

    private func loadRandomSequence(count: Int, isHardMode: Bool) async throws -> [Ayah] {
        let minCount = isHardMode ? hardModeMinWordCount : 1
        var result: [Ayah] = []
        var usedSurahs = Set<Int>()
        var attempts = 0
        let maxAttempts = 30

        while result.count < count && attempts < maxAttempts {
            attempts += 1
            var surahNo: Int
            var pickAttempts = 0
            repeat {
                surahNo = Int.random(in: surahRange)
                pickAttempts += 1
            } while usedSurahs.contains(surahNo) && pickAttempts < surahRange.count

            let (_, ayahs) = try await quranService.loadSurah(number: surahNo)
            let filtered = ayahs.filter { a in
                let wordCount = a.arabic2.split(separator: " ").count
                return wordCount >= minCount && wordCount <= maxAyahWordCount
            }
            guard let picked = filtered.randomElement() else { continue }
            result.append(picked)
            usedSurahs.insert(surahNo)
        }
        return result
    }
}
