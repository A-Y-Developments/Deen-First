# Deen First V2 Audit — 2026-04-24

Full audit of V2 (DF-1..DF-42) against PRD, architecture rules, and code. 82 findings across 6 areas.

---

## RESOLVED — 2026-04-24 sweep (Wave 3)

Post-Wave-2 closure pass executed in two rounds:

**Round 1 (verification sweep):** 60 of 82 audits flipped `status: open → status: closed` after code-level verification of the Wave 2 track landings.

**Round 2 (follow-through):** implemented the 14 gap items identified in Round 1 + reclassified 3 miscategorised audits → 15 additional flips. Pipeline re-verified green after the new code (506 tests, 0 failures).

**Final state:** 75 of 82 audits `status: closed`. 6 audits kept `status: open` pending physical-device verification. 1 audit retains its pre-existing `status: reviewed-false-positive` (093).

### Closure counts by area

| Area | Total | Closed | Device-pending | Still open | Pre-existing false-positive |
|---|---|---|---|---|---|
| Dashboard (001–008) | 8 | 5 | 3 | 0 | 0 |
| Unblock / Hard Mode (020–035) | 16 | 15 | 1 | 0 | 0 |
| Lock Editing / Ayah Pool (040–055) | 16 | 15 | 1 | 0 | 0 |
| Navigation / Architecture (060–078) | 19 | 19 | 0 | 0 | 0 |
| Infra / Tuist (090–101) | 12 | 10 | 1 | 0 | 1 (093) |
| V1 regression + quality (110–120) | 11 | 11 | 0 | 0 | 0 |
| **Total** | **82** | **75** | **6** | **0** | **1** |

### Code change shipped — pending physical-device verification (6)

Code matches the Solution but the Wave 3 Step 3 device checklist must confirm behavior. Frontmatter kept at `status: open` until device-pass.

| # | Reason |
|---|---|
| 001 | `.extensionKitExtension` + `EXAppExtensionAttributes` in place — need device to confirm extension actually loads |
| 002 | `DashboardDetailView` instantiates all 5 contexts — need device to confirm they render |
| 003 | `.daily(during:)` 7-segment filter in place — need device to confirm 7 bars render |
| 021 | Legacy `UnblockDurationSheet` removed; tier 3 routes to `.focusSection` — need device to walk flow |
| 043 | `.disableHardMode` apply now clears `isLockEditingEnabled` — need device to exercise pending apply |
| 090 | Extension point identifier fixed per Apple recipe — behavior is device-behavioral |

### Round 2 closures — new code + reclassifications (15)

**Newly implemented in Wave 3 follow-through:**
- **025** — `awaitingNextAyah` enum case now carries `completedIndex` + `totalAyahs`; view renders "Ayah N Complete" dynamically for HM Tier 2 (3 ayahs).
- **029** — `showPoolNudge` flag resets at start of `loadRandomAyah` so it drops when the pool is refilled mid-session.
- **032 / 115** — `UnblockTier` moved to `Domain/Entities/UnblockTier.swift`; presentation-layer definition deleted.
- **033** — `SessionService` focus-session record now gated on `!session.type.isUnblock` so Tier 3 unblock sessions no longer inflate Deen Score.
- **034** — `Text("🔥")` replaced with `Image(systemName: "flame.fill")`.
- **035** — `isHardMode` now snapshot at session start as `isHardModeSession`; `targetRuleId.didSet` eagerly refreshes. Mid-session rule edits can no longer shift thresholds between recording and scoring.
- **055** — `BGTaskSchedulerPermittedIdentifiers` + `fetch` background mode added to `Project.swift` infoPlist. Handler was already registered in `AppDelegate`.
- **066** — Extracted `UnblockCountdownManager` (`Domain/Services/`); `HomeTabViewModel` and `BlockingTabViewModel` both delegate ticking to it. No more duplicated timer plumbing.
- **068** — `AyahPoolViewModel` hoisted to `RootView` as `@StateObject`, injected via `@EnvironmentObject`.
- **118** — `URL(string:)!` force-unwraps in `PaywallView` replaced with `if let` optional binding.

**Reclassified (code was already correct — Round 1 agent misread):**
- **044** — HM confirmation dialog IS wired in both `TimeLimitView` and `AppLimitView` (`$viewModel.showHardModeConfirmation`).
- **091 / 092** — profile name variables in `Project.swift:10-13` ARE all in canonical `"DeenFirst ... Distribution"` (no space in DeenFirst).
- **094** — audit Solution explicitly says "no immediate code change required — flag for future refactor tracking"; documented as closed with design acknowledgement.

### Negative finding / pre-existing false-positive

- **077** — closed. Pattern is now consistent (EnvironmentObject wired via RootView).
- **093** — `status: reviewed-false-positive` (retained, not flipped). No `SFSpeechRecognizer` usage; Whisper HTTP upload + `NSMicrophoneUsageDescription` is sufficient.
- **098, 099, 100** — closed. Confirmed no-action-required after verification.
- **120** — closed. V1 auth, emergency unblock, daily surah, Quran search, paywall, streak, RevenueCat all traced intact.

### Remaining work before this wave's PR can merge

1. **Physical-device verification (Step 3)** — 40-item checklist in `prompts/WAVE-3-final-sweep.md`. Cannot be executed in simulator (`DeenFirstActivityReport` needs real device). Device pass will close the 6 device-pending audits, or produce fix commits on this branch.
2. Follow-up tickets are **no longer required** — all non-device-pending audits now have code-level closure.

---

## TOP-LINE DIAGNOSIS

**Why the Dashboard is not working.** Three compounding failures:

1. **(001 P0)** Committed `Project.swift` used `.appExtension` + legacy `NSExtension` identifier. iOS 17+ `DeviceActivityReportExtension` requires `.extensionKitExtension` + `EXAppExtensionAttributes`. **Fix exists in working tree but uncommitted.**
2. **(097 P0)** Committed `Project.swift` did not declare `DeenFirstActivityReport` as a dependency of the main app, so the extension was never embedded in the app bundle — it could not be loaded by the OS. **Fix exists in working tree but uncommitted.**
3. **(002 P0)** Even after registration is fixed, `DashboardTabView` only passes the `"DeenScore"` context to `DeviceActivityReport`. The other four scenes (`ScreenTimeOverview`, `QuranEngagementToday`, `QuranVsScreenTime`, `WeeklyTrend`) are architecturally unreachable — they were built and declared in the extension but never driven from the host view.
4. **(003 P0)** Weekly trend scene receives a `.weekly(during:)` filter (1 segment) instead of 7 daily segments — chart will always show phantom zero bars.

**So: commit the working-tree `Project.swift` + fix `DashboardTabView` to drive all five contexts + fix the weekly filter.** Then the dashboard will render real data.

**V2 accountability model is silently unenforced.** Tier picker (`UnblockDurationSelectionView`) is dead code — never navigated to (020 P0). The live Tier 3 path crashes (021 P0). Progressive tier unlock and 3-tier-per-session cap are both completely unimplemented (022/023/073 P1). User can pick Tier 3 first-try and repeat indefinitely — this defeats V2's entire "accountability friction" thesis.

**Silent data-loss bugs.** Two distinct paths silently lose user data: (042 P1) pending `.disable` type calls `applyDelete`, permanently deleting rules users wanted disabled; (111 P1) non-locked edit does `try? deleteAppLimit` then creates a new rule — any failure leaves the user with no blocking rule and no error.

**Hard Mode trap.** Hard Mode save silently force-enables Lock Editing (044), and `disableHardMode` doesn't clear Lock Editing (043) — a user who turns Hard Mode on is locked into a 48-hour exit path with zero UX disclosure.

---

## SEVERITY COUNTS BY AREA

| Area | P0 | P1 | P2 | P3 | Total |
|---|---|---|---|---|---|
| Dashboard (001–008) | 4 | 0 | 3 | 1 | 8 |
| Unblock + Hard Mode (020–035) | 2 | 7 | 6 | 1 | 16 |
| Lock Editing + Ayah Pool (040–055) | 0 | 7 | 6 | 3 | 16 |
| Navigation + Architecture (060–078) | 0 | 7 | 9 | 3 | 19 |
| Infra / Tuist / Entitlements (090–101) | 2 | 1 | 4 | 5 | 12 |
| V1 regression + code quality (110–120) | 0 | 3 | 5 | 3 | 11 |
| **Total** | **8** | **25** | **33** | **16** | **82** |

Unique issues ≈ 79 (duplicates: 062↔112, 064↔117, 027↔078 flagged by two agents).

**After review:** findings 004 (was P1 "build-blocking") and 093 (was P1 "missing plist key") were both demoted on re-verification — see individual file notes.

---

## P0 — SHIP-BLOCKERS (fix these before anything else)

| # | Title |
|---|---|
| 001 | Extension product type is `.appExtension`; iOS 17+ DeviceActivityReport requires `.extensionKitExtension` (working tree fixes this — needs commit) |
| 002 | DashboardTabView only drives `"DeenScore"` context; 4 of 5 scenes unreachable |
| 003 | Weekly trend uses `.weekly(during:)` filter — scene needs 7 daily segments |
| 020 | `UnblockDurationSelectionView` never navigated to — entire tier picker is dead code |
| 021 | Tier 3 live path crashes — `ayahCount` returns 0 in `UnblockDurationSheet` |
| 090 | Working-tree extension identifier fix needs commit |
| 097 | Committed Project.swift missing `DeenFirstActivityReport` as main app dep — extension never embedded (fixed in working tree; needs commit) |
| (implicit) | User-requested: reduce 5 tabs → 4; move Dashboard into Home (see `MIGRATION-dashboard-to-home.md`) |

---

## P1 — SHOULD-FIX BEFORE SHIP (27 items)

### Unblock / Hard Mode
- **022** — Progressive tier unlock not enforced (tiers always selectable)
- **023** — Max-3-tiers-per-session cap not implemented (unlimited retries)
- **024** — `handlePass` ignores Hard Mode minutes — HM T3 grants 15 not 20
- **025** — "Ayah 1 Complete" hardcoded — wrong for HM Tier 2 (3 ayahs)
- **026** — `acceptTier1Downgrade` checks `== 1` — fails HM Tier 2 index 2
- **027 / 078** — `callWhisperAPI` uses `URLSession.shared` + force-unwrapped URL (duplicate finding)
- **028** — `isUnblockSession` mutated after `repository.save()` — not persisted on crash
- **073** — `UnblockDurationSelectionView` renders all 3 tier cards unconditionally

### Lock Editing / Ayah Pool
- **040** — Clock-jump guard fires on overnight sleep (8h+) — changes may never apply
- **042** — `.disable` & `.delete` pending types both call `applyDelete` (data loss)
- **043** — `disableHardMode` apply leaves `isLockEditingEnabled = true` (48h exit)
- **044** — Hard Mode save silently force-enables Lock Editing (no confirmation)
- **049** — `addAyah` stores ayahs with `wordCount < 5` — silently ineligible in HM
- **052** — Pool-empty nudge fires in Normal Mode when pool is intentionally empty

### Navigation / Architecture
- **060** — 5 tabs rendered — Dashboard tab must be removed (user request)
- **061** — `currentUser!` force unwrap in `RootView.swift:40`
- **062 / 112** — 15 `print()` calls in ScreenTimeMonitor extension (duplicate)
- **064 / 117** — SummaryViewModel uses `@escaping` + `DispatchQueue` (duplicate)

### Infra
- **091** — Shield signing profile name inconsistent ("Deen First" vs "DeenFirst")

### V1 regression
- **110** — Streak increments on unblock sessions (Tier 3 focus sessions inflate streak)
- **111** — Non-locked edit does `try? delete` then create — rule silently lost on failure

---

## P2 — SHOULD-FIX (33 items, code quality + correctness)

See individual files `004, 006, 007, 008, 029–035, 041, 045, 048, 050, 051, 054, 055, 063, 065–072, 074–077, 094, 095, 100, 113–116`.

Highlights:
- **113** — `ReciteToUnblockViewModel` is 631 lines (god object — 5 separate findings live inside)
- **114** — `isUnblockSession: Bool` + nullable `unlockRuleId` should be `SessionType.unblock(ruleId:)` enum case (root cause of 110)
- **066** — Countdown-to-expiry logic duplicated in Home + Blocking ViewModels
- **074** — `applyFlagUpdate` helper duplicated in `PendingChangeService` + `ScreenTimeRulesService+LockEditing`
- **075** — Deen Score formula: spec says `clamp(50 + positives - negatives)`, code is tiered step-function
- **072** — `ScreenTimeRule` spec says SwiftData `@Model`, code has `Codable struct in UserDefaults`

---

## P3 — NITS (15 items)

See individual files. Cosmetic / docs / negative findings.

Notable:
- **120** — NEGATIVE FINDING: auth, emergency unblock, daily surah, Quran search, paywall verified intact (no V1 regression in those flows).

---

## COMPANION DOCS

- **`MIGRATION-dashboard-to-home.md`** — full design for 5→4 tabs + Dashboard-on-Home, including files to add/modify/delete and ordered migration steps 1–10.

---

## RECOMMENDED REMEDIATION ORDER

### Phase 1 — Unblock the dashboard (couple hours)
1. Commit working-tree `Project.swift` ONLY (fixes 001 + 090 + 097). **Use `git add Project.swift && git commit`, NOT `git commit -am`** — the working tree also has uncommitted `PrimaryButton.swift` UI changes that should not ride along.
2. Fix `DashboardTabView` to drive all 5 contexts (002).
3. Fix Weekly Trend filter to daily segments (003).
4. Verify on physical device (`DeenFirstActivityReport` cannot be tested on simulator).

### Phase 2 — Tab migration per user request (half day)
6. Execute `MIGRATION-dashboard-to-home.md` steps 1–10.
7. Delete `DashboardTab/` folder, rename `.dashboard` route to `.dashboardDetail`.
8. Add `DashboardSummaryCard` to Home, push to `DashboardDetailView` on tap.

### Phase 3 — Fix V2 accountability (1–2 days)
9. Wire `UnblockDurationSelectionView` into the live path; kill dead `UnblockDurationSheet` tier3 branch (020, 021).
10. Implement progressive tier unlock + 3-tier cap (022, 023, 073).
11. Fix Hard Mode minutes + Tier 2 index checks (024, 026).
12. Extract Whisper call into `WhisperAPIDataSource`, remove raw `URLSession` (027, 078).

### Phase 4 — Close the silent data-loss paths (half day)
13. Fix `.disable` pending type to call apply-disable, not apply-delete (042).
14. Non-locked edit: wrap in transaction or use update, not delete+create (111).
15. Add pending-apply post-sleep handling: distinguish "device slept" from "clock was tampered" (040).

### Phase 5 — Hard Mode UX trap (half day)
16. Add confirmation dialog when enabling Hard Mode that discloses Lock Editing auto-enable (044).
17. `disableHardMode` pending apply should also clear `isLockEditingEnabled` (043).
18. Reject short ayahs at add time in ayah pool (049).

### Phase 6 — Code quality (spread across any sprint)
19. Split `ReciteToUnblockViewModel` into tier state machine + scoring + audio services (113).
20. Convert `isUnblockSession` to `SessionType.unblock(ruleId:)` enum case (114).
21. Replace all `print()` in ScreenTimeMonitor with `os_log` (062/112).
22. Convert SummaryViewModel to async/await (064/117).
23. Consolidate signing profile names (091/092).
24. Move `ScreenTimeEvents.swift` out of `Shared/` (004).

### Phase 7 — Cleanup
25. Remove dead code: `StartView`, `SetupView`, unused `companyId` env, unused `BottomSheet` dep (119, 096, 101).
26. Consolidate duplicated countdown logic (066) and flag-update helper (074).
27. Reconcile Deen Score spec vs implementation (075).

---

## HOW TO READ A FINDING FILE

Every file in this folder follows the schema in the frontmatter + four sections: **Problem / Evidence (file:line) / Solution / Why**. You can open any `NNN-slug.md` and get a standalone, actionable fix spec.
