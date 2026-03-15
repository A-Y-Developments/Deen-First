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

    private let quranService: QuranService
    private let authService: AuthService
    private let screenTimeRulesService: ScreenTimeRulesService

    private var surahs: [Surah] = []
    private var countdownTimers: [UUID: AnyCancellable] = [:]

    init(
        quranService: QuranService = DIContainer.shared.quranService,
        authService: AuthService = DIContainer.shared.authService,
        screenTimeRulesService: ScreenTimeRulesService? = nil
    ) {
        self.quranService = quranService
        self.authService = authService
        self.screenTimeRulesService = screenTimeRulesService ?? DIContainer.shared.screenTimeRulesService
    }

    func loadData() async {
        await loadDailySurah()
        await refreshStreak()
        loadBlockingRules()
        syncCountdownFromStorage()
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

            let remaining = Int(expiry - Date().timeIntervalSince1970)
            guard remaining > 0 else {
                stopCountdown(for: rule.id)
                Task { await screenTimeRulesService.reblockIfExpired(ruleId: rule.id) }
                continue
            }

            unblockRemainingSeconds[rule.id] = remaining
            startCountdownTimer(ruleId: rule.id, expiry: expiry)
        }
    }

    private func startCountdownTimer(ruleId: UUID, expiry: TimeInterval) {
        countdownTimers[ruleId]?.cancel()

        countdownTimers[ruleId] = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                let remaining = Int(expiry - Date().timeIntervalSince1970)
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
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var visibleAppLimits: [ScreenTimeRule] {
        appLimits.filter { isRuleCurrentlyBlocking($0) || countdownDisplay(for: $0.id) != nil }
    }

    var visibleTimeLimits: [ScreenTimeRule] {
        timeLimits.filter { isRuleCurrentlyBlocking($0) || countdownDisplay(for: $0.id) != nil }
    }

    var hasBlocks: Bool {
        !visibleAppLimits.isEmpty || !visibleTimeLimits.isEmpty
    }
}
