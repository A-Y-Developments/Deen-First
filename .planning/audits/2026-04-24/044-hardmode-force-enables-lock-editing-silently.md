---
id: 044
title: Hard Mode save silently force-enables Lock Editing with no user confirmation
severity: P1
area: lock-editing
status: open
---

## Problem

`AppLimitConfig` and `TimeLimitConfig` override `isLockEditingEnabled = true` whenever `isHardMode` is true at save time. The UI exposes separate toggles for Hard Mode and Lock Editing. A user who has Hard Mode enabled but Lock Editing disabled will silently have Lock Editing activated on the next save — without any alert, sheet, or confirmation.

## Evidence

`Domain/Entities/AppLimitConfig.swift` line 36:
```swift
isLockEditingEnabled = isHardMode ? true : isLockEditingEnabled
```

`Domain/Entities/TimeLimitConfig.swift` line 55 (same pattern).

`AppLimitViewModel` line 242 and `TimeLimitViewModel` line 305 show `showLockEditingEnabledConfirmation` is set and presented at `AppLimitView:63` and `TimeLimitView:65` — but this confirmation is for *disabling* Lock Editing, not for the silent *enabling* that happens here.

## Solution

Two options:

**Option A (simpler):** Remove the Lock Editing force-enable in config. Instead, enforce the rule in the ViewModel: when the user enables Hard Mode, immediately show the same confirmation sheet explaining Lock Editing will also be enabled, requiring explicit consent.

**Option B (architectural):** Keep the force-coupling in config but add a ViewModel guard that detects when `isHardMode` changed from false→true and `isLockEditingEnabled` would change from false→true, and shows a confirmation before saving.

Option A is cleaner: the confirmation sheet for enabling Lock Editing alongside Hard Mode mirrors the existing sheet for disabling it.

## Why

Silent state mutations that lock the user out of editing their own rules violate the principle of least surprise — especially when there is already a confirmation pattern (the disable sheet) demonstrating the team knows this needs user acknowledgment.
