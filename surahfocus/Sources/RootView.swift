import SwiftUI

struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var paywallViewModel = PaywallViewModel()
    @StateObject private var screenTimePermissionViewModel = ScreenTimePermissionViewModel()
    @StateObject private var appSelectionViewModel = AppSelectionViewModel()
    @StateObject private var appLimitSetupViewModel = AppLimitSetupViewModel()
    @StateObject private var downtimeSetupViewModel = DowntimeSetupViewModel()

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            AuthView()
                .navigationDestination(for: Router.Route.self) { route in
                    destinationView(for: route)
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
            Text("Main Tabs - Phase 5")
        case .surahDetail(let surahId):
            Text("Surah \(surahId) - Phase 5")
        case .listenSession:
            Text("Listen Session - Phase 6")
        }
    }
}

#Preview {
    RootView()
}
