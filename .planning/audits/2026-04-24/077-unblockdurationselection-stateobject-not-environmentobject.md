---
id: 077
title: UnblockDurationSelectionView uses @StateObject for ViewModel — not consistent with other tab VMs
severity: P3
area: arch
status: open
---

## Problem

`UnblockDurationSelectionView.swift:9` uses `@StateObject private var viewModel = UnblockDurationSelectionViewModel()`. This is technically correct for a pushed navigation destination that owns its ViewModel. However, all other screen-level ViewModels in this project are hoisted to `RootView` as `@StateObject` and injected as `@EnvironmentObject`. The `UnblockDurationSelectionViewModel` is the only V2 ViewModel that follows a different pattern.

Practically: each time the user navigates to `UnblockDurationSelectionView` (from Home or Blocking), a new ViewModel is instantiated, `loadRule(ruleId:)` is called in `.onAppear`, and the ViewModel is destroyed on pop. This is correct behavior for this use case (stateless lookup of a rule by ID). The inconsistency is purely a pattern deviation.

## Evidence

`UnblockDurationSelectionView.swift:9`:
```swift
@StateObject private var viewModel = UnblockDurationSelectionViewModel()
```

Compare: `RootView.swift:20-26` — all other ViewModels are `@StateObject` at the root and `@EnvironmentObject` in children.

## Solution

Two options:
1. Accept local `@StateObject` for navigated destinations that are inherently stateless (no state that needs to survive back-navigation). Document the pattern exception.
2. Add `UnblockDurationSelectionViewModel` to `RootView` and inject via `@EnvironmentObject`.

Option 1 is recommended — this ViewModel has no persistent state worth preserving across navigations.

## Why

Pattern inconsistency is P3 — no functional impact. Documenting the intentional exception prevents future contributors from thinking it's an oversight.
