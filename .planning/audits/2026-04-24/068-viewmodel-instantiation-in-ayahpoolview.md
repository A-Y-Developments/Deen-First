---
id: 068
title: AyahPoolView instantiates AyahPoolViewModel directly instead of via environmentObject
severity: P2
area: arch
status: closed
---

## Problem

`AyahPoolView.swift:5` uses `@StateObject private var viewModel = AyahPoolViewModel()`. `AyahPoolViewModel.init()` calls `DIContainer.shared.ayahPoolService` with `MainActor.assumeIsolated` semantics implicitly via the default parameter `ayahPoolService ?? DIContainer.shared.ayahPoolService`. This pattern is acceptable when the default pulls from `DIContainer.shared`, but the `@StateObject` lifecycle in a pushed navigation destination means the ViewModel is recreated on every push — and not shared with its parent (`AyahPoolSurahPickerView`). This is functionally fine for now but deviates from the project pattern of lifting shared ViewModels to `RootView` as `@StateObject` + `@EnvironmentObject`.

Similarly, `AyahPoolSurahPickerView` creates its own `AyahPoolSurahPickerViewModel` with `@StateObject`. These ViewModels share `AyahPoolService` state but cannot share in-memory selection state unless routed through a common owner.

## Evidence

`AyahPoolView.swift:5`:
```swift
@StateObject private var viewModel = AyahPoolViewModel()
```

`AyahPoolSurahPickerView.swift` (not shown, but follows same pattern per file listing).

## Solution

If the pool state needs to persist across the Picker → Pool navigation round-trip, either:
1. Lift `AyahPoolViewModel` to a `@EnvironmentObject` injected from the route that opens AyahPool (e.g. Settings or Blocking tab).
2. Or accept local `@StateObject` and rely on `viewModel.load()` in `.onAppear` — which is what currently happens.

Option 2 is acceptable if `fetchPool()` is cheap (it is — in-memory SwiftData read). Document the decision. No crash risk; the issue is consistency with the project pattern.

## Why

CLAUDE.md rule 1 says services are accessed via DIContainer. The ViewModel default init accesses `DIContainer.shared` in its parameter default — that is compliant. The architectural inconsistency is that other features (Home, Quran, Blocking, Settings) have their ViewModels lifted to `RootView` as shared `@StateObject`, but `AyahPool` ViewModels are local. This creates an inconsistent pattern that may confuse future contributors.
