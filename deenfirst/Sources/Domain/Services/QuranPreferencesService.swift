import Foundation
import Combine

protocol QuranPreferencesService: ObservableObject {
    var selectedTranslation: TranslationLanguage { get set }
    var selectedReciterId: Int { get set }
    func getTranslation(for ayah: Ayah) -> String
    func getReciterAudio(for ayah: Ayah) -> ReciterAudio?
}


final class QuranPreferencesServiceImpl: QuranPreferencesService, ObservableObject {
    private let translationKey = "quran_selected_translation"
    // NOTE: Reusing existing key "lastReciterId" from SessionService.swift:104
    private let reciterKey = "lastReciterId"

    @Published var selectedTranslation: TranslationLanguage {
        didSet {
            UserDefaults.standard.set(selectedTranslation.rawValue, forKey: translationKey)
        }
    }

    @Published var selectedReciterId: Int {
        didSet {
            UserDefaults.standard.set(selectedReciterId, forKey: reciterKey)
        }
    }

    init() {
        // Load from UserDefaults with defaults
        let savedTranslation = UserDefaults.standard.string(forKey: translationKey)
        self.selectedTranslation = TranslationLanguage(rawValue: savedTranslation ?? "english") ?? .english

        let savedReciter = UserDefaults.standard.integer(forKey: reciterKey)
        self.selectedReciterId = savedReciter > 0 ? savedReciter : 1  // Default to 1
    }

    func getTranslation(for ayah: Ayah) -> String {
        ayah.translation(for: selectedTranslation)
    }

    func getReciterAudio(for ayah: Ayah) -> ReciterAudio? {
        ayah.audioUrls.first { $0.reciterId == selectedReciterId }
    }
}
