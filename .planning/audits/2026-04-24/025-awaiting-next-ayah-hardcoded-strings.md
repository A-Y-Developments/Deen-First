---
id: 025
title: awaitingNextAyah UI hardcodes "Ayah 1 Complete!" — wrong for HM Tier 2 ayah 2→3 transition
severity: P1
area: hard-mode
status: open
---

## Problem

The `awaitingNextAyah` state in `ReciteToUnblockView` shows hardcoded strings "Ayah 1 Complete!" and "Now recite the second ayah" regardless of which ayah was just completed. In Hard Mode Tier 2 (3 ayahs), after completing Ayah 2 the user sees "Ayah 1 Complete! / Now recite the second ayah" — both lines are factually wrong.

## Evidence

`ReciteToUnblockView.swift` (or the content view that renders `.awaitingNextAyah`) — the case renders:

```swift
case .awaitingNextAyah(let score):
    VStack {
        Text("Ayah 1 Complete!")       // hardcoded
        Text("Score: \(score)%")
        Text("Now recite the second ayah")  // hardcoded
        Button("Next Ayah") { vm.proceedToNextAyah() }
    }
```

`ReciteToUnblockViewModel.swift` — `processRecitationOutcome` transitions to `.awaitingNextAyah(score:)` when passing any non-final ayah:

```swift
// tier2 HM: ayahSequence has 3 items
// after ayah index 0 passes → .awaitingNextAyah (correct: "Ayah 1 done, next is Ayah 2")
// after ayah index 1 passes → .awaitingNextAyah (WRONG: still says "Ayah 1 Complete!")
```

The `awaitingNextAyah` enum case carries only `score`, not the current ayah index.

## Solution

Two options:

**Option A (minimal):** Change the associated value of `.awaitingNextAyah` to include the completed index:
```swift
case awaitingNextAyah(completedIndex: Int, score: Int)
```
Then in the view:
```swift
Text("Ayah \(completedIndex + 1) Complete!")
Text("Now recite ayah \(completedIndex + 2)")
```

**Option B:** Use `vm.currentAyahIndex` directly in the view (it points to the *next* ayah after advancement) — no enum change needed, but couples view more to VM state.

Option A is cleaner as it keeps information in the state enum.

## Why

The state machine advances `currentAyahIndex` before emitting `.awaitingNextAyah`, so the index at render time always reflects the *next* ayah. The hardcoded strings were written for the Tier 2 normal-mode 2-ayah case and were never generalized.
