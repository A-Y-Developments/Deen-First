---
id: 043
title: applyChange(.disableHardMode) only clears isHardMode, leaves isLockEditingEnabled true
severity: P1
area: lock-editing
status: superseded
superseded-by: ../2026-05-29/123-disable-hardmode-clears-lock-against-spec.md
---

> **SUPERSEDED 2026-05-29 — REVERTED.** This finding's "fix" (also clearing
> `isLockEditingEnabled` on `.disableHardMode`) was a symmetry/consistency guess
> that **contradicts the DF-16 product spec** ("Lock Editing does NOT turn off
> automatically when Hard Mode is turned off"). The Linear-conformance audit
> (2026-05-29) caught the conflict; per user decision the code was reverted so the
> lock persists. **Do not re-apply this finding.** See finding 123.

## Problem

When a pending change of type `.disableHardMode` applies, the service sets `isHardMode = false` but does NOT clear `isLockEditingEnabled`. Because `AppLimitConfig`/`TimeLimitConfig` force `isLockEditingEnabled = true` when Hard Mode is on at save time, a user turning off Hard Mode through the pending-change gate exits Hard Mode but remains locked — requiring a second 24hr pending change to disable Lock Editing. There is no UX disclosure of this.

## Evidence

`Domain/Services/PendingChangeService.swift` line 136 (approx):
```swift
case .disableHardMode:
    rule.isHardMode = false
    // isLockEditingEnabled is NOT touched
```

`Domain/Entities/AppLimitConfig.swift` line 36:
```swift
isLockEditingEnabled = isHardMode ? true : isLockEditingEnabled
```

This force-couple means enabling Hard Mode implicitly enables Lock Editing on save, but disabling Hard Mode does NOT implicitly disable Lock Editing.

`ScreenTimeRulesService+LockEditing.swift` `disableHardMode` (line 119): routes through pending-change gate if locked, but the apply only affects `isHardMode`.

## Solution

In `applyChange(.disableHardMode)`, also clear `isLockEditingEnabled`:
```swift
case .disableHardMode:
    rule.isHardMode = false
    rule.isLockEditingEnabled = false
```

Alternatively, treat "disable Hard Mode" as triggering two pending changes atomically: one for `.disableHardMode` and one for `.disableLockEditing`, both with the same `appliesAt`.

## Why

Hard Mode and Lock Editing are force-coupled on enable (via config) but decoupled on disable (via apply). This asymmetry means the user cannot exit the Hard Mode + Lock Editing combination with a single pending change despite entering it with a single toggle.
