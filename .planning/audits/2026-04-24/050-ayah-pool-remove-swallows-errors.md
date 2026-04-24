---
id: 050
title: AyahPoolService.removeAyah uses try? swallowing delete errors silently
severity: P2
area: ayah-pool
status: closed
---

## Problem

`AyahPoolService.removeAyah` calls the delete data source with `try?`, silently discarding any SwiftData or repository error. The caller receives no indication of failure. If the delete silently fails, the ayah remains in the pool and the UI still shows it as removed (if the ViewModel optimistically removes it from its published array) — creating a stale-read divergence on next load.

## Evidence

`Domain/Services/AyahPoolService.swift` line 75 (approx):
```swift
func removeAyah(_ item: AyahPoolItem) async {
    try? localDataSource.deleteAyahPoolItem(item)
}
```

This violates project error-handling rule #2: "No `try?` that silently discards errors — unless the failure is truly P3 and you log it." No log is present here.

## Solution

Propagate the error:
```swift
func removeAyah(_ item: AyahPoolItem) async throws {
    try localDataSource.deleteAyahPoolItem(item)
}
```

Update call sites in `AyahPoolViewModel` to handle the error with an `errorMessage` published property.

## Why

Delete failures in SwiftData are rare but real (disk full, model migration mismatch). Silently discarding them leaves the data layer in an inconsistent state with no recovery path.
