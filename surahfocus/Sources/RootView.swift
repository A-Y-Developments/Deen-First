import SwiftUI
import FamilyControls

struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var paywallViewModel = PaywallViewModel()
    @StateObject private var screenTimePermissionViewModel = ScreenTimePermissionViewModel()
    @StateObject private var appSelectionViewModel = AppSelectionViewModel()
    @StateObject private var appLimitSetupViewModel = AppLimitSetupViewModel()
    @StateObject private var downtimeSetupViewModel = DowntimeSetupViewModel()
    @StateObject private var quranTabViewModel = QuranTabViewModel()

    @State private var currentUser: User?
    @State private var isPremium = false
    @State private var isScreenTimeAuthorized = false
    @State private var refreshTrigger = 0
    @State private var isCheckingState = true

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            if isCheckingState {
                LoadingOverlay()
            } else if currentUser == nil {
                AuthView()
                    .navigationDestination(for: Router.Route.self) { route in
                        destinationView(for: route)
                    }
            } else if !currentUser!.hasCompletedOnboarding {
                OnboardingView()
                    .navigationDestination(for: Router.Route.self) { route in
                        destinationView(for: route)
                    }
            } else if !isPremium {
                PaywallView()
                    .navigationDestination(for: Router.Route.self) { route in
                        destinationView(for: route)
                    }
            } else if !isScreenTimeAuthorized {
                ScreenTimePermissionView()
                    .navigationDestination(for: Router.Route.self) { route in
                        destinationView(for: route)
                    }
            } else if !currentUser!.hasCompletedAppSelection {
                AppSelectionView()
                    .navigationDestination(for: Router.Route.self) { route in
                        destinationView(for: route)
                    }
            } else {
                MainTabView()
                    .navigationDestination(for: Router.Route.self) { route in
                        destinationView(for: route)
                    }
            }
        }
        .environmentObject(router)
        .environmentObject(authViewModel)
        .environmentObject(onboardingViewModel)
        .environmentObject(paywallViewModel)
        .environmentObject(screenTimePermissionViewModel)
        .environmentObject(appSelectionViewModel)
        .environmentObject(appLimitSetupViewModel)
        .environmentObject(downtimeSetupViewModel)
        .environmentObject(quranTabViewModel)
        .task {
            await checkUserState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSignIn)) { _ in
            refreshTrigger += 1
            Task {
                await checkUserState()
            }
        }
    }

    @MainActor
    private func checkUserState() async {
        isCheckingState = true

        // Check user
        currentUser = try? await DIContainer.shared.authService.getCurrentUser()

        guard currentUser != nil else {
            isCheckingState = false
            return
        }

        // Check subscription
        isPremium = (try? await DIContainer.shared.subscriptionService.checkSubscriptionStatus()) ?? false

        // Check Screen Time authorization
        isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved

        isCheckingState = false
    }

    @ViewBuilder
    private func destinationView(for route: Router.Route) -> some View {
        switch route {
        case .auth:
            AuthView()
        case .onboarding:
            OnboardingView()
        case .paywall:
            PaywallView()
        case .screenTimePermission:
            ScreenTimePermissionView()
        case .appSelection:
            AppSelectionView()
        case .appLimitSetup:
            AppLimitSetupView()
        case .downtimeSetup:
            DowntimeSetupView()
        case .mainTabs:
            MainTabView()
        case .surahDetail(let surahId):
            SurahDetailView(surahNumber: surahId)
        case .listenSession:
            Text("Listen Session - Phase 6")
        case .blocks:
            BlockingTabView()
        case .appLimit:
            AppLimitView()
        case .timeLimit:
            TimeLimitView()
        case .focusSection:
            FocusSectionView(router: router)
        case .selectSurah(let surahs):
            SelectSurahView(existingSurahs: surahs)
        case .ayahRange(let surah):
            AyahRangeSelectionView(surah: surah)
        case .downloadModal(let surahs):
            DownloadModalView(surahs: surahs)
        case .activeSession(let surahs, let ayahs):
            ActiveSessionView(surahs: surahs, ayahs: ayahs)
        case .sessionFinish(let duration, let surahCount):
            SessionFinishView(duration: duration, surahCount: surahCount)
        }
    }
}

extension Notification.Name {
    static let didSignIn = Notification.Name("didSignIn")
}

#Preview {
    RootView()
}
