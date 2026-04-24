---
id: 115
title: Tier 3 duration logic duplicated in ActiveSessionViewModel
severity: P2
area: code-quality
status: open
---

## Problem

`ActiveSessionViewModel` line 104 hardcodes:
```swift
let minutes = rule.isHardMode ? 20 : 15
```

The canonical source of truth for Tier 3 duration is `UnblockTier.minutes(isHardMode:)` defined in `UnblockDurationSelectionViewModel.swift`:
```swift
case .tier3: return isHardMode ? 20 : 15
```

If the product changes Tier 3 duration (e.g., Hard Mode becomes 25 min), only one site would be updated and the other would silently diverge.

## Evidence

`deenfirst/Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:104`
`deenfirst/Sources/Presentation/UnblockDurationSelection/UnblockDurationSelectionViewModel.swift:18`

## Solution

Move `UnblockTier` enum to its own file in `Domain/` (not in a ViewModel file). Both `ActiveSessionViewModel` and `UnblockDurationSelectionViewModel` import and use it. Then:

```swift
// ActiveSessionViewModel.swift
let minutes = UnblockTier.tier3.minutes(isHardMode: rule.isHardMode)
```

## Why

Business rules (tier durations) belong in the domain layer, not scattered across ViewModel files. A ViewModel file is not a good home for a shared enum — it creates an implicit dependency between two presentation-layer files that should be independent.
