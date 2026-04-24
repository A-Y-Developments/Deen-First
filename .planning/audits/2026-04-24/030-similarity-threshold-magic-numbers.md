---
id: 030
title: Whisper similarity threshold uses magic number literals instead of named constants
severity: P2
area: hard-mode
status: open
---

## Problem

`ReciteToUnblockViewModel.similarityThreshold` is computed using inline magic numbers `0.85` (Hard Mode) and `0.70` (Normal Mode). These values are the core of the Hard Mode behavioral difference — having them as unnamed literals makes them invisible in grep, undiscoverable in the domain layer, and easy to silently change or misapply.

## Evidence

`ReciteToUnblockViewModel.swift` line ~132:

```swift
var similarityThreshold: Double {
    isHardMode ? 0.85 : 0.70
}
```

`domain.md` explicitly documents these values: "Recitation threshold: 0.70 normal · 0.85 hard mode" — these are domain constants, not implementation details.

## Solution

Define named constants in a shared or domain location:

```swift
// In a RecitationThreshold namespace or AppConstants
enum RecitationThreshold {
    static let normal: Double = 0.70
    static let hardMode: Double = 0.85
}
```

Then:
```swift
var similarityThreshold: Double {
    isHardMode ? RecitationThreshold.hardMode : RecitationThreshold.normal
}
```

Place the enum in `Shared/` if extensions ever need it, or `Domain/` if app-only.

## Why

Magic numbers in threshold comparisons are a common source of silent regressions. A future change to recalibrate the threshold would require grep across the codebase rather than a single constant update. Named constants also make test assertions self-documenting.
