import SwiftUI

@MainActor
final class QuranTabViewModel: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var filteredSurahs: [Surah] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var currentStreak: Int = 0
    @Published var user: User?
    @Published var viewMode: QuranViewMode = .surah
    
    enum QuranViewMode {
        case surah
        case juz
    }

    private let quranService: QuranService
    private let authService: AuthService

    init(
        quranService: QuranService = DIContainer.shared.quranService,
        authService: AuthService = DIContainer.shared.authService
    ) {
        self.quranService = quranService
        self.authService = authService
    }

    func loadSurahs() async {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            let loadedSurahs = try await quranService.loadAllSurahs()
            surahs = loadedSurahs
            filteredSurahs = loadedSurahs

            if let currentUser = try? await authService.getCurrentUser() {
                user = currentUser
                currentStreak = currentUser.currentStreak
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func searchSurahs() {
        filteredSurahs = quranService.searchSurahs(query: searchQuery, in: surahs)
    }

    func clearSearch() {
        searchQuery = ""
        filteredSurahs = surahs
    }
}
