---
id: 026
title: acceptTier1Downgrade() index check fails Hard Mode Tier 2 after 2-of-3 ayahs
severity: P1
area: hard-mode
status: open
---

## Problem

`acceptTier1Downgrade()` in `ReciteToUnblockViewModel` checks `currentAyahIndex == 1` to determine whether the user passed at least one ayah before hitting 3 consecutive failures. In Hard Mode Tier 2 (3-ayah sequence), a user who passes ayahs 0 and 1 but fails on ayah 2 three times has `currentAyahIndex == 2` — the condition is false, and the else branch forces a full retry instead of offering the downgrade leniency. The user is penalized despite having completed 2 of 3 ayahs.

## Evidence

`ReciteToUnblockViewModel.swift` — `acceptTier1Downgrade()`:

```swift
func acceptTier1Downgrade() {
    if currentAyahIndex == 1 {
        // Grant tier1 unblock for partial completion
        Task { await handleTier1DowngradeUnblock() }
    } else {
        // Forces full retry
        resetToStart()
    }
}
```

Tier 2 Hard Mode: `ayahSequence.count == 3`. After passing ayahs at index 0 and 1, `currentAyahIndex == 2`. Three failures on index 2 triggers the downgrade offer — but `currentAyahIndex == 1` is false → `resetToStart()`.

Tier 2 Normal Mode: `ayahSequence.count == 2`. After passing index 0, `currentAyahIndex == 1` → condition is true → works correctly. This is the only case the check was written for.

## Solution

Replace the index equality check with a positional check — "user has completed at least one ayah":

```swift
func acceptTier1Downgrade() {
    if currentAyahIndex > 0 {
        Task { await handleTier1DowngradeUnblock() }
    } else {
        resetToStart()
    }
}
```

This correctly covers:
- Tier 2 Normal (2 ayahs): index 1 > 0 → downgrade
- Tier 2 Hard Mode (3 ayahs): index 1 or 2 > 0 → downgrade
- Tier 1 (1 ayah): index 0 when failing first ayah → full restart (correct)

## Why

The original check `== 1` was written for the specific Tier 2 normal-mode case (2 ayahs, fail on second) and was not generalized. Hard Mode adds a third ayah, bumping the index at failure to 2, which the check doesn't cover.
