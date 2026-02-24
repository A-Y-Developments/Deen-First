import Foundation

@MainActor
final class AyahRangeSelectionViewModel: ObservableObject {
    @Published var startAyah: Int = 1
    @Published var endAyah: Int = 1
    @Published var errorMessage: String?

    private var surah: Surah?

    var surahName: String {
        surah?.name ?? ""
    }

    var surahAyahCount: Int {
        surah?.numberOfAyahs ?? 0
    }

    var isValid: Bool {
        guard let surah = surah else { return false }
        return startAyah >= 1 && endAyah <= surah.numberOfAyahs && startAyah <= endAyah
    }

    init() {}

    func configure(with surah: Surah) {
        self.surah = surah

        // Load saved range if exists
        let rangeKey = "surahRange_\(surah.number)"
        if let rangeData = UserDefaults.standard.dictionary(forKey: rangeKey) as? [String: Int] {
            self.startAyah = rangeData["start"] ?? 1
            self.endAyah = rangeData["end"] ?? surah.numberOfAyahs
        } else {
            self.startAyah = 1
            self.endAyah = surah.numberOfAyahs
        }
    }

    func validate() -> Bool {
        guard let surah = surah, isValid else {
            if startAyah > endAyah {
                errorMessage = "Start ayah cannot be greater than end ayah"
            } else if let surah = surah, (startAyah < 1 || endAyah > surah.numberOfAyahs) {
                errorMessage = "Ayah must be between 1 and \(surah.numberOfAyahs)"
            }
            return false
        }
        errorMessage = nil
        return true
    }

    func saveRange() {
        guard validate() else { return }
        guard let surah = surah else { return }

        // Save to UserDefaults - use key format "surahRange_{surahNumber}"
        let key = "surahRange_\(surah.number)"
        let rangeData: [String: Int] = ["start": startAyah, "end": endAyah]
        UserDefaults.standard.set(rangeData, forKey: key)
    }

    func deleteRange() {
        guard let surah = surah else { return }

        // Remove from UserDefaults
        let key = "surahRange_\(surah.number)"
        UserDefaults.standard.removeObject(forKey: key)

        // Also remove surah from lastSelectedSurahs
        if let surahNumbers = UserDefaults.standard.array(forKey: "lastSelectedSurahs") as? [Int] {
            let updatedNumbers = surahNumbers.filter { $0 != surah.number }
            UserDefaults.standard.set(updatedNumbers, forKey: "lastSelectedSurahs")
        }
    }
}
