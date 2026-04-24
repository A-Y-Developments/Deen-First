---
id: 070
title: RootView foreground handler omits DashboardDataWriter.flush() in async block
severity: P2
area: dashboard
status: closed
---

## Problem

`RootView.swift:107-119` — the `willEnterForeground` notification handler calls `DIContainer.shared.dashboardDataWriter.flush()` synchronously before the `Task { }` block (line 110). This is correct. However, the `flush()` call sits outside the `Task {}` while other operations run inside it. If `flush()` needs to stamp the updated-at key AFTER pending changes are applied (`applyExpiredChanges()` at line 112), then the timestamp may be stale relative to any data written by `applyExpiredChanges()`.

The initial `.task` block (line 77) also correctly calls `flush()` first, then await pending changes — the same ordering concern applies there.

## Evidence

`RootView.swift:107-119`:
```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    DIContainer.shared.dashboardDataWriter.flush()   // ← synchronous, before async ops
    Task {
        await DIContainer.shared.pendingChangeService.applyExpiredChanges()
        // ... other ops that may write to App Group
    }
}
```

`DashboardDataWriter.flush()` only stamps `dataLastUpdatedAtKey` — it doesn't write streak or session data. So the stamp is written before pending changes execute, meaning the extension may see a "fresh" timestamp pointing to data from before this foreground cycle.

## Solution

Move `flush()` to the end of the `Task {}` block (after all writes complete), or call it after pending change application:
```swift
Task {
    await DIContainer.shared.pendingChangeService.applyExpiredChanges()
    // ... other ops
    DIContainer.shared.dashboardDataWriter.flush()  // stamp AFTER all writes
}
```

## Why

The `dataLastUpdatedAtKey` is used by `DeenFirstActivityReport` as a staleness signal. Stamping it before the async operations complete means the extension may render stale data with a fresh timestamp, hiding the staleness.
