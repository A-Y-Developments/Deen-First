---
id: 040
title: Clock-jump guard fires on overnight sleep, blocking legitimate applies
severity: P1
area: lock-editing
status: closed
---

## Problem

`PendingChangeService.applyExpiredChanges()` skips all pending changes when the elapsed time since `lastKnownDate` exceeds `clockJumpThreshold` (7200s = 2h). A device that sleeps overnight will have an elapsed gap of 8-28h, triggering this guard and silently skipping the apply — even though the 24hr delay has legitimately elapsed. The user wakes up, their rule change still hasn't applied, and there is no error surfaced.

## Evidence

`Domain/Services/PendingChangeService.swift` lines 78-89:
```swift
let elapsed = now.timeIntervalSince(lastKnown)
if elapsed > Self.clockJumpThreshold {
    logger.warning("Clock jump detected (\(elapsed)s). Skipping apply.")
    updateLastKnownDate(now)
    return
}
```
`clockJumpThreshold = 7200` (2h). Any overnight gap (8-28h) is treated as a clock manipulation.

`PendingChangeServiceTests.swift` tests a `8000s` jump (fires guard) and a `3600s` gap (passes). The legitimate overnight gap scenario (e.g. 28800s / 8h) is not tested.

## Solution

Change the guard to detect *backwards* jumps only (i.e., `now < lastKnownDate`), or use a much larger threshold (e.g., 48h). The actual clock-manipulation attack is moving time *forward* by exactly the right amount — but an attacker already bypasses this by just not opening the app. The 2h threshold creates more false positives (overnight sleep) than genuine catches.

```swift
// Replace threshold-based guard with direction-based guard:
if now < lastKnown {
    logger.warning("Clock rolled backward. Skipping apply.")
    return
}
```

If a directional guard feels too permissive, raise threshold to `172_800` (48h) — this still catches extreme jumps while not firing on overnight gaps.

## Why

The guard is designed to catch users manually advancing system clock to trigger early application. But a forward-jump guard using a 2h window is far too tight — overnight sleep trivially exceeds it. The attack model is defeated by the guard missing its window: an attacker advancing time by exactly 24h 1min still triggers the guard. The real defense is that apply only happens on foreground, so the attacker must open the app *after* the manipulation — but the guard would fire then too, preventing the legitimate apply for the actual user.
