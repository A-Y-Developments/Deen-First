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
    @Published var editingSurah: SurahWithRange?
    @Published var isRangeSheetPresented = false

    private let sessionService: SessionService
    private let userRepository: UserRepository
    private let quranService: QuranService

    init(
        sessionService: SessionService = DIContainer.shared.sessionService,
        userRepository: UserRepository = DIContainer.shared.userRepository,
        quranService: QuranService = DIContainer.shared.quranService
    ) {
        self.sessionService = sessionService
        self.userRepository = userRepository
        self.quranService = quranService
    }
    
    func openRangeSheet(for surah: SurahWithRange) {
        editingSurah = surah
        isRangeSheetPresented = true
    }
    
    func deleteSurah(surah: Surah) {
        // Remove from UserDefaults
        let key = "surahRange_\(surah.number)"
        UserDefaults.standard.removeObject(forKey: key)

        // Also remove surah from lastSelectedSurahs
        if let surahNumbers = UserDefaults.standard.array(forKey: "lastSelectedSurahs") as? [Int] {
            let updatedNumbers = surahNumbers.filter { $0 != surah.number }
            UserDefaults.standard.set(updatedNumbers, forKey: "lastSelectedSurahs")
        }
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
        appSelection.applicationTokens.count + appSelection.categoryTokens.count
    }

    var appsCountText: String {
        let apps = appSelection.applicationTokens.count
        let categories = appSelection.categoryTokens.count

        if apps > 0 && categories > 0 {
            return "\(categories) categor\(categories == 1 ? "y" : "ies") and \(apps) app\(apps == 1 ? "" : "s") selected"
        } else if categories > 0 {
            return "\(categories) categor\(categories == 1 ? "y" : "ies") selected"
        } else if apps > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s") selected"
        } else {
            return "Select apps"
        }
    }

    var canStartSession: Bool {
        !selectedSurahs.isEmpty
    }

    enum SessionError: LocalizedError {
        case noSurahs

        var errorDescription: String? {
            switch self {
            case .noSurahs: return "No surahs selected"
            }
        }
    }

    func prepareForSession() async throws -> (surahs: [SurahWithRange], ayahs: [Ayah]) {
        guard canStartSession else { throw SessionError.noSurahs }

        // Save current app selection before starting session
        saveAppSelection()

        var allAyahs: [Ayah] = []
        for surahWithRange in selectedSurahs {
            let (_, ayahs) = try await quranService.loadSurah(number: surahWithRange.surah.number)
            let rangeAyahs = ayahs.filter { ayah in
                ayah.numberInSurah >= surahWithRange.startAyah &&
                ayah.numberInSurah <= surahWithRange.endAyah
            }
            allAyahs.append(contentsOf: rangeAyahs)
        }
        return (selectedSurahs, allAyahs)
    }
}
