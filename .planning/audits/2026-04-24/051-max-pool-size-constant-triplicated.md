---
id: 051
title: maxPoolSize = 20 triplicated across service and two ViewModels
severity: P2
area: ayah-pool
status: open
---

## Problem

The maximum ayah pool size (20) is defined as a private constant in three separate files: `AyahPoolService`, `AyahPoolViewModel`, and `AyahPoolSurahPickerViewModel`. If the limit changes, all three must be updated in sync. They are not currently derived from a shared source.

## Evidence

- `Domain/Services/AyahPoolService.swift`: `private let maxPoolSize = 20`
- `Presentation/AyahPool/AyahPoolViewModel.swift`: `let maxPoolSize = 20` (or similar)
- `Presentation/AyahPool/AyahPoolSurahPickerViewModel.swift`: `let maxPoolSize = 20`

## Solution

Define the constant once in `AyahPoolService` (or in a shared `AyahPoolConstants` namespace) and expose it as a `static` property:
```swift
extension AyahPoolService {
    static let maxPoolSize = 20
}
```

ViewModels read from `AyahPoolService.maxPoolSize` (or `DIContainer.shared.ayahPoolService.maxPoolSize`). Alternatively, surface it via a `poolCapacity: Int` property on the service protocol.

## Why

DRY violation. Three-way duplication of a business rule constant means one change requires three edits and three PR reviewers to catch the discrepancy.
