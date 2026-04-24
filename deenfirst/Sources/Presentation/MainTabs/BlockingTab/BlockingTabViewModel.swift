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

    /// Non-nil when PendingChangeSheet should be presented.
    @Published var pendingChangeSheetRule: ScreenTimeRule?
    @Published var pendingChangeSheetType: PendingChangeType = .edit

    // MARK: - Dependencies

    private let screenTimeRulesService: ScreenTimeRulesService
    private let pendingChangeService: PendingChangeService

    // DF-066: countdown ticking lives in one place, shared with HomeTabViewModel.
    private let countdownManager: UnblockCountdownManager
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        screenTimeRulesService: ScreenTimeRulesService,
        pendingChangeService: PendingChangeService
    ) {
        self.screenTimeRulesService = screenTimeRulesService
        self.pendingChangeService = pendingChangeService
        self.countdownManager = UnblockCountdownManager(
            screenTimeRulesService: screenTimeRulesService
        )
        countdownManager.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
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

    /// Delegates to `UnblockCountdownManager` (shared with HomeTabViewModel).
    func syncCountdownFromStorage() {
        countdownManager.sync(rules: appLimits + timeLimits)
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

    // MARK: - Lock Editing Gate

    /// Returns true if navigation to editor should proceed.
    /// Returns false and presents PendingChangeSheet if the rule is locked.
    func attemptEdit(_ rule: ScreenTimeRule) -> Bool {
        guard rule.isLockEditingEnabled else { return true }
        pendingChangeSheetType = .edit
        pendingChangeSheetRule = rule
        return false
    }

    /// Attempts to delete a rule. If locked, presents PendingChangeSheet instead.
    func attemptDelete(_ rule: ScreenTimeRule) async {
        guard rule.isLockEditingEnabled else {
            await performDelete(rule)
            return
        }
        pendingChangeSheetType = .delete
        pendingChangeSheetRule = rule
    }

    func confirmPendingChange() async {
        guard let rule = pendingChangeSheetRule else { return }
        await pendingChangeService.createPendingChange(
            for: rule,
            changeType: pendingChangeSheetType.rawValue,
            pendingData: nil
        )
        pendingChangeSheetRule = nil
    }

    func cancelExistingPendingChange() async {
        guard let rule = pendingChangeSheetRule else { return }
        await pendingChangeService.cancelPendingChange(for: rule.id)
        pendingChangeSheetRule = nil
    }

    func existingPendingChange(for ruleId: UUID) -> PendingRuleChange? {
        pendingChangeService.pendingChange(for: ruleId)
    }

    // MARK: - Delete Operations

    func deleteAppLimit(_ limit: ScreenTimeRule) async {
        await attemptDelete(limit)
    }

    func deleteTimeLimit(_ limit: ScreenTimeRule) async {
        await attemptDelete(limit)
    }

    private func performDelete(_ rule: ScreenTimeRule) async {
        do {
            try await screenTimeRulesService.deleteRule(id: rule.id)
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
        countdownManager.countdownDisplay(for: ruleId)
    }

    func hasPendingChange(for ruleId: UUID) -> Bool {
        pendingChangeService.hasPendingChange(for: ruleId)
    }
}