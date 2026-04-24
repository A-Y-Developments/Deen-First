---
id: 049
title: AyahPoolService.addAyah stores wordCount < 5 ayahs that are silently unusable in Hard Mode
severity: P1
area: ayah-pool
status: closed
---

## Problem

`AyahPoolService.addAyah` computes `wordCount` from the ayah text and stores it, but does NOT reject ayahs with fewer than 5 words. Domain rules require `wordCount >= 5` for Hard Mode recitation eligibility. These short ayahs are stored in the pool, show up in the AyahPool UI, but are silently filtered out when the recitation engine picks from the pool in Hard Mode — the user has no idea their custom ayahs are ineligible.

## Evidence

`Domain/Services/AyahPoolService.swift` lines 57-67 (approx):
```swift
func addAyah(_ ayah: AyahPoolItem) async throws {
    let words = ayah.arabicText.split(separator: " ")
    ayah.wordCount = words.count
    // No guard on wordCount >= 5
    try await localDataSource.insertAyahPoolItem(ayah)
}
```

`Presentation/ReciteToUnblock/ReciteToUnblockViewModel.swift` `resolveEligiblePool()` (lines 184-202): filters the pool to `wordCount >= 5` when Hard Mode is active. Short ayahs silently fall out of the eligible set.

## Solution

**Option A (strict):** Reject at add time with a thrown error:
```swift
guard ayah.wordCount >= 5 else {
    throw AyahPoolError.ayahTooShort
}
```
Surface this error in `AyahPoolSurahPickerViewModel` so the user sees which ayahs were rejected.

**Option B (lenient):** Allow storage but mark `isHardModeEligible` on the item and display a badge in the AyahPool UI ("Not eligible for Hard Mode").

Option A is simpler and keeps the pool semantically consistent.

## Why

Storing data that is silently discarded at use time is a correctness problem: the pool's effective size (as seen in Hard Mode) diverges from its displayed size (as shown in the UI). A user in Hard Mode who adds 10 short ayahs thinks they have 10 custom ayahs but gets 0, causing the system to fall back to random picks — defeating the purpose of the pool.
