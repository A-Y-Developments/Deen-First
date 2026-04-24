---
id: 073
title: UnblockDurationSelectionView shows all 3 tiers always — no progressive unlock gate
severity: P1
area: unblock
status: open
---

## Problem

The domain rule (domain.md) states: "Tiers unlock progressively: must complete lower tier to access higher." `UnblockDurationSelectionView.swift` renders all 3 `TierCardView` cards unconditionally with no disabled state, lock icon, or conditional rendering based on whether lower tiers have been completed. A user can tap Tier 2 or Tier 3 without having ever completed Tier 1.

## Evidence

`UnblockDurationSelectionView.swift:50-67` — all three tiers rendered unconditionally:
```swift
TierCardView(tier: .tier1, ...)
TierCardView(tier: .tier2, ...)
TierCardView(tier: .tier3, ...)
```

No call to check tier completion history. `UnblockDurationSelectionViewModel` only loads `ruleName` and `isHardMode` — no tier state.

Domain rule: "Tiers unlock progressively: must complete lower tier to access higher."

## Solution

1. Add tier completion tracking to `ScreenTimeRulesService` or a new `UnblockTierTracker` service that persists completed tiers per-rule per-session in App Group.
2. `UnblockDurationSelectionViewModel` loads tier availability: `isTier2Available`, `isTier3Available`.
3. `TierCardView` receives an `isLocked: Bool` parameter — locked tiers show a lock icon and are non-interactive.

## Why

The progressive unlock mechanic is a core V2 design principle (accountability friction). Allowing users to skip directly to Tier 3 (longest unblock) undermines the entire feature. This is a functional bug, not just a UI issue.
