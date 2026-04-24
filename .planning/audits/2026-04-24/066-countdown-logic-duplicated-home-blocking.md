---
id: 066
title: Countdown timer / unblock tracking logic duplicated across HomeTabViewModel and BlockingTabViewModel
severity: P2
area: code-quality
status: open
---

## Problem

`HomeTabViewModel.swift` and `BlockingTabViewModel.swift` both contain nearly identical countdown timer logic: `syncCountdownFromStorage()`, `startCountdownTimer(ruleId:expiry:)`, `stopCountdown(for:)`, and `countdownDisplay(for:)`. The same `AppGroupConstants.unblockExpiryKey` reads, `Timer.publish`, `AnyCancellable` tracking, and `reblockIfExpired` calls are copy-pasted. Any bug fix or behavior change must be applied in two places.

## Evidence

`HomeTabViewModel.swift:88-134` — `syncCountdownFromStorage`, `startCountdownTimer`, `stopCountdown`.
`BlockingTabViewModel.swift:89-115` — identical pattern with the same structure.

`HomeTabViewModel.swift:148-151`:
```swift
func countdownDisplay(for ruleId: UUID) -> String? {
    guard let seconds = unblockRemainingSeconds[ruleId] else { return nil }
    ...
}
```
Identical to `BlockingTabViewModel.swift:200-204`.

## Solution

Extract into a shared `UnblockCountdownManager` class (or a `struct` + `ObservableObject`) in `Domain/Services/` or a `Shared/` utility. Both ViewModels compose it:
```swift
private let countdownManager = UnblockCountdownManager(screenTimeRulesService: ...)
```
ViewModels delegate `syncCountdown`, `startTimer`, `stopTimer`, `countdownDisplay(for:)` calls to the manager.

## Why

DRY violation. Both ViewModels show active block cards — keeping countdown state in sync between them is fragile. A single source of truth eliminates the class of bugs where Home shows "2:30 remaining" but Blocking shows "expired."
