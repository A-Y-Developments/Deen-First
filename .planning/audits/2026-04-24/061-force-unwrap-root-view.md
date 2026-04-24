---
id: 061
title: Force unwrap on currentUser in RootView
severity: P1
area: arch
status: open
---

## Problem

`RootView.swift:40` force-unwraps `currentUser` after it has been nil-checked on line 38. While the guard-else on line 38 short-circuits the nil case, force unwrap is explicitly forbidden by CLAUDE.md rule 3 ("No force unwrap — ever").

## Evidence

`RootView.swift:38-41`:
```swift
} else if currentUser == nil {
    AuthView()
} else if !currentUser!.hasCompletedOnboarding {
```

The pattern is a structurally redundant force unwrap — `currentUser` is non-nil at that branch, but the compiler cannot guarantee it and the rule is absolute.

## Solution

Replace with `if let` or guard binding at the top of the `Group` body:
```swift
} else if let user = currentUser, !user.hasCompletedOnboarding {
```
Also update subsequent uses of `currentUser!` (line 133: `currentUser?.hasCompletedSetup`, already safe) and in `destinationView(for:)` line 194.

## Why

Force unwrap violates CLAUDE.md hard rule 3. If `currentUser` is ever set to nil on a background thread between the nil-check and the force unwrap (race condition), this will crash.
