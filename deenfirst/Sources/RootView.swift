import FamilyControls
import SwiftUI

struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var surveyViewModel = SurveyViewModel()
    @StateObject private var summaryViewModel = SummaryViewModel()
    @StateObject private var paywallViewModel = PaywallViewModel()
    @StateObject private var permissionSetupViewModel = PermissionSetupViewModel()
    @StateObject private var setupViewModel = SetupViewModel()
    @StateObject private var quranTabViewModel = QuranTabViewModel()
    @StateObject private var homeTabViewModel = HomeTabViewModel()
    @StateObject private var quranReadingViewModel = QuranReadingViewModel()
    @StateObject private var settingsTabViewModel = SettingsTabViewModel()
    @StateObject private var activeSessionViewModel = ActiveSessionViewModel()
    @StateObject private var focusSectionViewModel = FocusSectionViewModel()
    @StateObject private var ayahRangeSelectionViewModel = AyahRangeSelectionViewModel()
    @StateObject private var selectSurahViewModel = SelectSurahViewModel()
    @StateObject private var reciteToUnblockViewModel = ReciteToUnblockViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var blockingTabViewModel = BlockingTabViewModel()
    @StateObject private var appLimitViewModel = AppLimitViewModel()
    @StateObject private var timeLimitViewModel = TimeLimitViewModel()
    @StateObject private var supportViewModel = SupportViewModel()

    @State private var currentUser: User?
    @State private var isPremium = false
    @State private var isScreenTimeAuthorized = false
    @State private var hasCompletedSetup = false
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
                } else if !isPremium {
                    PaywallView()
                } else if !isScreenTimeAuthorized {
                    PermissionView()
                } else if !hasCompletedSetup {
                    AppToBlock()
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
        .environmentObject(homeTabViewModel)
        .environmentObject(quranReadingViewModel)
        .environmentObject(settingsTabViewModel)
        .environmentObject(activeSessionViewModel)
        .environmentObject(focusSectionViewModel)
        .environmentObject(ayahRangeSelectionViewModel)
        .environmentObject(selectSurahViewModel)
        .environmentObject(reciteToUnblockViewModel)
        .environmentObject(subscriptionViewModel)
        .environmentObject(blockingTabViewModel)
        .environmentObject(appLimitViewModel)
        .environmentObject(timeLimitViewModel)
        .environmentObject(supportViewModel)
        .task {
            await DIContainer.shared.pendingChangeService.applyExpiredChanges()
            await DIContainer.shared.sessionService.cleanupOrphanedSessions()
            try? await DIContainer.shared.sessionService.checkAndResetStreakIfNeeded()
            await DIContainer.shared.notificationSchedulingService.scheduleMotivationalNotifications()
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
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task {
                await DIContainer.shared.pendingChangeService.applyExpiredChanges()
                await DIContainer.shared.sessionService.cleanupOrphanedSessions()
                try? await DIContainer.shared.sessionService.checkAndResetStreakIfNeeded()
                await DIContainer.shared.screenTimeRulesService.reblockAllExpired()
                await DIContainer.shared.screenTimeRulesService.reblockEmergencyIfExpired()
                await DIContainer.shared.notificationSchedulingService.scheduleMotivationalNotifications()
            }
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

        hasCompletedSetup = currentUser?.hasCompletedSetup ?? false

        let subscriptionActive = (try? await DIContainer.shared.subscriptionService.checkSubscriptionStatus()) ?? false
        isPremium = AppConstants.bypassPaywall || subscriptionActive

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
        case .permissionSetup, .setupAppToBlock, .setupSummary:
            if hasCompletedSetup {
                MainTabView()
                    .navigationBarBackButtonHidden(true)
            } else {
                switch route {
                case .permissionSetup:
                    PermissionView()
                case .setupAppToBlock:
                    AppToBlock()
                case .setupSummary:
                    SetupSummary()
                default: EmptyView()
                }
            }
        case .mainTabs:
            MainTabView()
                .navigationBarBackButtonHidden(true)
        case .quranReading(let surahId):
            QuranReadingView(surahId: surahId)
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
        case .focusSection(let unlockRuleId):
            FocusSectionView(unlockRuleId: unlockRuleId)
        case .selectSurah(let surahs):
            SelectSurahView(existingSurahs: surahs)
        case .ayahRange(let surah):
            AyahRangeSelectionView(surah: surah)
        case .activeSession(let surahs, let ayahs, let isUnblockSession, let unlockRuleId):
            ActiveSessionView(surahs: surahs, ayahs: ayahs, isUnblockSession: isUnblockSession, unlockRuleId: unlockRuleId)
        case .sessionFinish(let duration, let surahCount):
            SessionFinishView(duration: duration, surahCount: surahCount)
        case .survey, .calculateSurvey, .summary, .howAppWork, .finalSummary:
            if currentUser?.hasCompletedOnboarding == true {
                MainTabView()
                    .navigationBarBackButtonHidden(true)
            } else {
                switch route {
                case .survey(let step, let answers):
                    SurveyView(step: step, answers: answers)
                case .calculateSurvey(let answers):
                    CalculateSurveyView(answers: answers)
                case .summary(let step, let answers):
                    switch step {
                    case 1: Summary1View(answers: answers)
                    case 2: Summary2View(answers: answers)
                    case 3: Summary3View()
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
                default: EmptyView()
                }
            }
        case .subscription:
            SubscriptionView()
        case .preferences:
            PreferencesView()
        case .support:
            SupportView()
        case .reciteToUnlock:
            ReciteToUnblockView()
        case .emergencyUnblock:
            EmergencyUnblockView()
        case .unblockDurationSelection(let ruleId):
            UnblockDurationSelectionView(ruleId: ruleId)
        case .dashboard:
            DashboardTabView()
        case .ayahPool:
            AyahPoolView()
        }
    }
}

extension Notification.Name {
    static let didSignIn = Notification.Name("didSignIn")
    static let didSignOut = Notification.Name("didSignOut")
    static let didCompleteOnboarding = Notification.Name("didCompleteOnboarding")
    static let didCompleteScreenTimeSetup = Notification.Name("didCompleteScreenTimeSetup")
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let subscriptionExpired = Notification.Name("subscriptionExpired")
    static let didPurchaseSubscription = Notification.Name("didPurchaseSubscription")
    static let didCompleteSession = Notification.Name("didCompleteSession")
}
