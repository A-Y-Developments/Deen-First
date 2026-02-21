import SwiftUI
import FamilyControls

struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var surveyViewModel = SurveyViewModel()
    @StateObject private var summaryViewModel = SummaryViewModel()
    @StateObject private var paywallViewModel = PaywallViewModel()
    @StateObject private var permissionSetupViewModel = PermissionSetupViewModel()
    @StateObject private var setupViewModel = SetupViewModel()
    @StateObject private var quranTabViewModel = QuranTabViewModel()
    @StateObject private var quranReadingViewModel = QuranReadingViewModel()
    @StateObject private var settingsTabViewModel = SettingsTabViewModel()

    @State private var currentUser: User?
    @State private var isPremium = false
    @State private var isScreenTimeAuthorized = false
    @State private var isCheckingState = true

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            Group {
                if isCheckingState {
                    LoadingOverlay()
                } else if currentUser == nil {
                    AuthView()
                } else if !currentUser!.hasCompletedOnboarding {
                    SurveyView()
                        .environmentObject(surveyViewModel)
                } else if !isPremium {
                    PaywallView()
                } else if !isScreenTimeAuthorized {
                    // Subscribed but hasn't granted Screen Time permission
                    PermissionView()
                } else {
                    MainTabView()
                }
            }
            .navigationDestination(for: Router.Route.self) { route in
                destinationView(for: route)
            }
        }
        .environmentObject(router)
        .environmentObject(authViewModel)
        .environmentObject(surveyViewModel)
        .environmentObject(summaryViewModel)
        .environmentObject(paywallViewModel)
        .environmentObject(permissionSetupViewModel)
        .environmentObject(setupViewModel)
        .environmentObject(quranTabViewModel)
        .environmentObject(quranReadingViewModel)
        .environmentObject(settingsTabViewModel)
        .task {
            await checkUserState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSignIn)) { _ in
            Task { await checkUserState() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSignOut)) { _ in
            router.reset()
            Task { await checkUserState() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteScreenTimeSetup)) { _ in
            Task { await checkUserState() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didPurchaseSubscription)) { _ in
            Task { await checkUserState() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionExpired)) { _ in
            router.reset()
            isPremium = false
            Task { await checkUserState() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteOnboarding)) { _ in
            router.reset()
            Task { await checkUserState() }
        }
    }

    @MainActor
    private func checkUserState() async {
        isCheckingState = true

        currentUser = try? await DIContainer.shared.authService.getCurrentUser()

        guard currentUser != nil else {
            isCheckingState = false
            return
        }

        isPremium = (try? await DIContainer.shared.subscriptionService.checkSubscriptionStatus()) ?? false

        // Only check Screen Time if user is subscribed
        if isPremium {
            isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        }

        isCheckingState = false
    }

    @ViewBuilder
    private func destinationView(for route: Router.Route) -> some View {
        switch route {
        case .auth:
            AuthView()
        case .paywall(let isFromSettings, let currentPlan):
            PaywallView(isFromSettings: isFromSettings, currentPlan: currentPlan)
        case .permissionSetup:
            PermissionView()
        case .setupAppToBlock:
            AppToBlock()
        case .setupSummary:
            SetupSummary()
        case .mainTabs:
            MainTabView()
                .navigationBarBackButtonHidden(true)
        case .quranReading(let surahId):
            QuranReadingView(surahId: surahId)
                .environmentObject(quranReadingViewModel)
                .toolbar(.hidden, for: .tabBar)
        case .blocks:
            BlockingTabView()
        case .appLimit:
            AppLimitView()
        case .timeLimit:
            TimeLimitView()
        case .editAppLimit(let id):
            AppLimitView(limitId: id)
        case .editTimeLimit(let id):
            TimeLimitView(limitId: id)
        case .editAllDay(let id):
            AppLimitView(limitId: id, isAllDay: true)
        case .focusSection:
            FocusSectionView(router: router)
        case .selectSurah(let surahs):
            SelectSurahView(existingSurahs: surahs)
        case .ayahRange(let surah):
            AyahRangeSelectionView(surah: surah)
        case .activeSession(let surahs, let ayahs):
            ActiveSessionView(surahs: surahs, ayahs: ayahs)
        case .sessionFinish(let duration, let surahCount):
            SessionFinishView(duration: duration, surahCount: surahCount)
        case .survey(let step, let answers):
            SurveyView()
                .onAppear {
                    surveyViewModel.answers = answers
                    surveyViewModel.currentStep = step
                }
        case .calculateSurvey(let answers):
            CalculateSurveyView(answers: answers)
        case .summary(let step, let answers):
            switch step {
            case 1:
                Summary1View()
                    .onAppear {
                        summaryViewModel.answers = answers
                        summaryViewModel.currentStep = 1
                    }
            case 2: Summary2View()
            default: EmptyView()
            }
        case .howAppWork(let step):
            switch step {
            case 1: HowAppWork1View()
            case 2: HowAppWork2View()
            case 3: HowAppWork3View()
            default: EmptyView()
            }
        case .finalSummary:
            FinalSummaryView()
        case .subscription:
            SubscriptionView()
        case .preferences:
            PreferencesView()
        case .support:
            SupportView()
        }
    }
}

extension Notification.Name {
    static let didSignIn = Notification.Name("didSignIn")
    static let didSignOut = Notification.Name("didSignOut")
    static let didCompleteOnboarding = Notification.Name("didCompleteOnboarding") // NEW
    static let didCompleteScreenTimeSetup = Notification.Name("didCompleteScreenTimeSetup")
}
