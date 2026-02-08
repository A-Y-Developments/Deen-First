import SwiftUI

@MainActor
final class SurahDetailViewModel: ObservableObject {
    let surahNumber: Int

    @Published var surah: Surah?
    @Published var ayahs: [Ayah] = []
    @Published var showTranslation: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let quranService: QuranService

    init(
        surahNumber: Int,
        quranService: QuranService = DIContainer.shared.quranService
    ) {
        self.surahNumber = surahNumber
        self.quranService = quranService
    }

    func loadSurahDetail() async {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            let (loadedSurah, loadedAyahs) = try await quranService.loadSurah(number: surahNumber)
            surah = loadedSurah
            ayahs = loadedAyahs
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func toggleTranslation() {
        showTranslation.toggle()
    }
}
