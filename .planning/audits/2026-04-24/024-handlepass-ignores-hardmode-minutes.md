---
id: 024
title: handlePass() uses tier.minutes instead of tier.minutes(isHardMode:) — Hard Mode grant wrong
severity: P1
area: hard-mode
status: closed
---

## Problem

`ReciteToUnblockViewModel.handlePass()` calls `temporaryUnblock(minutes: tier.minutes, ...)` where `tier.minutes` is a plain property that always returns the normal-mode value. In Hard Mode, Tier 3 should grant 20 minutes, not 15. This means completing a Hard Mode Tier 3 session grants the wrong unblock duration. The same plain `tier.minutes` is also used in the shorter-wins guard, so the guard threshold is also wrong in Hard Mode.

## Evidence

`ReciteToUnblockViewModel.swift` — `handlePass()`:

```swift
// line ~544
let remainingExpiry = sharedDefaults.double(forKey: expiryKey)
let newExpiry = Date().timeIntervalSince1970 + Double(tier.minutes * 60)
if remainingExpiry > newExpiry { return }   // shorter-wins guard uses tier.minutes

// line ~549
await screenTimeService.temporaryUnblock(minutes: tier.minutes, ruleId: ruleId)
// ^^^ tier.minutes returns 15 for tier3 regardless of isHardMode
```

`UnblockDurationSelectionViewModel.swift` — `minutes(isHardMode:)`:
```swift
func minutes(isHardMode: Bool) -> Int {
    switch self {
    case .tier3: return isHardMode ? 20 : 15
    default: return self.minutes  // tier1=5, tier2=10
    }
}
```

The `isHardMode`-aware method exists but is never called in `handlePass()`.

## Solution

Replace both uses of `tier.minutes` in `handlePass()` with `tier.minutes(isHardMode: isHardMode)`:

```swift
let newExpiry = Date().timeIntervalSince1970 + Double(tier.minutes(isHardMode: isHardMode) * 60)
// ...
await screenTimeService.temporaryUnblock(minutes: tier.minutes(isHardMode: isHardMode), ruleId: ruleId)
```

## Why

Hard Mode Tier 3 grants an extra 5 minutes as a reward for higher difficulty. `tier.minutes` is a plain computed property that has no awareness of mode. The `isHardMode`-aware overload exists precisely for this purpose but was never connected to the actual unblock call.
