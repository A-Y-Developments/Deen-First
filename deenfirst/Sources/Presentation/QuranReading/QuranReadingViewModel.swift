import AVFoundation
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

    @Published var isPlayingAudio = false
    @Published var playingAyahId: String?

    private let quranService: QuranService
    private let quranPreferences: QuranPreferencesService
    private let dashboardDataWriter: DashboardDataWriter?
    private var audioPlayer = AudioPlayerServiceImpl()

    /// Timestamp the reading view became visible. Used to compute reading
    /// duration written to the dashboard on disappear.
    private var readingStartedAt: Date?

    init(
        quranService: QuranService = DIContainer.shared.quranService,
        quranPreferences: QuranPreferencesService = DIContainer.shared.quranPreferencesService,
        dashboardDataWriter: DashboardDataWriter? = DIContainer.shared.dashboardDataWriter
    ) {
        self.quranService = quranService
        self.quranPreferences = quranPreferences
        self.dashboardDataWriter = dashboardDataWriter
    }

    func setup(with surahId: Int) async {
        readingStartedAt = Date()
        if allSurahs.isEmpty {
            await loadAllSurahs(initialSurahId: surahId)
        } else {
            await loadSurah(number: surahId)
        }
    }

    /// Called from QuranReadingView.onDisappear. Records reading time to the
    /// dashboard. Resets the start timestamp so a re-entry starts a fresh window.
    func recordReadingSession() {
        guard let startedAt = readingStartedAt else { return }
        readingStartedAt = nil
        let duration = Date().timeIntervalSince(startedAt)
        guard duration > 0 else { return }
        dashboardDataWriter?.recordQuranReading(duration: duration)
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

    func getTranslation(for ayah: Ayah) -> String {
        quranPreferences.getTranslation(for: ayah)
    }

    func playAyah(_ ayah: Ayah) async {
        let ayahId = ayah.uniqueScrollID
        if playingAyahId == ayahId && isPlayingAudio {
            stopAudio()
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let reciterId = quranPreferences.selectedReciterId
            let url = try await quranService.getAudioStreamURL(
                reciterId: reciterId, surahNo: ayah.surahNo, ayahNo: ayah.numberInSurah)
            try await audioPlayer.loadAudio(url: url, surahName: ayah.surahName, reciterName: "")
            audioPlayer.onPlaybackFinished = { [weak self] in
                Task { @MainActor in
                    self?.isPlayingAudio = false
                    self?.playingAyahId = nil
                }
            }
            audioPlayer.play()
            playingAyahId = ayahId
            isPlayingAudio = true
        } catch {
            isPlayingAudio = false
            playingAyahId = nil
        }
    }

    func stopAudio() {
        audioPlayer.stop()
        isPlayingAudio = false
        playingAyahId = nil
    }
}
