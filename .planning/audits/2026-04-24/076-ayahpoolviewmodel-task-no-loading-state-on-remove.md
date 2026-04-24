---
id: 076
title: AyahPoolViewModel.remove() fires Task without setting isLoading — inconsistent loading state
severity: P3
area: ayah-pool
status: closed
---

## Problem

`AyahPoolViewModel.load()` correctly sets `isLoading = true/false` wrapping the async fetch. However `remove(id:)` at line 52 fires a `Task {}` without setting `isLoading`, while `fetchPool()` is called inside the task. If the fetch is slow (unlikely but possible), the UI shows stale items with no loading indicator during the remove+refetch cycle.

## Evidence

`AyahPoolViewModel.swift:52-57`:
```swift
func remove(id: UUID) {
    Task {
        await ayahPoolService.removeAyah(id: id)
        items = await ayahPoolService.fetchPool()
            .sorted { $0.addedAt < $1.addedAt }
    }
}
```

No `isLoading = true` before, no `isLoading = false` after. Contrast with `load()` lines 31-49 which correctly brackets with `isLoading`.

## Solution

```swift
func remove(id: UUID) {
    Task {
        isLoading = true
        await ayahPoolService.removeAyah(id: id)
        items = await ayahPoolService.fetchPool()
            .sorted { $0.addedAt < $1.addedAt }
        isLoading = false
    }
}
```

## Why

CLAUDE.md error-handling rules: "every async ViewModel operation sets isLoading before and after." The omission is minor (local SwiftData read is near-instant) but violates the explicit project rule and creates a UI flash if the list refreshes without a loading state.
