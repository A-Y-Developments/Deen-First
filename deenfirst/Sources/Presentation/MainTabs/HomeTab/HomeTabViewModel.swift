import Combine
import SwiftUI

@MainActor
final class HomeTabViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var dailySurah: Surah?
    @Published var isLoadingDailySurah = false
    @Published var appLimits: [ScreenTimeRule] = []
    @Published var timeLimits: [ScreenTimeRule] = []
    @Published var errorMessage: String?

    @Published var deenScore: Int = 0
    @Published var todayFocusSessions: Int = 0
    @Published var todayRecitationsPassed: Int = 0

    private let quranService: QuranService
    private let authService: AuthService
    private let screenTimeRulesService: ScreenTimeRulesService
    private let pendingChangeService: PendingChangeService
    private let sharedDefaults: UserDefaults?

    private var surahs: [Surah] = []
    private var cancellables: Set<AnyCancellable> = []
    // DF-066: single source of truth for countdown ticking — shared with BlockingTabViewModel.
    private let countdownManager: UnblockCountdownManager

    init(
        quranService: QuranService = DIContainer.shared.quranService,
        authService: AuthService = DIContainer.shared.authService,
        screenTimeRulesService: ScreenTimeRulesService? = nil,
        pendingChangeService: PendingChangeService? = nil,
        sharedDefaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) {
        self.quranService = quranService
        self.authService = authService
        let stService = screenTimeRulesService ?? DIContainer.shared.screenTimeRulesService
        self.screenTimeRulesService = stService
        self.pendingChangeService = pendingChangeService ?? DIContainer.shared.pendingChangeService
        self.sharedDefaults = sharedDefaults
        self.countdownManager = UnblockCountdownManager(
            screenTimeRulesService: stService,
            defaults: sharedDefaults
        )
        // Forward countdown ticks so SwiftUI re-renders card countdowns in this VM's views.
        countdownManager.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func loadData() async {
        await loadDailySurah()
        await refreshStreak()
        loadBlockingRules()
        syncCountdownFromStorage()
        refreshDashboardSummary()
    }

    /// Reads today's Quran/focus/recitation counters from the App Group and
    /// computes the Deen Score on-demand. Main-app-side score excludes screen
    /// time penalty (not readable without the ActivityReport extension) — the
    /// detail view renders the authoritative score via the extension.
    func refreshDashboardSummary() {
        let dayKey = DashboardDateKeys.dayKey(for: Date())
        let weekKey = DashboardDateKeys.weekKey(for: Date())

        let quranSeconds = sharedDefaults?.integer(forKey: AppGroupConstants.quranSecondsKey(dayKey)) ?? 0
        let focusSessions = sharedDefaults?.integer(forKey: AppGroupConstants.focusSessionsKey(dayKey)) ?? 0
        let recitationsPassed = sharedDefaults?.integer(forKey: AppGroupConstants.recitationsPassedKey(dayKey)) ?? 0
        let emergencyUnblocks = sharedDefaults?.integer(forKey: AppGroupConstants.emergencyUnblocksKey(weekKey)) ?? 0

        todayFocusSessions = focusSessions
        todayRecitationsPassed = recitationsPassed

        let input = DeenScoreInput(
            quranSeconds: quranSeconds,
            focusSessions: focusSessions,
            recitationsPassed: recitationsPassed,
            streakDays: currentStreak,
            screenTimeOverLimitSeconds: 0,
            emergencyUnblocksThisWeek: emergencyUnblocks
        )
        deenScore = calculateDeenScore(input)
    }

    private func loadDailySurah() async {
        if surahs.isEmpty {
            isLoadingDailySurah = true
            defer { isLoadingDailySurah = false }

            do {
                surahs = try await quranService.loadAllSurahs()
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        selectDailySurah()
    }

    func refreshStreak() async {
        if let currentUser = try? await authService.getCurrentUser() {
            currentStreak = currentUser.currentStreak
        }
    }

    func selectDailySurah() {
        guard !surahs.isEmpty else {
            dailySurah = nil
            return
        }

        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let year = calendar.component(.year, from: Date())

        let seed = Int64(dayOfYear + (year * 366))
        let mixed = (seed * 1103515245 + 12345) & 0x7fffffff
        let index = Int(mixed % Int64(surahs.count))

        dailySurah = surahs[index]
    }

    private func loadBlockingRules() {
        appLimits = screenTimeRulesService.getAppLimitRules()
        timeLimits = screenTimeRulesService.getTimeLimitRules()

        appLimits.sort { $0.createdAt < $1.createdAt }
        timeLimits.sort { $0.createdAt < $1.createdAt }
    }

    func syncCountdownFromStorage() {
        countdownManager.sync(rules: appLimits + timeLimits)
    }

    func isRuleCurrentlyBlocking(_ rule: ScreenTimeRule) -> Bool {
        guard DayHelper.isActiveToday(daysActive: rule.daysActive) else { return false }

        switch rule.type {
        case .appLimit:
            return ScreenTimeEvents.getTriggeredRuleIds().contains(rule.id.uuidString)
        case .timeLimit:
            return rule.isCurrentlyInBlockingPeriod
        }
    }

    func countdownDisplay(for ruleId: UUID) -> String? {
        countdownManager.countdownDisplay(for: ruleId)
    }

    var visibleAppLimits: [ScreenTimeRule] {
        appLimits
    }

    var visibleTimeLimits: [ScreenTimeRule] {
        timeLimits
    }

    var hasBlocks: Bool {
        !visibleAppLimits.isEmpty || !visibleTimeLimits.isEmpty
    }

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingChangeService.hasPendingChange(for: ruleId)
    }
}
