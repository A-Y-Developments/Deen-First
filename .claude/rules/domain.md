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
- Computed by `calculateDeenScore(_: DeenScoreInput)` in `Shared/DeenScoreCalculator.swift`.
- Inputs (`DeenScoreInput`): `quranSeconds`, `focusSessions`, `recitationsPassed`, `streakDays`, `screenTimeOverLimitSeconds`, `emergencyUnblocksThisWeek`.
- Shape: tiered step-function starting at base `50`, clamped to `[0, 100]`. See `ScoreWeights` for exact thresholds and point awards.
- Tiers (positives):
  - Quran seconds → 0 / 5 / 10 / 15 / 20 pts at `<10m / <20m / <30m / ≥30m` (see `quranTier*`)
  - Focus sessions → 0 / 10 / 15 pts at `0 / 1 / 2+` sessions
  - Recitations passed → 0 / 5 / 10 pts at `0 / 1–2 / 3+`
  - Streak days → 0 / 5 / 10 pts at `0 / 1–6 / 7+`
- Tiers (negatives):
  - Screen time over daily limit → 0 / -10 / -20 / -30 at `<30m / <60m / <90m / ≥90m`
  - Emergency unblocks this week → 0 / -5 / -10 at `0 / 1 / 2+`
- Calculated on read (pure function, no caching). Per-day inputs are written to App Group by `DashboardDataWriter`.
- Rendered by `DeenFirstActivityReport` extension (read-only from App Group) and by the main app's Home summary card.
