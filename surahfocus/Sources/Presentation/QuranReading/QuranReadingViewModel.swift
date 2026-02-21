import SwiftUI

@MainActor
final class QuranReadingViewModel: ObservableObject {
    @Published var allSurahs: [Surah] = []
    @Published var selectedSurah: Surah?
    @Published var ayahs: [Ayah] = []

    @Published var searchQuery: String = ""
    @Published var filteredAyahs: [Ayah] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let quranService: QuranService

    init(
        quranService: QuranService = DIContainer.shared.quranService
    ) {
        self.quranService = quranService
    }

    func setup(with surahId: Int) async {
        if allSurahs.isEmpty {
            await loadAllSurahs(initialSurahId: surahId)
        } else {
            await loadSurah(number: surahId)
        }
    }

    private func loadAllSurahs(initialSurahId: Int) async {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            allSurahs = try await quranService.loadAllSurahs()
            await loadSurah(number: initialSurahId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func loadSurah(number: Int) async {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            let (surah, loadedAyahs) = try await quranService.loadSurah(number: number)
            selectedSurah = surah
            ayahs = loadedAyahs
            filteredAyahs = loadedAyahs
            searchQuery = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func searchAyahs() {
        if searchQuery.isEmpty {
            filteredAyahs = ayahs
        } else {
            filteredAyahs = ayahs.filter { ayah in
                ayah.english.localizedCaseInsensitiveContains(searchQuery) ||
                String(ayah.numberInSurah).contains(searchQuery)
            }
        }
    }

    func clearSearch() {
        searchQuery = ""
        filteredAyahs = ayahs
    }
}
