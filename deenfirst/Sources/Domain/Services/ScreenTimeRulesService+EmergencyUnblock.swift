import Foundation
import UserNotifications

// MARK: - Emergency Unblock Extension

extension ScreenTimeRulesServiceImpl {

    // MARK: - Activate

    func activateEmergencyUnblock() async {
        let defaults = AppGroupConstants.sharedDefaults

        // Increment used count (with weekly reset)
        let _ = emergencyUnblockQuotaRemaining() // triggers reset if new week

        let usedCount = defaults?.integer(forKey: AppGroupConstants.emergencyUnblockUsedCountKey) ?? 0
        defaults?.set(usedCount + 1, forKey: AppGroupConstants.emergencyUnblockUsedCountKey)

        // Store midnight as expiry
        let midnight = nextMidnight()
        defaults?.set(midnight.timeIntervalSince1970, forKey: AppGroupConstants.emergencyUnblockExpiryKey)
        defaults?.synchronize()

        // Remove all shields
        await deviceActivityManager.removeShield()

        // Schedule notification at midnight
        scheduleEmergencyReblockNotification(at: midnight)

        // Dashboard: weekly emergency unblock counter.
        dashboardDataWriter?.recordEmergencyUnblock()

        print("✅ [EmergencyUnblock] Activated — all shields removed until \(midnight)")
    }

    // MARK: - Deactivate

    func deactivateEmergencyUnblock() async {
        let defaults = AppGroupConstants.sharedDefaults
        defaults?.removeObject(forKey: AppGroupConstants.emergencyUnblockExpiryKey)
        defaults?.synchronize()

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [AppGroupConstants.emergencyReblockNotificationId]
        )

        await reapplyActiveShields()
        print("✅ [EmergencyUnblock] Deactivated — shields restored")
    }

    // MARK: - Reblock if Expired (foreground check)

    func reblockEmergencyIfExpired() async {
        guard isEmergencyUnblockActive == false else { return }

        let defaults = AppGroupConstants.sharedDefaults
        let expiry = defaults?.double(forKey: AppGroupConstants.emergencyUnblockExpiryKey) ?? 0
        guard expiry > 0 else { return }

        // Expiry exists but is in the past — clean up and reapply
        defaults?.removeObject(forKey: AppGroupConstants.emergencyUnblockExpiryKey)
        defaults?.synchronize()

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [AppGroupConstants.emergencyReblockNotificationId]
        )

        await reapplyActiveShields()
        print("✅ [EmergencyUnblock] Expired — shields reapplied")
    }

    // MARK: - State Queries

    var isEmergencyUnblockActive: Bool {
        let expiry = AppGroupConstants.sharedDefaults?.double(
            forKey: AppGroupConstants.emergencyUnblockExpiryKey
        ) ?? 0
        guard expiry > 0 else { return false }
        return Date().timeIntervalSince1970 < expiry
    }

    func emergencyUnblockQuotaRemaining() -> Int {
        let defaults = AppGroupConstants.sharedDefaults
        let storedWeek = defaults?.string(forKey: AppGroupConstants.emergencyUnblockWeekStartKey) ?? ""
        let currentWeek = currentWeekMondayString()

        if storedWeek != currentWeek {
            defaults?.set(0, forKey: AppGroupConstants.emergencyUnblockUsedCountKey)
            defaults?.set(currentWeek, forKey: AppGroupConstants.emergencyUnblockWeekStartKey)
            defaults?.synchronize()
        }

        let used = defaults?.integer(forKey: AppGroupConstants.emergencyUnblockUsedCountKey) ?? 0
        return max(0, 2 - used)
    }

    // MARK: - Private Helpers

    private func nextMidnight() -> Date {
        let calendar = Calendar.current
        return calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86400)
    }

    private func currentWeekMondayString() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        let monday = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: monday)
    }

    private func scheduleEmergencyReblockNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [AppGroupConstants.emergencyReblockNotificationId]
        )

        let content = UNMutableNotificationContent()
        content.title = "Deen First"
        content.body = "⏰ Emergency unblock expired — apps are blocked again"
        content.sound = .default

        let delay = date.timeIntervalSinceNow
        guard delay > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: AppGroupConstants.emergencyReblockNotificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("⚠️ [EmergencyUnblock] Failed to schedule notification: \(error)")
            } else {
                print("✅ [EmergencyUnblock] Reblock notification scheduled in \(Int(delay))s")
            }
        }
    }
}
