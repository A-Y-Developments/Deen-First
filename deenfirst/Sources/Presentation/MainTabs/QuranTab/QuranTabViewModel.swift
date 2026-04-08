import SwiftUI
import Combine

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
    @Published var ayahPoolCount: Int = 0

    let ayahPoolMaxSize = AyahPoolViewModel.maxPoolSize

    private var cancellables = Set<AnyCancellable>()

    enum QuranViewMode {
        case surah
        case juz
    }
    private let quranService: QuranService
    private let authService: AuthService
    private let notificationPermissionService: NotificationPermissionService
    private let ayahPoolService: AyahPoolService

    init(
        quranService: QuranService = DIContainer.shared.quranService,
        authService: AuthService = DIContainer.shared.authService,
        notificationPermissionService: NotificationPermissionService = DIContainer.shared.notificationPermissionService,
        ayahPoolService: AyahPoolService = MainActor.assumeIsolated { DIContainer.shared.ayahPoolService }
    ) {
        self.quranService = quranService
        self.authService = authService
        self.notificationPermissionService = notificationPermissionService
        self.ayahPoolService = ayahPoolService

        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .didCompleteSession)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshUser()
                }
            }
            .store(in: &cancellables)
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

    func refreshUser() async {
        if let currentUser = try? await authService.getCurrentUser() {
            user = currentUser
            currentStreak = currentUser.currentStreak
            print("🔄 QuranTabViewModel: Refreshed user, streak=\(currentStreak)")
        }
    }

    func loadAyahPoolCount() async {
        ayahPoolCount = await ayahPoolService.poolCount()
    }

    func requestNotificationPermission() async {
        _ = await notificationPermissionService.requestAuthorizationIfNeeded()
    }
}
