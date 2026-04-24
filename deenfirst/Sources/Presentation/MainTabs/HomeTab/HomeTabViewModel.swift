import Combine
import SwiftUI

@MainActor
final class HomeTabViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var dailySurah: Surah?
    @Published var isLoadingDailySurah = false
    @Published var appLimits: [ScreenTimeRule] = []
    @Published var timeLimits: [ScreenTimeRule] = []
    @Published var unblockRemainingSeconds: [UUID: Int] = [:]
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
    private var countdownTimers: [UUID: AnyCancellable] = [:]

    init(
        quranService: QuranService = DIContainer.shared.quranService,
        authService: AuthService = DIContainer.shared.authService,
        screenTimeRulesService: ScreenTimeRulesService? = nil,
        pendingChangeService: PendingChangeService? = nil,
        sharedDefaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) {
        self.quranService = quranService
        self.authService = authService
        self.screenTimeRulesService = screenTimeRulesService ?? DIContainer.shared.screenTimeRulesService
        self.pendingChangeService = pendingChangeService ?? DIContainer.shared.pendingChangeService
        self.sharedDefaults = sharedDefaults
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
        let allRules = appLimits + timeLimits

        for rule in allRules {
            let key = AppGroupConstants.unblockExpiryKey(for: rule.id)
            let expiry = AppGroupConstants.sharedDefaults?.double(forKey: key) ?? 0

            guard expiry > 0 else {
                stopCountdown(for: rule.id)
                continue
            }

            let expiresAt = Date(timeIntervalSince1970: expiry)
            let remaining = Int(UnblockCountdownCalculator.remaining(expiresAt: expiresAt))
            guard remaining > 0 else {
                stopCountdown(for: rule.id)
                Task { await screenTimeRulesService.reblockIfExpired(ruleId: rule.id) }
                continue
            }

            unblockRemainingSeconds[rule.id] = remaining
            startCountdownTimer(ruleId: rule.id, expiresAt: expiresAt)
        }
    }

    private func startCountdownTimer(ruleId: UUID, expiresAt: Date) {
        countdownTimers[ruleId]?.cancel()

        countdownTimers[ruleId] = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                let remaining = Int(UnblockCountdownCalculator.remaining(expiresAt: expiresAt))
                if remaining <= 0 {
                    self.stopCountdown(for: ruleId)
                    Task { await self.screenTimeRulesService.reblockIfExpired(ruleId: ruleId) }
                } else {
                    self.unblockRemainingSeconds[ruleId] = remaining
                }
            }
    }

    private func stopCountdown(for ruleId: UUID) {
        countdownTimers[ruleId]?.cancel()
        countdownTimers.removeValue(forKey: ruleId)
        unblockRemainingSeconds.removeValue(forKey: ruleId)
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
        guard let seconds = unblockRemainingSeconds[ruleId] else { return nil }
        return UnblockCountdownCalculator.formatted(remaining: TimeInterval(seconds))
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
