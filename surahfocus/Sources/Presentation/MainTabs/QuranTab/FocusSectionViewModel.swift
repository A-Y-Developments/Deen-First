import Foundation
import Combine
import SwiftUI
import FamilyControls
import ManagedSettings

@MainActor
final class FocusSectionViewModel: ObservableObject {
    @Published var selectedSurahs: [SurahWithRange] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPickerPresented = false
    @Published var appSelection = FamilyActivitySelection()

    private let sessionService: SessionService
    private let userRepository: UserRepository
    private let quranService: QuranService
    private weak var router: Router?

    init(
        sessionService: SessionService = DIContainer.shared.sessionService,
        userRepository: UserRepository = DIContainer.shared.userRepository,
        quranService: QuranService = DIContainer.shared.quranService,
        router: Router? = nil
    ) {
        self.sessionService = sessionService
        self.userRepository = userRepository
        self.quranService = quranService
        self.router = router
    }

    func loadData() async {
        isLoading = true

        do {
            if let surahNumbers = UserDefaults.standard.array(forKey: "lastSelectedSurahs") as? [Int] {
                let allSurahs = try await quranService.loadAllSurahs()
                selectedSurahs = surahNumbers.compactMap { number in
                    guard let surah = allSurahs.first(where: { $0.number == number }) else { return nil }

                    // Load saved ayah range for this surah
                    let rangeKey = "surahRange_\(number)"
                    let rangeData = UserDefaults.standard.dictionary(forKey: rangeKey) as? [String: Int]
                    let startAyah = rangeData?["start"] ?? 1
                    let endAyah = rangeData?["end"] ?? surah.numberOfAyahs

                    return SurahWithRange(surah: surah, startAyah: startAyah, endAyah: endAyah)
                }
            }

            // Load existing app selection from shared defaults
            loadAppSelectionFromDefaults()
        } catch {
            errorMessage = "Failed to load data"
        }

        isLoading = false
    }

    private func loadAppSelectionFromDefaults() {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else { return }

        var selection = FamilyActivitySelection()
        
        // Load application tokens
        if let tokenMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data] {
            for (_, data) in tokenMapping {
                if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                    selection.applicationTokens.insert(token)
                }
            }
        }

        // Load category tokens
        if let categoryMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] {
            for (_, data) in categoryMapping {
                if let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                    selection.categoryTokens.insert(token)
                }
            }
        }

        appSelection = selection
    }

    func navigateToSelectSurah() {
        router?.navigate(to: .selectSurah(surahs: selectedSurahs))
    }

    func navigateToAyahRange(_ surahWithRange: SurahWithRange) {
        router?.navigate(to: .ayahRange(surah: surahWithRange.surah))
    }

    func updateSurahRange(_ surahWithRange: SurahWithRange) {
        if let index = selectedSurahs.firstIndex(where: { $0.surah.number == surahWithRange.surah.number }) {
            selectedSurahs[index] = surahWithRange
        }
    }

    func openAppPicker() {
        isPickerPresented = true
    }

    func updateAppSelection(_ newSelection: FamilyActivitySelection) {
        appSelection = newSelection
    }

    func saveAppSelection() {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else { return }

        // Save application tokens
        var tokenMapping: [String: Data] = [:]
        for token in appSelection.applicationTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                let key = String(token.hashValue)
                tokenMapping[key] = encoded
            }
        }
        sharedDefaults.set(tokenMapping, forKey: AppGroupConstants.tokenMappingKey)

        // Save category tokens
        var categoryMapping: [String: Data] = [:]
        for token in appSelection.categoryTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                let key = String(token.hashValue)
                categoryMapping[key] = encoded
            }
        }
        sharedDefaults.set(categoryMapping, forKey: AppGroupConstants.categoryTokensKey)
    }

    func removeSurah(_ surah: SurahWithRange) {
        selectedSurahs.removeAll { $0.id == surah.id }
    }

    var selectedAppsCount: Int {
        appSelection.applicationTokens.count
    }

    var canStartSession: Bool {
        !selectedSurahs.isEmpty
    }

    func navigateToDownload() async {
        guard canStartSession else { return }
        saveAppSelection()

        do {
            var allAyahs: [Ayah] = []
            for surahWithRange in selectedSurahs {
                let (_, ayahs) = try await quranService.loadSurah(number: surahWithRange.surah.number)
                let rangeAyahs = ayahs.filter { ayah in
                    ayah.numberInSurah >= surahWithRange.startAyah &&
                    ayah.numberInSurah <= surahWithRange.endAyah
                }
                allAyahs.append(contentsOf: rangeAyahs)
            }
            router?.navigate(to: .activeSession(surahs: selectedSurahs, ayahs: allAyahs))
        } catch {
            errorMessage = "Failed to load ayahs"
        }
    }
}