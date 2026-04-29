# Domain Reference

## Core Entities (SwiftData @Model)

### V1
- `User` — id, isPremium, hasCompletedOnboarding, streakStartDate, currentStreak
- `Session` — id, userId, modality (`reading`|`listening`), surahNumbers, reciterId, durationSeconds, isCompleted, `type: SessionType` (`.normal` | `.unblock(ruleId:)`) (V2). Internal storage retains `isUnblockSession: Bool` + `unlockRuleId: UUID?` for SwiftData backward compatibility — read/write through `type` only.

### V2 New
- `PendingRuleChange` — id, ruleId, changeType, pendingData, requestedAt, appliesAt, isCancelled, isApplied
- `AyahPoolItem` — id, surahNumber, ayahNumberInSurah, arabicText, transliteration, wordCount, addedAt

## UserDefaults-backed Entities

`ScreenTimeRule` is **not** a SwiftData `@Model`. It is a `Codable struct` persisted to the App Group `UserDefaults` (`group.com.aydev.deenfirst`) via `ScreenTimeRulesRepository`. UserDefaults is used because extension targets (ScreenTimeMonitor, Shield, DeenFirstActivityReport) need cross-process read access to the rule set, and SwiftData stores are not shared across process boundaries in the same way.

- `ScreenTimeRule` — id, name, type, applicationTokenData, categoryTokenData, limitSeconds, startTime, endTime, daysActiveArray, unblockAllowedAfterLimit, durationOptions, createdAt, **isHardMode** (V2), **isLockEditingEnabled** (V2)
- V2 fields (`isHardMode`, `isLockEditingEnabled`) were added with a custom `Decodable` init that defaults both to `false` for rules persisted before V2 — a JSON-level backward-compat shim, not a SwiftData migration.

## Key Enums

- `UnblockTier`: `tier1` (5 min) · `tier2` (10 min) · `tier3` (15 min Normal / 20 min Hard Mode). Read minutes via `tier.minutes(isHardMode:)` — never inline.
- `PendingChangeType`: `edit` · `delete` · `disable` · `disableHardMode` · `disableLockEditing`
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
- `PendingChangeService.applyExpiredChanges()` called on app foreground (and via `BGTaskScheduler` background refresh, identifier `com.aydev.deenfirst.pending-apply`)
- Clock manipulation guard: `applyExpiredChanges` compares wall-clock delta to monotonic uptime delta (`CLOCK_MONOTONIC`). If wall-clock advanced materially further than monotonic (or rolled backward) beyond a 10-minute tolerance, treat as tamper, log at `.error`, and skip silently. Reboot is detected by negative monotonic delta and refreshes the baseline benignly.
- User can cancel a pending change before it applies

### Custom Ayah Pool
- Max 20 `AyahPoolItem`s per user. Canonical constant: `AyahPoolService.maxPoolSize`.
- Add-time eligibility: `wordCount >= 5` (enforced in `AyahPoolService.addAyah`). Short ayahs are rejected with `AyahPoolError.ayahTooShort`.
- **Normal Mode:**
  - If pool is non-empty → recitation draws from pool (no word-count filter).
  - If pool is empty → system falls back to standard (random) ayah selection. No nudge is shown.
- **Hard Mode:**
  - If pool is non-empty → recitation draws from pool, filtered to `wordCount >= 5`.
  - If the filtered pool is empty (pool empty or all short) → a once-per-day nudge is shown prompting the user to add eligible ayahs; the flow falls back to random selection of ayahs that match Hard Mode's `wordCount >= 5` filter.
- Nudge gate: `AppGroupConstants.poolNudgeDateKey` tracks last-shown day. The stamp is cleared after a successful add so the nudge can re-trigger if the pool is emptied later.

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
