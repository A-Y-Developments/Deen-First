---
id: 052
title: Pool-empty nudge fires in Normal Mode when pool is intentionally empty
severity: P1
area: ayah-pool
status: open
---

## Problem

`ReciteToUnblockViewModel.resolveEligiblePool()` calls `maybeShowPoolNudge()` whenever the eligible set is empty, regardless of mode. In Normal Mode, an empty pool is the default state (the pool is optional — the system falls back to standard ayah selection). Users who have never configured a pool will see a nudge to add ayahs to their pool on every Normal Mode recitation attempt, which is incorrect behavior and a false UX alarm.

## Evidence

`Presentation/ReciteToUnblock/ReciteToUnblockViewModel.swift` lines 207-214 (approx):
```swift
func resolveEligiblePool() -> [AyahPoolItem] {
    let eligible = pool.filter { ... }
    if eligible.isEmpty {
        maybeShowPoolNudge()  // fires in any mode
    }
    return eligible
}
```

The code comment at line ~78 says "Hard Mode active AND empty" as the nudge trigger condition, but the implementation does not gate on mode.

## Solution

Gate the nudge on Hard Mode being active:
```swift
if eligible.isEmpty && rule.isHardMode {
    maybeShowPoolNudge()
}
```

In Normal Mode with an empty pool, the system should silently fall back to standard ayah selection (already implemented) without surfacing any nudge.

## Why

The pool is optional in Normal Mode by design (domain.md: "Normal Mode: pool is optional; system uses standard ayah selection if pool empty"). Nudging users who never intended to use a pool is misleading and degrades the Normal Mode recitation UX.
