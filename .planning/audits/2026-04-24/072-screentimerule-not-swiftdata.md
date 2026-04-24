---
id: 072
title: ScreenTimeRule is a struct stored in UserDefaults — not a SwiftData @Model
severity: P2
area: arch
status: open
---

## Problem

`ScreenTimeRule.swift` defines `struct ScreenTimeRule: Codable, Identifiable, Hashable` — it is a value type serialized to `UserDefaults` via `ScreenTimeRulesRepository`. The domain rules file (`domain.md`) states ScreenTimeRule is a core entity and lists it as a `@Model`. It is NOT a SwiftData `@Model` and is not included in the `Schema` in `DIContainer.swift`. The V2 fields `isHardMode` and `isLockEditingEnabled` were added to this struct with a custom `Decodable` init (lines 104-120) to handle backward compatibility — but this is a JSON migration strategy, not SwiftData migration.

This is not a bug per se (it works correctly as a UserDefaults-backed struct), but it is a discrepancy between the domain.md specification and the actual implementation.

## Evidence

`domain.md`:
```
- `ScreenTimeRule` — ... **isHardMode** (V2), **isLockEditingEnabled** (V2)
```
(listed under "Core Entities (SwiftData @Model)")

`ScreenTimeRule.swift:42`:
```swift
struct ScreenTimeRule: Codable, Identifiable, Hashable {
```

`DIContainer.swift:94-99` — Schema does NOT include ScreenTimeRule:
```swift
let schema = Schema([
    User.self,
    Session.self,
    PendingRuleChange.self,
    AyahPoolItem.self,
])
```

## Solution

The current UserDefaults approach is intentional (ScreenTime rules need cross-process access without SwiftData). Update `domain.md` to accurately reflect that `ScreenTimeRule` is a `Codable struct` stored in UserDefaults App Group — not a SwiftData `@Model`. The distinction matters for future contributors.

## Why

The mismatch between specification and implementation creates false expectations. A developer reading `domain.md` would try to access ScreenTimeRule via a SwiftData context, which would fail. The documentation must match the implementation.
