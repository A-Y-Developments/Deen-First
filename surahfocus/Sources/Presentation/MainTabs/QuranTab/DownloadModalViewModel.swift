import Foundation
import Combine

@MainActor
final class DownloadModalViewModel: ObservableObject {
    @Published var isDownloading = false
    @Published var overallProgress: Double = 0
    @Published var downloadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var errorMessage: String?
    @Published var canDismiss = false
    @Published var downloadComplete = false

    private let downloadService: AudioDownloadServiceImpl
    private let quranService: QuranService
    private weak var router: Router?
    private var cancellables = Set<AnyCancellable>()

    let surahs: [SurahWithRange]
    private let reciterId: Int = 7

    var totalAyahCount: Int {
        surahs.reduce(0) { $0 + $1.ayahCount }
    }

    init(surahs: [SurahWithRange], router: Router? = nil) {
        self.surahs = surahs
        self.downloadService = DIContainer.shared.audioDownloadService as! AudioDownloadServiceImpl
        self.quranService = DIContainer.shared.quranService
        self.router = router

        setupBindings()
    }

    private func setupBindings() {
        downloadService.$isDownloading
            .assign(to: &$isDownloading)

        downloadService.$overallProgress
            .assign(to: &$overallProgress)

        downloadService.$downloadedCount
            .assign(to: &$downloadedCount)

        downloadService.$totalCount
            .assign(to: &$totalCount)
    }

    func setRouter(_ router: Router) {
        self.router = router
    }

    func startDownload() async {
        canDismiss = false
        downloadComplete = false

        do {
            var allAyahs: [Ayah] = []
            for surahWithRange in surahs {
                let (surah, ayahs) = try await quranService.loadSurah(number: surahWithRange.surah.number)
                let filteredAyahs = ayahs.filter { surahWithRange.ayahRange.contains($0.numberInSurah) }
                allAyahs.append(contentsOf: filteredAyahs)
            }

            let ayahAudios = allAyahs.map { ayah in
                AyahAudio(reciterId: reciterId, surahNumber: ayah.surahNo, ayahNumber: ayah.numberInSurah)
            }

            try await downloadService.downloadAyahs(ayahAudios)

            downloadComplete = true
            navigateToActiveSession(allAyahs)

        } catch {
            errorMessage = error.localizedDescription
            canDismiss = true
        }
    }

    func retry() {
        errorMessage = nil
        Task {
            await startDownload()
        }
    }

    private func navigateToActiveSession(_ ayahs: [Ayah]) {
        router?.navigate(to: .activeSession(surahs: surahs, ayahs: ayahs))
    }
}
