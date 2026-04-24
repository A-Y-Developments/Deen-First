import Combine
import Foundation

/// Manages per-rule unblock countdown timers — reads expiry timestamps from the App Group,
/// publishes remaining-seconds updates, and triggers re-block when an unblock elapses.
///
/// DF-066: extracted from `HomeTabViewModel` and `BlockingTabViewModel`, where the same timer
/// plumbing was copy-pasted. Both VMs now compose one of these so the ticking logic lives
/// in a single place. Keep the pure math (`remaining(expiresAt:)`, `formatted(seconds:)`)
/// in `Shared/UnblockCountdownCalculator.swift` — that file is extension-safe; this one isn't.
@MainActor
final class UnblockCountdownManager: ObservableObject {
    /// Remaining seconds per rule id. Views bind to individual entries via `remainingSeconds[ruleId]`.
    @Published private(set) var remainingSeconds: [UUID: Int] = [:]

    private var timers: [UUID: AnyCancellable] = [:]
    private let defaults: UserDefaults?
    private let screenTimeRulesService: ScreenTimeRulesService

    init(
        screenTimeRulesService: ScreenTimeRulesService,
        defaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) {
        self.screenTimeRulesService = screenTimeRulesService
        self.defaults = defaults
    }

    /// Reads per-rule unblock expiry from App Group defaults and starts or stops each
    /// rule's individual countdown timer. Safe to call repeatedly; timers are replaced idempotently.
    func sync(rules: [ScreenTimeRule]) {
        for rule in rules {
            let key = AppGroupConstants.unblockExpiryKey(for: rule.id)
            let expiry = defaults?.double(forKey: key) ?? 0

            guard expiry > 0 else {
                stop(ruleId: rule.id)
                continue
            }

            let expiresAt = Date(timeIntervalSince1970: expiry)
            let remaining = Int(UnblockCountdownCalculator.remaining(expiresAt: expiresAt))
            guard remaining > 0 else {
                stop(ruleId: rule.id)
                Task { await screenTimeRulesService.reblockIfExpired(ruleId: rule.id) }
                continue
            }

            remainingSeconds[rule.id] = remaining
            start(ruleId: rule.id, expiresAt: expiresAt)
        }
    }

    /// Returns the formatted "m:ss" string for a rule's remaining countdown, or nil if not ticking.
    func countdownDisplay(for ruleId: UUID) -> String? {
        guard let seconds = remainingSeconds[ruleId] else { return nil }
        return UnblockCountdownCalculator.formatted(remaining: TimeInterval(seconds))
    }

    func stop(ruleId: UUID) {
        timers[ruleId]?.cancel()
        timers.removeValue(forKey: ruleId)
        remainingSeconds.removeValue(forKey: ruleId)
    }

    func stopAll() {
        timers.values.forEach { $0.cancel() }
        timers.removeAll()
        remainingSeconds.removeAll()
    }

    private func start(ruleId: UUID, expiresAt: Date) {
        timers[ruleId]?.cancel()
        timers[ruleId] = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let remaining = Int(UnblockCountdownCalculator.remaining(expiresAt: expiresAt))
                if remaining <= 0 {
                    self.stop(ruleId: ruleId)
                    Task { await self.screenTimeRulesService.reblockIfExpired(ruleId: ruleId) }
                } else {
                    self.remainingSeconds[ruleId] = remaining
                }
            }
    }
}
