---
id: 023
title: Max-3-tiers-per-blocking-session rule not implemented
severity: P1
area: unblock
status: open
---

## Problem

The domain spec (`domain.md`) states: "3 tiers max per blocking session." There is no tracking of how many tier attempts have been made per session, and no code that refuses a fourth attempt. A user can repeat Tier 1 (5 min) indefinitely with no upper bound on total unblock time per blocking session.

## Evidence

`ScreenTimeRulesService+Unblock.swift` — `temporaryUnblock(minutes:ruleId:)` only enforces the longer-wins guard (skip if remaining time already > new grant). No attempt counter:

```swift
func temporaryUnblock(minutes: Int, ruleId: UUID) async {
    let expiryKey = AppGroupConstants.unblockExpiryKey(for: ruleId)
    let existingExpiry = sharedDefaults.double(forKey: expiryKey)
    // longer-wins guard only
    if existingExpiry > Date().timeIntervalSince1970 + Double(minutes * 60) { return }
    // ... grants unblock without checking attempt count
}
```

`ReciteToUnblockViewModel.swift` — no `attemptCount` or session-level tier tracking field.

`AppGroupConstants.swift` — no key defined for per-session tier attempt tracking.

## Solution

1. Define `AppGroupConstants.tierAttemptCountKey(for ruleId: UUID) -> String` and `AppGroupConstants.tierAttemptResetDateKey(for ruleId: UUID) -> String`.
2. In `temporaryUnblock()`, read and increment the attempt counter. If `count >= 3`, return without granting.
3. Reset the counter when the blocking rule is reapplied (rule reblock event) or at the start of a new calendar day.
4. Surface a "max unblocks reached" message in `ReciteToUnblockView` if the ViewModel detects the cap before starting.

## Why

Without the cap, the tiered system provides unlimited unblocks via repeated Tier 1 completions — defeating the accountability purpose entirely.
