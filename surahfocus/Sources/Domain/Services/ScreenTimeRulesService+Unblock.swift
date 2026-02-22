import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

// MARK: - Temporary Unblock Extension

extension ScreenTimeRulesServiceImpl {

    // MARK: - Temporary Unblock

    func temporaryUnblock(minutes: Int) async {
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)

        let expiry = Date().addingTimeInterval(Double(minutes) * 60)
        defaults?.set(expiry.timeIntervalSince1970, forKey: AppGroupConstants.unblockExpiryKey)
        defaults?.synchronize()

        await removeSessionShield()
        print("✅ [Unblock] Shields removed for \(minutes) minutes")

        Task {
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)

            let storedExpiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey) ?? 0
            let now = Date().timeIntervalSince1970
            if now >= storedExpiry {
                await self.reblockIfExpired()
            }
        }
    }

    // MARK: - Re-block

    func reblockIfExpired() async {
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        let expiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey) ?? 0

        guard expiry > 0 else { return }

        if Date().timeIntervalSince1970 >= expiry {
            defaults?.removeObject(forKey: AppGroupConstants.unblockExpiryKey)
            defaults?.synchronize()

            await reapplyActiveShields()
            print("✅ [Unblock] Re-block applied after expiry")
        }
    }

    // MARK: - Check Unblock Status

    var isTemporarilyUnblocked: Bool {
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        let expiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey) ?? 0
        guard expiry > 0 else { return false }
        return Date().timeIntervalSince1970 < expiry
    }

    var unblockRemainingMinutes: Int? {
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        let expiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey) ?? 0
        guard expiry > 0 else { return nil }
        let remaining = expiry - Date().timeIntervalSince1970
        guard remaining > 0 else { return nil }
        return Int(ceil(remaining / 60))
    }
}
