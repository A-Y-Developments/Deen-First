---
id: 055
title: Pending changes only apply on foreground — no BGTaskScheduler registration
severity: P2
area: lock-editing
status: closed
---

## Problem

`PendingChangeService.applyExpiredChanges()` is triggered only on app launch (`.task` in `RootView`) and on `UIApplication.willEnterForegroundNotification`. If a user does not open the app for 2+ days, expired pending changes accumulate and apply all at once the next time they foreground — which is technically correct but means a user who set a 24hr change, then forgot about the app for a week, gets all their queued changes applied simultaneously with no staggered notification.

More importantly, the scheduled `UNUserNotificationRequest` for "your change will apply in 24h" fires but the actual application has not happened yet if the user doesn't foreground. The notification is thus misleading.

## Evidence

`RootView.swift` line 79: `await DIContainer.shared.pendingChangeService.applyExpiredChanges()` — only on launch task.

`RootView.swift` line 112-113: same call in `willEnterForegroundNotification` handler.

No `BGTaskScheduler` registration found in `DIContainer`, `AppDelegate`, or `@main` entry point.

## Solution

Register a `BGAppRefreshTask` to call `applyExpiredChanges()` in the background. This ensures changes apply within minutes of their `appliesAt` timestamp even if the user doesn't foreground the app.

```swift
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.aydev.deenfirst.pendingApply",
    using: nil
) { task in
    Task {
        await DIContainer.shared.pendingChangeService.applyExpiredChanges()
        task.setTaskCompleted(success: true)
    }
}
```

Register in `Project.swift` info.plist with `BGTaskSchedulerPermittedIdentifiers`.

## Why

Without background execution, "your change applies in 24h" notifications are deceptive — the system only applies on next foreground, not at the stated time. A BGAppRefreshTask costs minimal battery and closes this gap.
