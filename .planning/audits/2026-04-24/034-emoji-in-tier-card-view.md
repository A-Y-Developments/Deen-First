---
id: 034
title: Raw emoji literal in TierCardView violates no-emoji rule
severity: P3
area: code-quality
status: closed
---

## Problem

`UnblockDurationSelectionView.swift` contains a raw `Text("🔥")` emoji literal at line ~137 inside `TierCardView`. While this view is currently dead code (finding 020), it still violates the project rule against emoji in source files.

## Evidence

`UnblockDurationSelectionView.swift` line ~137:

```swift
Text("🔥")  // Hard Mode indicator inside TierCardView
```

CLAUDE.md global rules: "No emojis in any responses or output." The `BlockRuleCard.swift` correctly uses `Image(systemName: "flame.fill")` for the same Hard Mode visual indicator — establishing the correct pattern.

## Solution

Replace `Text("🔥")` with `Image(systemName: "flame.fill").foregroundColor(.orange)` consistent with `BlockRuleCard.swift`:

```swift
Image(systemName: "flame.fill")
    .foregroundColor(.orange)
    .font(.caption)
```

## Why

Consistency with existing Hard Mode indicators (`BlockRuleCard` uses SF Symbol) and compliance with the no-emoji rule. SF Symbols also scale with Dynamic Type and respect the user's system tint preferences — raw emoji does not.
