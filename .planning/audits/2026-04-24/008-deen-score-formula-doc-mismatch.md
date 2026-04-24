---
id: 008
title: domain.md documents simple additive Deen Score formula; implementation uses tiered step-function
severity: P2
area: dashboard
status: open
---

## Problem

`domain.md` (the authoritative feature specification) documents the Deen Score formula as:

> `clamp(50 + positives - negatives, 0, 100)`

The actual implementation in `DeenScoreCalculator.swift` uses a tiered step-function approach with fixed tier boundaries — not a simple additive formula. The two are not equivalent. This creates a gap between spec and implementation that will cause future feature work to be built against the wrong contract: any developer reading `domain.md` before extending the scoring will implement incorrect behavior, and the QA acceptance criteria based on the spec will produce incorrect expected values.

## Evidence

`domain.md` lines 43–48:
```
### Deen Score
- Formula: `clamp(50 + positives - negatives, 0, 100)`
- Positives: Quran session time, session count, recitation completions, streak days
- Negatives: screen time over daily limit (per app), emergency unblocks used
```

`deenfirst/Sources/Shared/DeenScoreCalculator.swift` — actual implementation uses `DeenScoreInput` struct fed into `calculateDeenScore(_:)` which applies tiered scoring with multiple threshold boundaries and step-based increments rather than a single additive formula.

`WeeklyTrendReportBuilder.swift` lines 83–91 — extension usage of the same calculator:
```swift
let input = DeenScoreInput(
    quranSeconds: quranSeconds,
    focusSessions: focusSessions,
    recitationsPassed: recitationsPassed,
    streakDays: streak,
    screenTimeOverLimitSeconds: max(0, screenSeconds - defaultDailyLimitSeconds),
    emergencyUnblocksThisWeek: emergencyUnblocks
)
score = calculateDeenScore(input)
```

The `DeenScoreInput` struct and `calculateDeenScore` function are the ground truth — the `domain.md` formula is an oversimplification.

## Solution

Update `domain.md` to accurately document the real formula. Extract and document the tier boundaries and step values from `DeenScoreCalculator.swift`. Replace the one-liner with a table or pseudocode that matches the actual implementation. Example structure:

```
### Deen Score
Calculated by `calculateDeenScore(_: DeenScoreInput)` in `Shared/DeenScoreCalculator.swift`.

Inputs: quranSeconds, focusSessions, recitationsPassed, streakDays,
        screenTimeOverLimitSeconds, emergencyUnblocksThisWeek

Formula: tiered step-function (see DeenScoreCalculator.swift for exact thresholds).
Range: 0–100.
```

Do not change the implementation — only update the spec to match what ships.

## Why

Documentation-implementation drift is a P2 maintenance hazard, not a runtime bug. The risk materializes when: (a) a developer extends Deen Score based on the spec and produces incorrect behavior; (b) integration tests assert expected score values based on the spec formula and fail spuriously against the real implementation; (c) the PRD is shared with stakeholders who make product decisions based on an incorrect formula. Fixing the doc costs one file edit; leaving it creates compounding confusion.
