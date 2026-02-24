import Combine
import FamilyControls
import SwiftUI

@MainActor
final class BlockingTabViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var appLimits: [ScreenTimeRule] = []
    @Published var timeLimits: [ScreenTimeRule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Remaining seconds on the temporary unblock. nil means not currently unblocked.
    /// All cards observe this single value — unblock is global across all rules.
    @Published var unblockRemainingSeconds: Int? = nil

    // MARK: - Dependencies

    private let screenTimeRulesService: ScreenTimeRulesService
    private var countdownTimer: AnyCancellable?

    // MARK: - Init

    init(screenTimeRulesService: ScreenTimeRulesService) {
        self.screenTimeRulesService = screenTimeRulesService
    }

    convenience init() {
        self.init(screenTimeRulesService: DIContainer.shared.screenTimeRulesService)
    }

    // MARK: - Load Data

    func loadBlockedApps() async {
        isLoading = true
        errorMessage = nil

        appLimits = screenTimeRulesService.getAppLimitRules()
        timeLimits = screenTimeRulesService.getTimeLimitRules()

        appLimits.sort { $0.createdAt < $1.createdAt }
        timeLimits.sort { $0.createdAt < $1.createdAt }

        isLoading = false

        syncCountdownFromStorage()
    }

    // MARK: - Countdown Timer

    /// Reads the unblock expiry from SharedDefaults and starts (or stops) the countdown timer.
    func syncCountdownFromStorage() {
        let expiry = AppGroupConstants.sharedDefaults?
            .double(forKey: AppGroupConstants.unblockExpiryKey) ?? 0

        guard expiry > 0 else {
            stopCountdown()
            return
        }

        let remaining = Int(expiry - Date().timeIntervalSince1970)
        guard remaining > 0 else {
            stopCountdown()
            Task { await screenTimeRulesService.reblockIfExpired() }
            return
        }

        unblockRemainingSeconds = remaining
        startCountdownTimer(expiry: expiry)
    }

    private func startCountdownTimer(expiry: TimeInterval) {
        countdownTimer?.cancel()

        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let remaining = Int(expiry - Date().timeIntervalSince1970)
                if remaining <= 0 {
                    self.stopCountdown()
                    Task { await self.screenTimeRulesService.reblockIfExpired() }
                } else {
                    self.unblockRemainingSeconds = remaining
                }
            }
    }

    private func stopCountdown() {
        countdownTimer?.cancel()
        countdownTimer = nil
        unblockRemainingSeconds = nil
    }

    // MARK: - Per-Rule Blocking State

    /// Returns whether a given rule is currently actively blocking apps.
    /// - AppLimit: quota was reached today (persisted in triggeredRuleIds)
    /// - TimeLimit: currently inside the scheduled window on an active day
    func isRuleCurrentlyBlocking(_ rule: ScreenTimeRule) -> Bool {
        guard DayHelper.isActiveToday(daysActive: rule.daysActive) else { return false }

        switch rule.type {
        case .appLimit:
            return ScreenTimeEvents.getTriggeredRuleIds().contains(rule.id.uuidString)
        case .timeLimit:
            return rule.isCurrentlyInBlockingPeriod
        }
    }

    // MARK: - Delete Operations

    func deleteAppLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesService.deleteAppLimit(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTimeLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesService.deleteTimeLimit(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    var hasApps: Bool {
        !appLimits.isEmpty || !timeLimits.isEmpty
    }

    /// "4:32" style display string for the countdown button label.
    var countdownDisplay: String? {
        guard let seconds = unblockRemainingSeconds else { return nil }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
