import Foundation

@MainActor
final class SelectSurahViewModel: ObservableObject {
    @Published var allSurahs: [Surah] = []
    @Published var filteredSurahs: [Surah] = []
    @Published var selectedSurahNumbers: Set<Int> = []
    @Published var searchText = ""
    @Published var isLoading = false

    private let quranService: QuranService

    init() {
        self.quranService = DIContainer.shared.quranService
    }

    func configure(existingSurahs: [SurahWithRange]) {
        self.selectedSurahNumbers = Set(existingSurahs.map { $0.surah.number })
    }

    func loadData() async {
        isLoading = true

        do {
            allSurahs = try await quranService.loadAllSurahs()
            applySearch()
        } catch {
        }

        isLoading = false
    }

    func applySearch() {
        if searchText.isEmpty {
            filteredSurahs = allSurahs
        } else {
            filteredSurahs = allSurahs.filter { surah in
                surah.name.localizedCaseInsensitiveContains(searchText) ||
                surah.englishName.localizedCaseInsensitiveContains(searchText) ||
                surah.englishNameTranslation.localizedCaseInsensitiveContains(searchText) ||
                String(surah.number).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    func toggleSelection(_ surah: Surah) {
        if selectedSurahNumbers.contains(surah.number) {
            selectedSurahNumbers.remove(surah.number)
        } else {
            selectedSurahNumbers.insert(surah.number)
        }
    }

    func isSelected(_ surah: Surah) -> Bool {
        selectedSurahNumbers.contains(surah.number)
    }

    var selectedCount: Int {
        selectedSurahNumbers.count
    }
}
