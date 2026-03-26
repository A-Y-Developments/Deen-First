# Domain Reference

## Core Entities (SwiftData @Model)

### V1
- `User` — id, isPremium, hasCompletedOnboarding, streakStartDate, currentStreak
- `Session` — id, surahIds, ayahIds, duration, completedAt, isUnblockSession (V2)
- `ScreenTimeRule` — id, name, isEnabled, **isHardMode** (V2), **isLockEditingEnabled** (V2)

### V2 New
- `PendingRuleChange` — id, ruleId, changeType, pendingData, requestedAt, appliesAt, isCancelled, isApplied
- `AyahPoolItem` — id, surahNumber, ayahNumberInSurah, arabicText, transliteration, wordCount, addedAt

## Key Enums

- `UnblockTier`: `tier1` (5 min) · `tier2` (10 min) · `tier3` (15 min)
- `PendingChangeType`: `editRule` · `disableLockEditing` (others TBD)
- Recitation threshold: `0.70` normal · `0.85` hard mode

## Business Rules

### Tiered Unblock
- Tiers unlock progressively: must complete lower tier to access higher
- Longer-wins: if mid-unblock, next session grants the higher remaining time
- 3 tiers max per blocking session

### Hard Mode
- 85% Whisper similarity threshold (not 70%)
- Only ayahs with `wordCount >= 5` eligible for recitation
- "Refresh ayah" button disabled
- Applied per-rule (each `ScreenTimeRule` can have its own Hard Mode setting)

### Lock Editing
- When `isLockEditingEnabled = true`: rule edits are queued as `PendingRuleChange` with `appliesAt = requestedAt + 24h`
- `PendingChangeService.applyDuePendingChanges()` called on app foreground
- Clock manipulation guard: skip apply if `Date() - lastKnownDate > 2 hours`
- User can cancel a pending change before it applies

### Custom Ayah Pool
- Max 20 `AyahPoolItem`s per user
- In Hard Mode: recitation draws from pool exclusively (if non-empty)
- In Normal Mode: pool is optional; system uses standard ayah selection if pool empty

### Deen Score
- Formula: `clamp(50 + positives - negatives, 0, 100)`
- Positives: Quran session time, session count, recitation completions, streak days
- Negatives: screen time over daily limit (per app), emergency unblocks used
- Calculated daily; written to App Group by `DashboardDataWriter`
- Rendered by `DeenFirstActivityReport` extension (read-only from App Group)
