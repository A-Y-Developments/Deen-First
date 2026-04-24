---
id: 035
title: isHardMode computed property re-fetches rule on every access — no mid-session caching
severity: P2
area: hard-mode
status: open
---

## Problem

`ReciteToUnblockViewModel.isHardMode` is a computed property that calls `screenTimeService.getRule(id: targetRuleId)` on every access. The `isHardMode` value is checked frequently during a session (threshold computation, ayah filtering, tier minute calculation). If a rule is edited mid-session (e.g., Hard Mode toggled off via another device or by Lock Editing applying a pending change), the threshold can change between ayah loads — creating inconsistent session behavior.

## Evidence

`ReciteToUnblockViewModel.swift` lines ~127–130:

```swift
var isHardMode: Bool {
    guard let ruleId = targetRuleId else { return false }
    return screenTimeService.getRule(id: ruleId)?.isHardMode ?? false
    // Called on: similarityThreshold, ayahCount, minutes, canRefreshAyah, etc.
}
```

Each call to `similarityThreshold`, `ayahCount`, or `tier.minutes(isHardMode:)` independently re-fetches from the service. If the rule changes between two accesses in the same `processRecitationOutcome()` call, the threshold used for evaluation and the threshold used for the unblock grant could differ.

## Solution

Snapshot `isHardMode` at session start into a stored property:

```swift
private(set) var isHardModeSession: Bool = false

func beginSession(ruleId: UUID) {
    targetRuleId = ruleId
    isHardModeSession = screenTimeService.getRule(id: ruleId)?.isHardMode ?? false
    // load ayah sequence using isHardModeSession
}
```

Replace all internal references to the computed `isHardMode` with `isHardModeSession`. Keep the computed property if external callers need the live value (e.g., the View binding), but don't use it internally during session logic.

## Why

Session rules should be stable for the duration of a recitation attempt. A mid-session Hard Mode toggle (even if rare) would cause `similarityThreshold` to change between recording start and scoring — the user could start recording at 85% threshold and be evaluated at 70%, or vice versa. Snapshotting at session start provides a stable, auditable contract.
