---
id: 032
title: UnblockTier enum defined in Presentation ViewModel file instead of Domain layer
severity: P2
area: arch
status: closed
---

## Problem

`UnblockTier` is a core domain enum (it governs unblock duration, ayah count, and Hard Mode behavior) but it is defined inside `UnblockDurationSelectionViewModel.swift` in the Presentation layer. Domain entities and enums must live in `Domain/` — not in ViewModel files.

## Evidence

`UnblockDurationSelectionViewModel.swift`:

```swift
// Defined at top of Presentation ViewModel file
enum UnblockTier {
    case tier1, tier2, tier3

    var minutes: Int { ... }
    func minutes(isHardMode: Bool) -> Int { ... }
    func ayahCount(isHardMode: Bool) -> Int { ... }
    static func closest(to minutes: Int) -> UnblockTier { ... }
}

@MainActor final class UnblockDurationSelectionViewModel: ObservableObject { ... }
```

`ReciteToUnblockViewModel.swift` references `UnblockTier` directly — it imports it from the same module but the type conceptually owns the unblock flow at the domain level. `domain.md` describes `UnblockTier` under "Key Enums" without specifying it should live in Presentation.

## Solution

Move `UnblockTier` to `Domain/Entities/UnblockTier.swift`. Keep all computed properties (`minutes`, `ayahCount`, `closest`) on the enum — they are pure domain logic.

Remove the local definition from `UnblockDurationSelectionViewModel.swift`.

## Why

Architecture rule: Presentation depends on Domain, never the reverse. When `ReciteToUnblockViewModel` (and potentially services) need to use `UnblockTier`, they must import from Domain. Placing a domain type in a Presentation file inverts the dependency and prevents Domain layer reuse without pulling in Presentation code.
