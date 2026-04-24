---
id: 021
title: Tier 3 selection via live UnblockDurationSheet immediately errors
severity: P0
area: unblock
status: open
---

## Problem

Via the live path (`UnblockDurationSheet` wheel picker), selecting 13–15 minutes triggers the Tier 3 code path in `ReciteToUnblockViewModel` with `ayahCount = 0`, which causes an immediate error state before the user sees any recitation UI. Tier 3 is completely broken on the live path.

## Evidence

`UnblockDurationSheet.swift` — on confirm:
```swift
let tier = UnblockTier.closest(to: selectedMinutes)
// selectedMinutes 13-15 → closest() returns .tier3
vm.tier = tier
router.path.append(.reciteToUnlock)
// navigates ReciteToUnblockView regardless of tier
```

`UnblockDurationSelectionViewModel.swift` — `ayahCount(isHardMode:)`:
```swift
func ayahCount(isHardMode: Bool) -> Int {
    switch self {
    case .tier1: return isHardMode ? 2 : 1
    case .tier2: return isHardMode ? 3 : 2
    default: return 0   // tier3 returns 0
    }
}
```

`ReciteToUnblockViewModel.loadAyahSequence(count:)` — when called with `count: 0`:
```swift
guard count > 0 else {
    state = .error("Could not load ayah...")
    return
}
```

Reproduction: Open app → BlockingTab → tap Unblock on any rule → drag wheel to 13 min → confirm → `ReciteToUnblockView` opens → immediately shows error state.

## Solution

Tier 3 must route to the focus/listening session flow (ActiveSessionView), not to ReciteToUnblockView. `UnblockDurationSheet.confirmSelection()` needs to branch:

```swift
if tier == .tier3 {
    router.path.append(.focusSection(unlockRuleId: ruleId))
} else {
    router.path.append(.reciteToUnlock)
}
```

This is exactly what `UnblockDurationSelectionView.selectTier()` already does correctly. Fixing finding 020 (wire the new picker) would fix this automatically.

## Why

`ReciteToUnblockViewModel` drives ayah recitation. Tier 3 is a full Quran listening session — it should never go through the recitation ViewModel. `ayahCount` returning 0 for tier3 is intentional (tier3 has no recitation), but `UnblockDurationSheet` doesn't gate on that, routing tier3 into recitation unconditionally.
