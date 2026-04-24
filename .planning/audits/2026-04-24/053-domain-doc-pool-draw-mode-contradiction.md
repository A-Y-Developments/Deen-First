---
id: 053
title: domain.md pool-draw rule contradicts implemented behavior (draws from pool in both modes)
severity: P3
area: ayah-pool
status: open
---

## Problem

`rules/domain.md` states: "In Hard Mode: recitation draws from pool exclusively (if non-empty). In Normal Mode: pool is optional; system uses standard ayah selection if pool empty." The actual implementation in `ReciteToUnblockViewModel.resolveEligiblePool()` draws from the pool in BOTH modes (falling back to random only if pool is empty). This means in Normal Mode with a non-empty pool, pool ayahs are used — which is intentional per DF-29 but contradicts the doc.

## Evidence

`Presentation/ReciteToUnblock/ReciteToUnblockViewModel.swift` lines 184-202:
```swift
// Pool draw regardless of mode; wordCount >= 5 filter only in Hard Mode
let eligible = isHardMode
    ? pool.filter { $0.wordCount >= 5 }
    : pool  // full pool in Normal Mode
return eligible.isEmpty ? randomAyah() : eligible.randomElement()
```

`rules/domain.md` Custom Ayah Pool section says Normal Mode uses standard selection if pool empty, implying pool is NOT used in Normal Mode when non-empty — which is not what the code does.

## Solution

Update `rules/domain.md` to accurately reflect the implementation:
```
In Hard Mode: recitation draws from pool exclusively (if non-empty, wordCount >= 5 filter applied).
In Normal Mode: if pool is non-empty, pool ayahs are used (no wordCount filter); if pool is empty, falls back to standard ayah selection.
```

No code change needed — the DF-29 implementation is intentional.

## Why

Stale documentation misleads agents writing tests, auditing behavior, or building on top of this system. Low-effort fix.
