---
id: 054
title: AyahPoolSurahPickerViewModel.addSelected() stops on poolFull with no per-ayah feedback
severity: P2
area: ayah-pool
status: closed
---

## Problem

`AyahPoolSurahPickerViewModel.addSelected()` iterates the user's selection and stops as soon as `AyahPoolError.poolFull` is thrown. It shows `showPoolFullAlert = true`, but the user has no way to know which ayahs from their selection were successfully added vs which were skipped. If they selected 8 ayahs and 5 fit, they see an alert but don't know the state of the pool.

## Evidence

`Presentation/AyahPool/AyahPoolSurahPickerViewModel.swift` lines 130-168 (approx):
```swift
for ayah in selectedAyahs {
    do {
        try await ayahPoolService.addAyah(ayah)
    } catch AyahPoolError.poolFull {
        showPoolFullAlert = true
        break  // stops here; prior adds are committed
    }
}
```

The alert message (inferred from `showPoolFullAlert`) says the pool is full but does not confirm how many were added.

## Solution

Track added count and surface it in the alert message:
```swift
var addedCount = 0
for ayah in selectedAyahs {
    do {
        try await ayahPoolService.addAyah(ayah)
        addedCount += 1
    } catch AyahPoolError.poolFull {
        poolFullAddedCount = addedCount
        showPoolFullAlert = true
        break
    }
}
```

Alert message: "Pool is full. \(addedCount) of \(selectedAyahs.count) ayahs were added."

## Why

Partial operations need transparent feedback. The user submitted a batch and needs to know the outcome of each item. Without this, they may re-attempt adding ayahs they've already added, or be confused about the pool's state.
