import Foundation

/// Pure helper for the tiered-unblock countdown shared between Home and Blocking tabs.
/// No dependencies on SwiftData or network — safe for extension targets.
enum UnblockCountdownCalculator {

    /// Seconds remaining until `expiresAt`, floored at 0.
    static func remaining(expiresAt: Date, now: Date = Date()) -> TimeInterval {
        max(0, expiresAt.timeIntervalSince(now))
    }

    /// Formats a `TimeInterval` (seconds) as `m:ss`. Returns `nil` for expired / zero.
    static func formatted(remaining: TimeInterval) -> String? {
        guard remaining > 0 else { return nil }
        let total = Int(remaining)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
