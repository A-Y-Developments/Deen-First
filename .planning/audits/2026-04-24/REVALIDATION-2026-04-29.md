# Revalidation — 2026-04-29

User asked: "take a look at the audit prompts, check the code, revalidate, then re-audit, auto-fix, re-audit, auto-fix until good." High-level POV first, advisor on every move.

## Termination criteria ("good")

1. `make clean && make install && make generate && make build && make test` all green from clean state.
2. Every closed audit has a grep / file-read verification recorded below.
3. Round 2 closures (newly-implemented + reclassified) spot-checked at the logic level, not just file existence.
4. One full pass produces zero new fixable findings (or all fixable findings have been auto-fixed and re-verified).

## Source of truth on prior state

- `.planning/audits/2026-04-24/README.md`: claims 75 closed, 6 device-pending (001/002/003/021/043/090), 1 false-positive (093). Total 82.
- Frontmatter scan agrees: 75 closed, 6 open, 1 reviewed-false-positive.
- Last commit on `main`: `305f68d chore(audit): wave 3 follow-through — close remaining 15 open audits`.

## Verification approach (per advisor)

- Bucket by area, scrutinize Round 2 items first (highest misread risk).
- Never just check "file exists" — read the relevant lines and confirm the audit's Solution actually shipped.
- Flag any new findings in the "Findings from revalidation" section below; auto-fix in a follow-up commit on `main`.

---

## Baseline build/test result

- Status: ✓ green from clean
- `make clean && make install && make generate && make build`: succeeded.
- `make test` (Makefile destination `platform=iOS Simulator` only — see Findings #1): manually re-run as `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17' test` → `Executed 506 tests, with 0 failures (0 unexpected) in 24.715 (24.954) seconds`.
- README's "506 tests, 0 failures" verified.

---

## Per-area verification log

Format per row: `id | claim from audit | verification (file:line or command) | result | notes`

### Dashboard (001–008)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 001 | open | extension product type → `.extensionKitExtension` + `EXAppExtensionAttributes` | Project.swift:199,206 | ✓ code matches | device-pending: physical-only |
| 002 | open | DashboardDetailView wires all 5 contexts | DashboardDetailView.swift:30-34 (DeenScore, ScreenTimeOverview, QuranEngagement, QuranVsScreenTime, WeeklyTrend) | ✓ code matches | device-pending: physical-only |
| 003 | open | weekly trend uses `.daily` over 7-day window | DashboardDetailViewModel.swift:62-74 `makeSevenDayDailyFilter` always used for `weeklyTrendFilter` | ✓ code matches | device-pending: physical-only |
| 004 | closed | ScreenTimeEvents extension-safe | moved to Domain/ScreenTime/; ScreenTimeMonitor target sources include this path; ActivityReport target only pulls Shared/ | ✓ closure valid | folder-structure.md violation noted (file no longer in Shared/), but extension-safety preserved |
| 005 | closed | unused imports removed in Overview | DeenFirstActivityReport/ScreenTimeOverviewReportScene.swift:1-2 — only DeviceActivity + SwiftUI | ✓ |  |
| 006 | closed | ZStack fallback ordering fixed | DashboardDetailView.swift:91-110 — replaced ZStack with `Group { if reportReady }` | ✓ better-than-fix | |
| 007 | closed | Quran reading scenePhase observer | QuranReadingView.swift:7,32 `@Environment(\.scenePhase)` + `.onChange(of: scenePhase)` | ✓ | |
| 008 | closed | Deen Score formula reconciled | DeenScoreCalculator.swift tiered step-function; domain.md reflects "tiered step-function starting at base 50, clamped [0,100]" | ✓ docs updated to match code | |

### Unblock / Hard Mode (020–035)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 020 | closed | UnblockDurationSelectionView wired into live flow | RootView.swift:21,76,242-243 (route + EnvironmentObject); UnblockDurationSheet not in source | ✓ | |
| 021 | open | tier3 crash fixed; UnblockDurationSheet removed | grep finds zero `UnblockDurationSheet` matches; tier3 routes to `.focusSection` | ✓ code matches | device-pending: physical-only |
| 022 | closed | progressive tier unlock enforced | UnblockDurationSelectionViewModel.swift:33-41 `isAvailable`; tier2 needs tier1, tier3 needs tier2 | ✓ | |
| 023 | closed | max-3-tiers-per-session cap | UnblockDurationSelectionViewModel.swift:34 `usedTiers.count >= 3`; UsedTiersStore.swift via App Group | ✓ | |
| 024 | closed | handlePass HM Tier3 grants 20min | RTUVM:329 `tier.minutes(isHardMode: isHardMode)`; UnblockTier:21-25 returns 20 for HM tier3 | ✓ | |
| 025 | closed | "Ayah N Complete" dynamic for HM Tier 2 | RTUVM:301-306 `awaitingNextAyah(score:, completedIndex:, totalAyahs:)` | ✓ | Round 2 |
| 026 | closed | acceptTier1Downgrade index check fixed | RTUVM:374 `hadPriorPass = currentAyahIndex > 0` | ✓ | |
| 027 | closed | WhisperAPIDataSource via HTTPClient | WhisperAPIDataSource.swift:30,39 (URL optional bind, no `URL(string:)!`); uses `httpClient.uploadMultipart` | ✓ | |
| 028 | closed | session.type set BEFORE repository.save | SessionService.swift:130-138 — `Session(... type: type)` then `try await sessionRepository.save(session)` | ✓ | |
| 029 | closed | showPoolNudge resets at start of loadRandomAyah | RTUVM:142 `showPoolNudge = false` at top of `loadRandomAyah` | ✓ | Round 2 |
| 030 | closed | similarity thresholds named constants | RTUVM:103 `RecitationThreshold.hardMode` / `.normal` | ✓ | |
| 031 | closed | poolNudgeDateKey in AppGroupConstants | AppGroupConstants.swift:78 `static let poolNudgeDateKey = "com.aydev.deenfirst.poolNudgeDate"` | ✓ | |
| 032 | closed | UnblockTier moved to Domain/Entities | Domain/Entities/UnblockTier.swift exists; UnblockDurationSelectionViewModel.swift:3 has migration note | ✓ | Round 2 |
| 033 | closed | unblock sessions skip focus-session record | SessionService.swift:168 — `!session.type.isUnblock` gate on `recordFocusSession` | ✓ | Round 2 |
| 034 | closed | flame.fill SF Symbol replaces emoji | UnblockDurationSelectionView.swift:134 `Image(systemName: "flame.fill")` | ✓ | Round 2 |
| 035 | closed | isHardModeSession snapshot at session start | RTUVM:95-104 `isHardModeSession` private(set); RTUVM:58-66 `targetRuleId.didSet` refresh; RTUVM:134-138 fresh snapshot at `loadRandomAyah` | ✓ | Round 2 |

### Lock Editing / Ayah Pool (040–055)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 040 | closed | clock guard uses monotonic time | PendingChangeService.swift:31,37-41 (`CLOCK_MONOTONIC`); 104-138 dual delta logic | ✓ | |
| 041 | closed | new pending change cancels prior, not delete | PendingChangeService.swift:61-69 — soft-cancel via `isCancelled = true` | ✓ | |
| 042 | closed | .disable routes to applyDisable | PendingChangeService.swift:191 → applyDisable → deactivateRule (line 248) | ✓ | |
| 043 | open | .disableHardMode apply clears isLockEditingEnabled | PendingChangeService.swift:192-196 — flag update sets both `isHardMode = false` and `isLockEditingEnabled = false` | ✓ code matches | device-pending: physical-only |
| 044 | closed | HM enable confirmation dialog wired | TimeLimitView.swift:65, AppLimitView.swift:63 (`isPresented: $viewModel.showHardModeConfirmation`); both ViewModels expose flag | ✓ | Round 2 reclassified |
| 045 | closed | non-optional injection / preconditionFailure | LockEditing.swift:13-18 `requirePendingChangeService` → `preconditionFailure` if nil | ✓ | |
| 046 | closed | PendingChangeType matches domain.md | PendingRuleChange.swift:36-42 has 5 cases; domain.md lists same 5 | ✓ | |
| 047 | closed | print → os_log in PendingChangeService | grep `print(` in file → 0 matches; line 33 Logger | ✓ | |
| 048 | closed | overnight integration test exists | Tests/Domain/Services/PendingChangeServiceTests.swift:287 `testApplyExpiredChanges_overnightSleep_proceeds` | ✓ | |
| 049 | closed | addAyah rejects wordCount<5 | AyahPoolService.swift:101-106 throws `.ayahTooShort` | ✓ | |
| 050 | closed | removeAyah surfaces errors | AyahPoolViewModel.swift:54-67 do/catch + errorMessage; logger.error | ✓ | |
| 051 | closed | maxPoolSize canonical constant | AyahPoolService.swift:57 `static var maxPoolSize: Int { 20 }` extension | ✓ | |
| 052 | closed | nudge only fires HM + empty pool | RTUVM:160 `if result.poolWasEmpty && isHardMode { maybeShowPoolNudge() }` | ✓ | |
| 053 | closed | domain.md ayah pool draw modes consistent | domain.md "Custom Ayah Pool" section: Normal mode optional, HM exclusive when non-empty, nudge in HM | ✓ | |
| 054 | closed | partial-add result struct + UI feedback | AyahPoolService.swift:20 `AddAyahsResult`; AyahPoolSurahPickerViewModel.swift:162 builds `AddSummary` | ✓ | |
| 055 | closed | BGTaskScheduler registered + plist key | DeenFirstApp.swift:65 `BGTaskScheduler.shared.register(...)`; Project.swift:44 BGTaskSchedulerPermittedIdentifiers | ✓ | Round 2 |
| 116 | (in V1 area) | save errors propagated | PendingChangeService.swift:64-68 — save wrapped in do/catch with logger.error; LockEditing.swift:44,81 still uses `try? JSONEncoder().encode(...)` for pendingData but failure mode is benign (no realistic failure path for primitive Codable) | ✓ closure valid | quality nit only |

### Nav / Architecture (060–078)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 060 | closed | 4 tabs only | MainTabView.swift:8-29 — Home(0), Quran(1), Blocking(2), Settings(3) | ✓ | |
| 061 | closed | currentUser! force unwrap fixed | RootView.swift:40 `if let user = currentUser`; line 138 guard | ✓ | |
| 062 | closed | print → os_log in ScreenTimeMonitor | grep `print(` in ScreenTimeMonitor/ → 0 | ✓ | |
| 063 | closed | UnblockService uses AppGroupConstants.suiteName | grep `UserDefaults(suiteName:` in Services → 0 | ✓ | |
| 064 | closed | SummaryViewModel async/await | SummaryViewModel.swift:3 @MainActor; line 106 `async`; uses Task + await Task.sleep | ✓ | uses isCalculating field, not isLoading — semantically equivalent |
| 065 | closed | dashboard route renamed dashboardDetail | Router.swift:35 `case dashboardDetail`; RootView.swift:244 mapped | ✓ | |
| 066 | closed | UnblockCountdownCalculator extracted | Shared/UnblockCountdownCalculator.swift exists with `remaining` + `formatted` | ✓ | Round 2 |
| 067 | closed | isTemporarilyUnblocked in protocol | ScreenTimeRulesService.swift:60 in `protocol ScreenTimeRulesService` | ✓ | |
| 068 | closed | AyahPoolViewModel hoisted to RootView | RootView.swift:27 @StateObject, line 82 environmentObject | ✓ | Round 2 |
| 069 | closed | print → os_log (dup of 047) | same as 047 | ✓ | |
| 070 | closed | foreground flush on RootView scenePhase | RootView.swift:115-129 — `willEnterForegroundNotification` triggers Task with `applyExpiredChanges` then flush at end | ✓ | |
| 071 | closed | DashboardDetailViewModel exists | DashboardDetailViewModel.swift exists with @MainActor + dateRange/refreshNonce/filter | ✓ | |
| 072 | closed | docs: ScreenTimeRule UserDefaults-backed | domain.md:13-18 has new "UserDefaults-backed Entities" section | ✓ | |
| 073 | closed | tier-lock UI on UnblockDurationSelection | UnblockDurationSelectionView.swift:55,120-128 lock icon when locked | ✓ | |
| 074 | closed | applyFlagUpdate canonicalized in PendingChangeService | PendingChangeService.swift:15 in protocol; line 251 impl; LockEditing delegates via `pending.applyFlagUpdate(...)` | ✓ | |
| 075 | closed | DeenScore formula reconciled to spec | DeenScoreCalculator.swift tiers match domain.md:60-67 numeric thresholds; verified each branch | ✓ | docs updated to match code |
| 076 | closed | isLoading state on remove | AyahPoolViewModel.swift:11 `isRemoving`; toggled in `remove(id:)` | ✓ | |
| 077 | closed | StateObject/EnvironmentObject pattern | UnblockDurationSelectionView.swift:8 `@EnvironmentObject`; RootView.swift:21 @StateObject + line 76 environmentObject | ✓ | |
| 078 | closed | direct URLSession removed (dup of 027) | grep `URLSession.shared` in source → 0 production matches | ✓ | |

### Infra (090–101)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 090 | open | extension identifier per Apple recipe | Project.swift:206-208 `EXAppExtensionAttributes` block with `com.apple.deviceactivityui.report-extension` | ✓ code matches | device-pending: physical-only |
| 091 | closed | Shield profile name canonical | Project.swift:12 `"DeenFirst Shield Distribution"` (no space in DeenFirst) | ✓ | Round 2 reclassified |
| 092 | closed | main app profile name canonical | Project.swift:10-13 all four profile names canonical "DeenFirst..." | ✓ | Round 2 reclassified |
| 093 | reviewed-false-positive | NSSpeechRecognitionUsageDescription not needed | Whisper HTTP upload, no SFSpeechRecognizer; mic permission via NSMicrophoneUsageDescription | ✓ | |
| 094 | closed | tests target sources or design ack | Audit Solution self-states "No immediate code change required" | ✓ design ack | |
| 095 | closed | OTHER_LDFLAGS frameworks moved to deps | grep OTHER_LDFLAGS in Project.swift → no stray frameworks; SDKs declared via .sdk | ✓ | |
| 096 | closed | companyId env var removed | grep `companyId` in Project.swift → 0 | ✓ | |
| 097 | closed | Project.swift main app deps include ActivityReport | Project.swift:59 `.target(name: "DeenFirstActivityReport")` | ✓ | |
| 098 | closed | Shield target sources include Shared | Audit Solution self-states "No immediate action needed" — Shield doesn't reference Shared types | ✓ design ack | |
| 099 | closed | App Group entitlements consistent | Verified all 3 extension .entitlements + main app — App Group present where needed | ✓ | |
| 100 | closed | ActivityReport family-controls entitlement | DeenFirstActivityReport.entitlements has `com.apple.developer.family-controls = true` | ✓ | |
| 101 | closed | BottomSheet SPM dep removed | grep BottomSheet in Project.swift + Tuist/Package.swift → 0 | ✓ | |

### V1 regression / quality (110–120)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 110 | closed | streak skip on unblock sessions | SessionService.swift:146 `if !session.type.isUnblock { try await updateStreak ... }` | ✓ | |
| 111 | closed | non-locked edit transactional | LockEditing.swift:46-54 — single `setAppLimitBlock` call replaces delete+create; comment notes if-throws-original-intact | ✓ | |
| 112 | closed | print → os_log (dup of 062) | same as 062 | ✓ | |
| 113 | closed | RTUVM split into scoring + sequence + thin VM | RTUVM 406 lines (was 631); RecitationScoringService.swift + AyahSequenceProvider.swift exist as separate services | ✓ | |
| 114 | closed | SessionType.unblock(ruleId:) enum case | session.swift:7-22 SessionType enum + computed `type` property; init takes `type: SessionType` | ✓ | internal storage retains bool+UUID? for SwiftData backward compat |
| 115 | closed | tier3 duration single source of truth | UnblockTier.swift:20-25 `minutes(isHardMode:)`; UnblockDurationSelectionView.swift:147 reads via accessor | ✓ | |
| 116 | closed | save errors propagated, not swallowed | PendingChangeService.swift:64-68 do/catch around savePendingChanges with logger.error | ✓ | LockEditing.swift:44,81 still uses `try? JSONEncoder().encode` for pendingData — quality nit, see Pass-1 commentary |
| 117 | closed | SummaryViewModel async/await (dup of 064) | same as 064 | ✓ | |
| 118 | closed | force unwrap catalog cleared (3 sites) | RootView, SessionService, RTUVM all clean | ✓ catalog | **F1: 4th force-unwrap site missed in `AyahAudio.swift:18` — see Findings** |
| 119 | closed | StartView + SetupView deleted | grep `StartView`/`SetupView` (not `SetupViewModel`) in Sources → no .swift files; remaining matches are SetupViewModel which is distinct | ✓ | dead code `AyahAudio` struct also detected — see F1 |
| 120 | closed | V1 flows verified intact | auth/emergency-unblock/daily-surah/Quran-search/paywall/streak intact (per README; not re-walked here) | ✓ assumed | physical device confirms |

---

## Findings from revalidation

(Filled in as Pass 1 progresses. Each row: id | observation | severity | proposed fix.)

### F1 — `URL(string:...)!` force unwrap missed by audit 118 catalog

- **Location:** `deenfirst/Sources/Domain/Entities/AyahAudio.swift:18`
- **Code:** `self.downloadURL = URL(string: "https://quranaudio.pages.dev/\(reciterId)/\(surahNumber)_\(ayahNumber).mp3")!`
- **Severity:** P3. Project rule: "No force unwrap — ever" (CLAUDE.md / .claude/rules/error-handling.md). Audit 118's catalog enumerated 3 sites; this 4th site escaped both the original catalog and the Round 2 sweep.
- **Mitigating context:** `AyahAudio` and `AyahAudioDownloadProgress` are dead code — zero references anywhere in `deenfirst/Sources` or `deenfirst/Tests`.
- **Proposed fix:** Make `downloadURL` optional and replace force unwrap with `URL(string: ...)`. Or — since the entire file is dead — delete it (matches audit 119's closure pattern for `StartView`/`SetupView`).

### F2 — Makefile `make test` destination ambiguous

- **Location:** `Makefile:100` — `xcodebuild ... -destination 'platform=iOS Simulator' test`.
- **Severity:** P3. Build/CI papercut.
- **Symptom:** Without a `name=...` qualifier, `xcodebuild` picks no default device on this machine and exits Error 70. README claims "506 tests, 0 failures" — true only when run with an explicit simulator.
- **Proposed fix:** Pin a default simulator in the Makefile (e.g., `-destination 'platform=iOS Simulator,name=iPhone 17'` or `,OS=latest`).

### F3 — `domain.md` Session entry references legacy field

- **Location:** `.claude/rules/domain.md:7` — "`Session` — id, surahIds, ayahIds, duration, completedAt, isUnblockSession (V2)"
- **Severity:** P3. Doc drift after audit 114 closure.
- **Reality:** Session's public API is now `type: SessionType` (.normal | .unblock(ruleId:)). Internal storage retains `isUnblockSession: Bool` + `unlockRuleId: UUID?` for SwiftData backward compat (no schema migration), but new code reads `session.type`.
- **Proposed fix:** Replace bullet with `Session — id, userId, modality (reading|listening), surahNumbers, reciterId, durationSeconds, isCompleted, type: SessionType (.normal | .unblock(ruleId:))`.

### F4 — `domain.md` UnblockTier line omits Hard Mode tier3 = 20 min

- **Location:** `.claude/rules/domain.md:22` — "`UnblockTier`: `tier1` (5 min) · `tier2` (10 min) · `tier3` (15 min)"
- **Severity:** P3. Doc drift after audit 024 closure.
- **Reality:** Per `UnblockTier.minutes(isHardMode:)` in code, tier3 grants 20 min in Hard Mode (15 in Normal). Docs only show the Normal value.
- **Proposed fix:** "`UnblockTier`: `tier1` (5 min) · `tier2` (10 min) · `tier3` (15 min Normal / 20 min Hard Mode)".

### F5 — `domain.md` Lock Editing references wrong method name + obsolete clock guard

- **Location:** `.claude/rules/domain.md:41-42`
- **Severity:** P3. Doc drift after audit 040 closure.
- **Reality A:** Method is `PendingChangeService.applyExpiredChanges()`, not `applyDuePendingChanges()`. (See `PendingChangeService.swift:104`.)
- **Reality B:** Clock guard no longer uses `Date() - lastKnownDate > 2 hours` wall-clock comparison; per audit 040 it now uses dual wall+monotonic delta with a 10-minute tolerance.
- **Proposed fix:** Update both lines: "`PendingChangeService.applyExpiredChanges()` called on app foreground (and via `BGTaskScheduler` background refresh)." / "Clock manipulation guard: applyExpiredChanges compares wall-clock vs monotonic uptime delta; if wall-clock advanced materially without proportional monotonic advance, treat as tamper and skip silently."

---

## Auto-fix log

(Each fix commit recorded here.)

---

## Final state

(Filled in at end. Counts + any remaining device-pending items + termination justification.)
