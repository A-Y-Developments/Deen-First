---
id: 121
title: Blocking-tab rule card not refreshed when a pending change auto-applies on foreground
severity: P3
area: lock-editing
ticket: DF-22
status: open
---

## Problem

DF-22 acceptance criterion: "Applied changes reflected immediately in UI (rule card updates)."

When a `PendingRuleChange` crosses its 24h boundary and is auto-applied on app foreground, the Blocking tab does **not** refresh on that same foreground. A stale pending-change clock indicator (and, for a `.delete` change, the already-deleted rule's card) lingers until the next independent refresh trigger (tab re-appear, navigation, or a later foreground). The apply itself is correct — only the immediate UI reflection is missing.

## Evidence

- `PendingChangeService.applyExpiredChanges()` mutates the rule store but posts **no** `NotificationCenter` event and holds no reference to `BlockingTabViewModel` (only `UNUserNotificationCenter` local-push calls exist in the rules services).
- `BlockingTabViewModel` (`deenfirst/Sources/Presentation/MainTabs/BlockingTab/BlockingTabViewModel.swift:39-41`) subscribes its `objectWillChange` **only** to `countdownManager.objectWillChange`. Nothing fires when the pending store changes.
- `appLimits` / `timeLimits` are stale snapshots taken at the last `loadBlockedApps()` (lines 53-66); `hasPendingChange(for:)` (line 160) reads live but won't be re-evaluated without a re-render.
- On foreground, `applyExpiredChanges()` runs from `RootView` (`RootView.swift:127`) while `BlockingTabView` separately calls `refreshBlockingState()->loadBlockedApps()` (`BlockingTabView.swift:109-117`) in a parallel, unsequenced Task. `loadBlockedApps()` is fast and completes **before** the longer apply chain finishes, so it reads pre-apply state.

## Solution

Either:
1. Have `applyExpiredChanges()` post a `Notification` (e.g. `.pendingChangesApplied`) when it applies ≥1 change, and have `BlockingTabView` observe it to re-run `loadBlockedApps()`. (Touches `PendingChangeService` + `BlockingTabView`.)
2. Or sequence `loadBlockedApps()` *after* `applyExpiredChanges()` inside the foreground Task. **Caveat:** the natural place for this is `RootView.swift`, which is currently owned by other in-flight work — avoid editing it; prefer option 1.

Either fix touches lock-editing's apply path → confirm before applying.

## Why

P3: cosmetically stale, self-heals on the next refresh, and never causes a wrong unblock/lock state (the underlying store is correct). But it briefly contradicts the "reflected immediately" criterion and can confuse a user who watches a rule they expected to disappear.
