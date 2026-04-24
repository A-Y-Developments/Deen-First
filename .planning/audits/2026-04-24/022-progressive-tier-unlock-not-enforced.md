---
id: 022
title: Progressive tier unlock not enforced — all tiers always selectable
severity: P1
area: unblock
status: closed
---

## Problem

The PRD states tiers unlock progressively: user must complete a lower tier before accessing a higher one within a blocking session. Neither `UnblockDurationSelectionView` nor `UnblockDurationSheet` enforces this. All three tiers are always selectable regardless of session history.

## Evidence

`UnblockDurationSelectionView.swift` — all three `TierCardView` calls are rendered unconditionally with `isSelectable: true`:

```swift
TierCardView(tier: .tier1, isHardMode: vm.isHardMode, isSelectable: true) {
    selectTier(.tier1)
}
TierCardView(tier: .tier2, isHardMode: vm.isHardMode, isSelectable: true) {
    selectTier(.tier2)
}
TierCardView(tier: .tier3, isHardMode: vm.isHardMode, isSelectable: true) {
    selectTier(.tier3)
}
```

`UnblockDurationSheet.swift` — user can freely drag the wheel to any minute value; `closest(to:)` maps it to any tier without checking completion history.

No code anywhere in the codebase reads a "completedTiers" or "sessionTierHistory" value. `ScreenTimeRulesService+Unblock.swift` has no such tracking.

## Solution

1. Add a `completedTiersForSession: Set<UnblockTier>` tracking mechanism — either in `AppGroupConstants` UserDefaults (cross-process) or in-memory on `UnblockDurationSelectionViewModel` (per-launch).
2. In `UnblockDurationSelectionView`, pass `isSelectable: completedTiersForSession.contains(lowerTier)` for tier2 and tier3.
3. On successful unblock (in `ScreenTimeRulesService+Unblock.temporaryUnblock`), write the completed tier to the tracking store.
4. Reset tracking when the rule is reblocked or a new blocking session starts.

## Why

Without enforcement, a user can select Tier 3 on first attempt, bypassing the accountability friction that is the core V2 value proposition. The TierCard UI already has an `isSelectable` parameter — it just isn't being used to gate access.
