---
id: 033
title: Tier 3 unblock sessions counted as Quran focus sessions in Deen Score
severity: P2
area: dashboard
status: closed
---

## Problem

`SessionService.endSession()` calls `dashboardDataWriter?.recordFocusSession(duration:)` for all `.listening` session types regardless of `isUnblockSession`. Tier 3 unblock sessions (forced listening to earn an unblock) are consequently credited as voluntary Quran focus sessions in the Deen Score, inflating the score. Whether this is intentional is undocumented, but it undermines the accountability signal the Deen Score is meant to provide.

## Evidence

`SessionService.swift` lines ~142–144:

```swift
func endSession(_ session: Session, durationSeconds: Int) async throws {
    // ...
    if session.type == .listening {
        dashboardDataWriter?.recordFocusSession(duration: durationSeconds)
        // no check on session.isUnblockSession
    }
}
```

`DashboardDataWriter.recordFocusSession()` increments a UserDefaults counter used by `DeenScoreCalculator` as a positive contributor.

A user who repeatedly uses Tier 3 to unblock apps could maintain a high Deen Score without voluntary Quran engagement.

## Solution

Two valid design choices — pick one and document it:

**Option A (recommended):** Separate the metrics. Only call `recordFocusSession` when `!session.isUnblockSession`:
```swift
if session.type == .listening && !session.isUnblockSession {
    dashboardDataWriter?.recordFocusSession(duration: durationSeconds)
}
```
Add a separate `recordUnblockSession(duration:)` method to `DashboardDataWriter` that contributes less weight or a separate metric.

**Option B (permissive):** Document the decision in `domain.md` that Tier 3 sessions count as focus sessions — their Quran listening is genuine regardless of motivation. No code change needed.

## Why

The Deen Score's purpose is to reflect genuine Islamic productivity engagement. Coerced listening (to unlock apps) and voluntary listening carry different signal values. Without a deliberate design decision, the score degrades as a metric.
