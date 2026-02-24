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

        // Remove all shields immediately
        await deviceActivityManager.removeShield()

        // Schedule a DeviceActivity that ends exactly at the expiry time.
        // When intervalDidEnd fires in DeviceActivityMonitorExtension, it detects
        // the tempUnblock_ prefix and re-applies all shields.
        //
        // This is the ONLY reliable background re-block mechanism — Task.sleep and
        // Timer are both suspended when the app is backgrounded by iOS.
        await scheduleReblockActivity(expiry: expiry)

        print("✅ [Unblock] All shields removed for \(minutes) minutes, expiry: \(expiry)")
    }

    // MARK: - Schedule Reblock via DeviceActivity

    private func scheduleReblockActivity(expiry: Date) async {
        let calendar = Calendar.current

        // Stop any existing tempUnblock schedule first (user may have re-unblocked)
        let activityName = DeviceActivityName(
            AppGroupConstants.tempUnblockActivityPrefix + "main"
        )
        try? await deviceActivityManager.stopMonitoring(names: [activityName])

        // Build a schedule that starts now and ends at the expiry timestamp.
        // When intervalDidEnd fires, the extension re-applies shields.
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: expiry)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try await deviceActivityManager.startMonitoring(
                name: activityName,
                schedule: schedule,
                events: [:]  // No threshold events — we only need intervalDidEnd
            )
            print("✅ [Unblock] Scheduled reblock activity ending at \(expiry)")
        } catch {
            print("⚠️ [Unblock] Failed to schedule reblock activity: \(error)")
            // Non-fatal — foreground timer in BlockingTabViewModel is backup
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

            // Stop the DeviceActivity schedule — already fired or user manually triggered
            let activityName = DeviceActivityName(
                AppGroupConstants.tempUnblockActivityPrefix + "main"
            )
            try? await deviceActivityManager.stopMonitoring(names: [activityName])

            await reapplyActiveShields()
            print("✅ [Unblock] Re-block applied, shields restored to rule-based state")
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