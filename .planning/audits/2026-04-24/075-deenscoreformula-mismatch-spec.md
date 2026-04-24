---
id: 075
title: DeenScore formula does not match PRD spec (clamp(50 + positives - negatives))
severity: P2
area: dashboard
status: closed
---

## Problem

`domain.md` specifies the Deen Score formula as: `clamp(50 + positives - negatives, 0, 100)`. The actual implementation in `DeenScoreCalculator.swift` uses a tiered scoring system with multiple weight constants — NOT a simple positives-minus-negatives additive formula. While the base is 50 and the clamp is applied, the individual component weights are not documented anywhere in the domain spec.

Additionally, the spec says "Negatives: screen time over daily limit (per app)". The calculator uses total `screenTimeOverLimitSeconds` (a single aggregated value) — there's no per-app breakdown.

## Evidence

`domain.md`:
```
Formula: clamp(50 + positives - negatives, 0, 100)
Negatives: screen time over daily limit (per app), emergency unblocks used
```

`DeenScoreCalculator.swift:63`:
```swift
func calculateDeenScore(_ input: DeenScoreInput) -> Int {
    var score = ScoreWeights.base  // 50
    score += quranTimePoints(...)   // tiered: +5, +10, +15, +20
    score += focusSessionPoints(...) // +10 or +15
    score += recitationPoints(...)   // +5 or +10
    score += streakPoints(...)       // +5 or +10
    score += overLimitPenalty(...)   // tiered: -10, -20, -30
    score += emergencyUnblockPenalty(...) // -5 or -10
}
```

`DeenScoreInput.screenTimeOverLimitSeconds` is a single aggregated metric — not per-app.

## Solution

Either:
1. Update `domain.md` to accurately document the tiered weights (preferred — implementation is more nuanced and useful than the spec).
2. Or update the implementation to match the simpler spec.

The per-app breakdown issue requires `DeenScoreInput` to accept `[String: Int]` per-app over-limit seconds if that granularity is desired.

## Why

Spec-implementation mismatch misleads QA and future contributors. The Deen Score is a user-facing feature — its formula should be documented accurately.
