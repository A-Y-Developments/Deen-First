---
id: 110
title: Streak incremented on unblock sessions
severity: P1
area: v1-regression
status: open
---

## Problem

`SessionService.startSession()` unconditionally calls `updateStreak(for: user.id)` at line 123, before the caller ever has a chance to set `isUnblockSession`. In `ActiveSessionViewModel.startSession()` (lines 119-125), `isUnblockSession = true` and `unlockRuleId` are assigned on the returned session object **after** `sessionService.startSession()` returns. The streak has already been bumped by the time the unblock context is established.

A user who taps "Recite to Unblock" and completes a Tier 3 session will have their daily streak updated as if they completed a voluntary Quran session.

## Evidence

`deenfirst/Sources/Domain/Services/SessionService.swift:123`
```swift
try await updateStreak(for: user.id)   // always fires
```

`deenfirst/Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:119-125`
```swift
let session = try await sessionService.startSession(...)
// streak already updated above ↑
session.isUnblockSession = true
session.unlockRuleId = targetRuleId
```

Reproduction: trigger a Tier 3 unblock session from the BlockingTab; check `User.currentStreak` before and after — it increments even with no voluntary prayer intent.

## Solution

Pass unblock context into `startSession()` so the service can skip the streak bump:

```swift
func startSession(
    surahIds: [Int],
    ayahIds: [Int],
    duration: Int,
    isUnblockSession: Bool = false,
    unlockRuleId: UUID? = nil
) async throws -> Session {
    // ...
    if !isUnblockSession {
        try await updateStreak(for: user.id)
    }
}
```

Remove the post-hoc assignment in `ActiveSessionViewModel`.

## Why

Streak is a V1 metric that signals consistent voluntary Quran engagement. Unblock sessions are a friction mechanism, not a prayer habit. Crediting the streak for unblock sessions inflates the score artificially and undermines the metric's meaning. The root cause is the temporal gap between the service call and the caller's assignment of unblock context — the fix eliminates that gap by making the flag a first-class parameter.
