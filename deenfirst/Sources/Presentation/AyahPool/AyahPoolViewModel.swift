import Foundation

@MainActor
final class AyahPoolViewModel: ObservableObject {
    static let maxPoolSize = 20

    @Published private(set) var items: [AyahPoolItem] = []
    @Published private(set) var surahNames: [Int: String] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showPoolFullAlert = false

    private let ayahPoolService: AyahPoolService
    private let quranService: QuranService

    init(
        ayahPoolService: AyahPoolService? = nil,
        quranService: QuranService? = nil
    ) {
        self.ayahPoolService = ayahPoolService ?? DIContainer.shared.ayahPoolService
        self.quranService = quranService ?? DIContainer.shared.quranService
    }

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }
    var isFull: Bool { items.count >= Self.maxPoolSize }
    var countLabel: String { "\(items.count) / \(Self.maxPoolSize)" }

    func load() {
        Task {
            isLoading = true
            errorMessage = nil
            items = await ayahPoolService.fetchPool()
                .sorted { $0.addedAt < $1.addedAt }
            if surahNames.isEmpty {
                do {
                    let surahs = try await quranService.loadAllSurahs()
                    var map: [Int: String] = [:]
                    for surah in surahs {
                        map[surah.number] = surah.englishName
                    }
                    surahNames = map
                } catch {
                    // Non-fatal: fall back to "Surah N" label
                    errorMessage = nil
                }
            }
            isLoading = false
        }
    }

    func remove(id: UUID) {
        Task {
            await ayahPoolService.removeAyah(id: id)
            items = await ayahPoolService.fetchPool()
                .sorted { $0.addedAt < $1.addedAt }
        }
    }

    /// Called when the user taps "+ Add Ayahs".
    /// Returns `true` if the caller should navigate to the surah picker.
    /// Returns `false` (and triggers the full-state alert) when the pool is already at capacity.
    func handleAddAyahsTap() -> Bool {
        if isFull {
            showPoolFullAlert = true
            return false
        }
        return true
    }

    func displayLabel(for item: AyahPoolItem) -> String {
        if let name = surahNames[item.surahNumber] {
            return "\(name) \(item.surahNumber):\(item.ayahNumberInSurah)"
        }
        return "Surah \(item.surahNumber):\(item.ayahNumberInSurah)"
    }
}
