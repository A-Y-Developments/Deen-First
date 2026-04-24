import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

// MARK: - Per-Rule Temporary Unblock Extension

extension ScreenTimeRulesServiceImpl {

    // MARK: - Per-Rule Unblock

    /// Temporarily unblocks only the apps belonging to the specified rule.
    /// Other rules remain fully blocked and unaffected.
    /// Implements "longer wins": if an active unblock with more time remaining exists, keeps it.
    func temporaryUnblock(minutes: Int, ruleId: UUID) async {
        let defaults = AppGroupConstants.sharedDefaults
        let now = Date()
        let newExpiry = now.addingTimeInterval(Double(minutes) * 60)

        // Longer-wins guard: do not replace an active unblock that has more time remaining
        let existingExpiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey(for: ruleId)) ?? 0
        let isActiveUnblock = existingExpiry > now.timeIntervalSince1970
        if isActiveUnblock && existingExpiry > newExpiry.timeIntervalSince1970 {
            notifyShorterDurationIgnored(ruleId: ruleId)
            print("⏭️ [Unblock] Longer-wins: existing expiry has more time remaining — skipping replacement for rule \(ruleId)")
            return
        }

        defaults?.set(newExpiry.timeIntervalSince1970, forKey: AppGroupConstants.unblockExpiryKey(for: ruleId))
        defaults?.synchronize()

        // Remove shields for THIS rule's tokens only — other rules stay blocked
        if let rule = repository.getRule(id: ruleId) {
            let selection = rule.getFamilyActivitySelection()
            await deviceActivityManager.removeShield(for: selection)
        }

        // PRIMARY: DeviceActivity background re-block (best effort for short windows)
        await scheduleReblockActivity(expiry: newExpiry, ruleId: ruleId)

        // FALLBACK: Local notification fires reliably even if app is killed.
        // User taps → app foregrounds → willEnterForeground → reblockAllExpired() runs.
        scheduleReblockNotification(expiry: newExpiry, ruleId: ruleId, minutes: minutes)

        print("✅ [Unblock] Rule \(ruleId) shields removed for \(minutes) minutes, expiry: \(newExpiry)")
    }

    // MARK: - Global Fallback (Shield flow — no specific rule context)

    /// Called when the user recites from the Shield screen (no specific ruleId is known).
    /// Unblocks all currently blocking rules simultaneously, each with its own timer.
    func temporaryUnblockAll(minutes: Int) async {
        let blockingRules = getAllRules().filter { isRuleCurrentlyBlocking($0) }
        for rule in blockingRules {
            await temporaryUnblock(minutes: minutes, ruleId: rule.id)
        }
        print("✅ [Unblock] Global unblock — \(blockingRules.count) rule(s) unblocked for \(minutes) minutes")
    }

    // MARK: - Schedule Reblock via DeviceActivity (per-rule)

    private func scheduleReblockActivity(expiry: Date, ruleId: UUID) async {
        let calendar = Calendar.current
        let activityName = DeviceActivityName(AppGroupConstants.tempUnblockActivityPrefix + ruleId.uuidString)

        // Stop any existing schedule for this rule (user may have re-unblocked)
        try? await deviceActivityManager.stopMonitoring(names: [activityName])

        // Mirror the pattern used by createDailySchedule:
        // — Explicit DateComponents with only hour + minute (no .second)
        // — intervalStart = midnight (00:00) gives a multi-hour interval, avoiding
        //   Apple's `intervalTooShort` rejection.
        // — intervalDidEnd fires at the exact expiry hour:minute.
        let expiryComps = calendar.dateComponents([.hour, .minute], from: expiry)
        let expiryTotalMinutes = (expiryComps.hour ?? 0) * 60 + (expiryComps.minute ?? 0)

        // Edge case: expiry within the first hour after midnight (e.g. 00:03 -> 00:08).
        // Interval from 00:00 to 00:08 is only 8 min — still hits intervalTooShort.
        // DeviceActivitySchedule cannot reference yesterday, so skip DA here and
        // rely on the local notification fallback which handles this perfectly.
        guard expiryTotalMinutes >= 60 else {
            print("⏭️ [Unblock] Expiry within first hour of midnight — skipping DeviceActivity, notification fallback active")
            return
        }

        let startComponents = DateComponents(hour: 0, minute: 0)
        let endComponents   = DateComponents(hour: expiryComps.hour ?? 0, minute: expiryComps.minute ?? 0)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try await deviceActivityManager.startMonitoring(
                name: activityName,
                schedule: schedule,
                events: [:]
            )
            print("✅ [Unblock] Scheduled reblock activity for rule \(ruleId) ending at \(expiry)")
        } catch {
            print("⚠️ [Unblock] Failed to schedule reblock activity for rule \(ruleId): \(error)")
            // Non-fatal — local notification is the reliable fallback
        }
    }

    // MARK: - Schedule Reblock Notification (per-rule fallback)

    private func scheduleReblockNotification(expiry: Date, ruleId: UUID, minutes: Int) {
        let center = UNUserNotificationCenter.current()
        let notificationId = AppGroupConstants.reblockNotificationId(for: ruleId)

        // Cancel any previous notification for this rule (user may have re-unblocked)
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let content = UNMutableNotificationContent()
        content.title = "Deen First"
        content.body = "⏰ Your apps are blocked again"
        content.sound = .default

        let delay = expiry.timeIntervalSinceNow
        guard delay > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("⚠️ [Unblock] Failed to schedule reblock notification for rule \(ruleId): \(error)")
            } else {
                print("✅ [Unblock] Reblock notification scheduled for rule \(ruleId) in \(Int(delay))s")
            }
        }
    }

    // MARK: - Re-block (per-rule)

    /// Checks if a specific rule's unblock period has expired and re-applies its shields.
    func reblockIfExpired(ruleId: UUID) async {
        let defaults = AppGroupConstants.sharedDefaults
        let key = AppGroupConstants.unblockExpiryKey(for: ruleId)
        let expiry = defaults?.double(forKey: key) ?? 0

        guard expiry > 0 else { return }
        guard Date().timeIntervalSince1970 >= expiry else { return }

        // Clear this rule's expiry
        defaults?.removeObject(forKey: key)
        defaults?.synchronize()

        // Stop the DeviceActivity schedule for this rule
        let activityName = DeviceActivityName(AppGroupConstants.tempUnblockActivityPrefix + ruleId.uuidString)
        try? await deviceActivityManager.stopMonitoring(names: [activityName])

        // Cancel the notification — re-block already happened, no need to show it
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [AppGroupConstants.reblockNotificationId(for: ruleId)]
        )

        // Reapply full shield state — this correctly handles the union of all active rules
        await reapplyActiveShields()
        print("✅ [Unblock] Re-block applied for rule \(ruleId), shields restored")
    }

    // MARK: - Re-block All Expired (called on foreground)

    /// Iterates all known rules and re-blocks any whose unblock timer has expired.
    /// Called from RootView.willEnterForeground so coming back to the app always catches up.
    func reblockAllExpired() async {
        let allRules = getAllRules()
        for rule in allRules {
            await reblockIfExpired(ruleId: rule.id)
        }
    }

    // MARK: - Check Unblock Status (per-rule)

    func isTemporarilyUnblocked(ruleId: UUID) -> Bool {
        let defaults = AppGroupConstants.sharedDefaults
        let expiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey(for: ruleId)) ?? 0
        guard expiry > 0 else { return false }
        return Date().timeIntervalSince1970 < expiry
    }

    func unblockRemainingSeconds(ruleId: UUID) -> Int? {
        let defaults = AppGroupConstants.sharedDefaults
        let expiry = defaults?.double(forKey: AppGroupConstants.unblockExpiryKey(for: ruleId)) ?? 0
        guard expiry > 0 else { return nil }
        let remaining = expiry - Date().timeIntervalSince1970
        guard remaining > 0 else { return nil }
        return Int(ceil(remaining))
    }

    // MARK: - Private Helpers

    /// Fires an immediate local notification informing the user their current unblock has more time remaining.
    private func notifyShorterDurationIgnored(ruleId: UUID) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Deen First"
        content.body = "Your current unblock has more time remaining"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: AppGroupConstants.shorterDurationIgnoredNotificationId(for: ruleId),
            content: content,
            trigger: nil // nil trigger fires immediately
        )

        center.add(request) { error in
            if let error {
                print("⚠️ [Unblock] Failed to notify shorter-duration ignored for rule \(ruleId): \(error)")
            }
        }
    }

    private func isRuleCurrentlyBlocking(_ rule: ScreenTimeRule) -> Bool {
        guard DayHelper.isActiveToday(daysActive: rule.daysActive) else { return false }
        switch rule.type {
        case .appLimit:
            return ScreenTimeEvents.getTriggeredRuleIds().contains(rule.id.uuidString)
        case .timeLimit:
            return rule.isCurrentlyInBlockingPeriod
        }
    }
}