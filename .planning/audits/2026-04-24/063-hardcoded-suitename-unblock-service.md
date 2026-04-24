---
id: 063
title: Hardcoded UserDefaults suiteName in ScreenTimeRulesService+Unblock
severity: P3
area: arch
status: open
---

## Problem

`ScreenTimeRulesService+Unblock.swift` calls `UserDefaults(suiteName: AppGroupConstants.suiteName)` directly in four places instead of using the canonical `AppGroupConstants.sharedDefaults` accessor. While the string value is correctly pulled from `AppGroupConstants.suiteName`, the CLAUDE.md and project rules require using `AppGroupConstants.sharedDefaults` consistently to avoid any future inconsistency and to keep a single point of truth.

More critically: if `AppGroupConstants.sharedDefaults` returns `nil` (misconfiguration), the code silently falls back to zero via `?? 0` — a P0 misconfiguration goes undetected. The rest of the codebase uses `AppGroupConstants.sharedDefaults`.

## Evidence

`ScreenTimeRulesService+Unblock.swift`:
- Line 17: `let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)`
- Line 146: `let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)`
- Line 185: `let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)`
- Line 192: `let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)`

## Solution

Replace all 4 occurrences with:
```swift
let defaults = AppGroupConstants.sharedDefaults
```
No behavior change — same suite name — but now consistent with every other call site.

## Why

The project rule is "cross-process data via `AppGroupConstants` — never hardcode keys inline." Using the accessor (not the raw initializer) ensures nil detection is consistent, and a single refactor of `AppGroupConstants` propagates everywhere.
