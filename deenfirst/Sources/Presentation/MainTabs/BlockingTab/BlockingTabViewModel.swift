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

    /// Per-rule remaining seconds. Each rule has its own independent countdown.
    /// Key = rule UUID. nil entry (or missing key) means that rule is not currently unblocked.
    @Published var unblockRemainingSeconds: [UUID: Int] = [:]

    // MARK: - Dependencies

    private let screenTimeRulesService: ScreenTimeRulesService
    private let pendingChangeService: PendingChangeService

    /// One timer subscription per rule — so rules tick down independently.
    private var countdownTimers: [UUID: AnyCancellable] = [:]

    // MARK: - Init

    init(
        screenTimeRulesService: ScreenTimeRulesService,
        pendingChangeService: PendingChangeService
    ) {
        self.screenTimeRulesService = screenTimeRulesService
        self.pendingChangeService = pendingChangeService
    }

    convenience init() {
        self.init(
            screenTimeRulesService: DIContainer.shared.screenTimeRulesService,
            pendingChangeService: DIContainer.shared.pendingChangeService
        )
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

    // MARK: - Countdown Timers (per-rule)

    /// Reads per-rule unblock expiry from SharedDefaults and starts or stops
    /// each rule's individual countdown timer.
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
                // Already expired — stop timer and trigger re-block
                stopCountdown(for: rule.id)
                Task { await screenTimeRulesService.reblockIfExpired(ruleId: rule.id) }
                continue
            }

            unblockRemainingSeconds[rule.id] = remaining
            startCountdownTimer(ruleId: rule.id, expiry: expiry)
        }
    }

    private func startCountdownTimer(ruleId: UUID, expiry: TimeInterval) {
        // Cancel existing timer for this rule before starting a new one
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

    // MARK: - Per-Rule Blocking State

    /// Returns whether a given rule is currently actively blocking apps.
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

    /// Returns "4:32" style display string for a specific rule's countdown, or nil if not unblocked.
    func countdownDisplay(for ruleId: UUID) -> String? {
        guard let seconds = unblockRemainingSeconds[ruleId] else { return nil }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingChangeService.hasPendingChange(for: ruleId)
    }
}