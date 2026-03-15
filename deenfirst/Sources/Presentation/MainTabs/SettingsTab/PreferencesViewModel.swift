import SwiftUI

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published var selectedTranslation: TranslationLanguage
    @Published var selectedReciterId: Int

    private let preferences: QuranPreferencesService
    private let quranService: QuranService

    init(
        preferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService,
        quranService: QuranService = DIContainer.shared.quranService
    ) {
        self.preferences = preferences
        self.quranService = quranService
        self.selectedTranslation = preferences.selectedTranslation
        self.selectedReciterId = preferences.selectedReciterId
    }

    func saveTranslation() {
        preferences.selectedTranslation = selectedTranslation
    }

    func saveReciter() {
        preferences.selectedReciterId = selectedReciterId
    }

    var reciterName: String {
        let reciters = quranService.getAvailableReciters()
        return reciters.first { $0.id == selectedReciterId }?.name ?? "Mishary Alafasy"
    }

    var availableReciters: [Reciter] {
        quranService.getAvailableReciters()
    }
}
