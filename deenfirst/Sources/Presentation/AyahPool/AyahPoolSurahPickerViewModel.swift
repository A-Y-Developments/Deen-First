import Foundation

@MainActor
final class AyahPoolSurahPickerViewModel: ObservableObject {
    // Surah list state
    @Published var allSurahs: [Surah] = []
    @Published var filteredSurahs: [Surah] = []
    @Published var searchText = ""
    @Published private(set) var isLoadingSurahs = false

    // Ayah list state
    @Published private(set) var selectedSurah: Surah?
    @Published private(set) var ayahs: [Ayah] = []
    @Published private(set) var isLoadingAyahs = false

    // Selection / pool state
    @Published private(set) var pooledKeys: Set<AyahKey> = []
    @Published var newlySelected: Set<AyahKey> = []

    @Published var errorMessage: String?
    @Published var showPoolFullAlert = false
    @Published var didFinishAdding = false

    private let ayahPoolService: AyahPoolService
    private let quranService: QuranService

    init(
        ayahPoolService: AyahPoolService? = nil,
        quranService: QuranService? = nil
    ) {
        self.ayahPoolService = ayahPoolService ?? DIContainer.shared.ayahPoolService
        self.quranService = quranService ?? DIContainer.shared.quranService
    }

    // MARK: - Derived

    var pooledCount: Int { pooledKeys.count }
    var remainingSlots: Int { max(0, AyahPoolServiceImpl.maxPoolSize - pooledCount - newlySelected.count) }
    var canAddMore: Bool { remainingSlots > 0 }
    var selectedCountLabel: String { "\(newlySelected.count) selected" }

    // MARK: - Loading

    func loadInitial() {
        Task {
            isLoadingSurahs = true
            errorMessage = nil
            do {
                let surahs = try await quranService.loadAllSurahs()
                allSurahs = surahs
                applySearch()
            } catch {
                errorMessage = error.localizedDescription
            }
            let pool = await ayahPoolService.fetchPool()
            pooledKeys = Set(pool.map { AyahKey(surah: $0.surahNumber, ayah: $0.ayahNumberInSurah) })
            isLoadingSurahs = false
        }
    }

    func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filteredSurahs = allSurahs
            return
        }
        filteredSurahs = allSurahs.filter { surah in
            surah.name.localizedCaseInsensitiveContains(query) ||
            surah.englishName.localizedCaseInsensitiveContains(query) ||
            surah.englishNameTranslation.localizedCaseInsensitiveContains(query) ||
            String(surah.number).localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Surah selection

    func selectSurah(_ surah: Surah) {
        selectedSurah = surah
        ayahs = []
        Task {
            isLoadingAyahs = true
            errorMessage = nil
            do {
                let result = try await quranService.loadSurah(number: surah.number)
                ayahs = result.1
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoadingAyahs = false
        }
    }

    func backToSurahList() {
        selectedSurah = nil
        ayahs = []
    }

    // MARK: - Ayah selection

    func isPooled(_ ayah: Ayah) -> Bool {
        pooledKeys.contains(key(for: ayah))
    }

    func isSelected(_ ayah: Ayah) -> Bool {
        newlySelected.contains(key(for: ayah))
    }

    /// Toggles selection for a newly chosen ayah.
    /// Returns `true` if the toggle was applied, `false` if blocked (pool full, already pooled).
    @discardableResult
    func toggleSelection(_ ayah: Ayah) -> Bool {
        let k = key(for: ayah)
        if pooledKeys.contains(k) { return false }
        if newlySelected.contains(k) {
            newlySelected.remove(k)
            return true
        }
        guard canAddMore else {
            showPoolFullAlert = true
            return false
        }
        newlySelected.insert(k)
        return true
    }

    // MARK: - Commit

    /// Adds all newly selected ayahs to the pool via the service.
    /// Stops early if the service reports the pool is full.
    func addSelected() {
        guard let surah = selectedSurah, !newlySelected.isEmpty else { return }
        let ayahsToAdd = ayahs
            .filter { newlySelected.contains(key(for: $0)) }
        Task {
            var addedKeys: [AyahKey] = []
            var hitPoolFull = false
            for ayah in ayahsToAdd {
                do {
                    try await ayahPoolService.addAyah(
                        surahNumber: surah.number,
                        ayahNumber: ayah.numberInSurah,
                        arabicText: ayah.text,
                        transliteration: ayah.transliteration
                    )
                    addedKeys.append(key(for: ayah))
                } catch AyahPoolError.poolFull(_) {
                    hitPoolFull = true
                    break
                } catch AyahPoolError.alreadyInPool {
                    addedKeys.append(key(for: ayah))
                } catch AyahPoolError.ayahTooShort(_, _) {
                    // Skip short ayahs silently for now; partial-add feedback (DF-054) adds UX.
                    continue
                } catch {
                    errorMessage = error.localizedDescription
                    break
                }
            }
            for k in addedKeys {
                pooledKeys.insert(k)
                newlySelected.remove(k)
            }
            if !addedKeys.isEmpty {
                clearPoolNudgeStamp()
            }
            if hitPoolFull {
                showPoolFullAlert = true
            } else if errorMessage == nil {
                didFinishAdding = true
            }
        }
    }

    /// Resets the HM "empty pool" nudge 24h gate so it can re-fire in a future
    /// HM session if the pool is emptied again.
    private func clearPoolNudgeStamp() {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.poolNudgeDateKey)
    }

    // MARK: - Helpers

    private func key(for ayah: Ayah) -> AyahKey {
        let surahNumber = selectedSurah?.number ?? ayah.surahNo
        return AyahKey(surah: surahNumber, ayah: ayah.numberInSurah)
    }
}

// MARK: - AyahKey

struct AyahKey: Hashable {
    let surah: Int
    let ayah: Int
}
