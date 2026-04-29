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

- Status: TBD (running)
- Output snippet: TBD

---

## Per-area verification log

Format per row: `id | claim from audit | verification (file:line or command) | result | notes`

### Dashboard (001–008)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 001 | open | extension product type → `.extensionKitExtension` + `EXAppExtensionAttributes` | TBD | | device-pending |
| 002 | open | DashboardDetailView wires all 5 contexts | TBD | | device-pending |
| 003 | open | weekly trend uses `.daily` over 7-day window | TBD | | device-pending |
| 004 | closed | Shared/ScreenTimeEvents extension-safe | TBD | | |
| 005 | closed | unused imports removed in Overview | TBD | | |
| 006 | closed | ZStack fallback ordering fixed | TBD | | |
| 007 | closed | Quran reading scenePhase observer | TBD | | |
| 008 | closed | Deen Score formula reconciled | TBD | | |

### Unblock / Hard Mode (020–035)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 020 | closed | UnblockDurationSelectionView wired into live flow | TBD | | |
| 021 | open | tier3 crash fixed; UnblockDurationSheet removed | TBD | | device-pending |
| 022 | closed | progressive tier unlock enforced | TBD | | |
| 023 | closed | max-3-tiers-per-session cap | TBD | | |
| 024 | closed | handlePass HM Tier3 grants 20min | TBD | | |
| 025 | closed | "Ayah N Complete" dynamic for HM Tier 2 | TBD | | Round 2 |
| 026 | closed | acceptTier1Downgrade index check fixed | TBD | | |
| 027 | closed | WhisperAPIDataSource via HTTPClient | TBD | | |
| 028 | closed | session.type set BEFORE repository.save | TBD | | |
| 029 | closed | showPoolNudge resets at start of loadRandomAyah | TBD | | Round 2 |
| 030 | closed | similarity thresholds named constants | TBD | | |
| 031 | closed | poolNudgeDateKey in AppGroupConstants | TBD | | |
| 032 | closed | UnblockTier moved to Domain/Entities | TBD | | Round 2 |
| 033 | closed | unblock sessions skip focus-session record | TBD | | Round 2 |
| 034 | closed | flame.fill SF Symbol replaces emoji | TBD | | Round 2 |
| 035 | closed | isHardModeSession snapshot at session start | TBD | | Round 2 |

### Lock Editing / Ayah Pool (040–055)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 040 | closed | clock guard uses monotonic time | TBD | | |
| 041 | closed | new pending change cancels prior, not delete | TBD | | |
| 042 | closed | .disable routes to applyDisable | TBD | | |
| 043 | open | .disableHardMode apply clears isLockEditingEnabled | TBD | | device-pending |
| 044 | closed | HM enable confirmation dialog wired | TBD | | Round 2 reclassified |
| 045 | closed | non-optional injection / preconditionFailure | TBD | | |
| 046 | closed | PendingChangeType matches domain.md | TBD | | |
| 047 | closed | print → os_log in PendingChangeService | TBD | | |
| 048 | closed | overnight integration test exists | TBD | | |
| 049 | closed | addAyah rejects wordCount<5 | TBD | | |
| 050 | closed | removeAyah surfaces errors | TBD | | |
| 051 | closed | maxPoolSize canonical constant | TBD | | |
| 052 | closed | nudge only fires HM + empty pool | TBD | | |
| 053 | closed | domain.md ayah pool draw modes consistent | TBD | | |
| 054 | closed | partial-add result struct + UI feedback | TBD | | |
| 055 | closed | BGTaskScheduler registered + plist key | TBD | | Round 2 |

### Nav / Architecture (060–078)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 060 | closed | 4 tabs only | TBD | | |
| 061 | closed | currentUser! force unwrap fixed | TBD | | |
| 062 | closed | print → os_log in ScreenTimeMonitor | TBD | | |
| 063 | closed | UnblockService uses AppGroupConstants.suiteName | TBD | | |
| 064 | closed | SummaryViewModel async/await | TBD | | |
| 065 | closed | dashboard route renamed dashboardDetail | TBD | | |
| 066 | closed | UnblockCountdownCalculator extracted | TBD | | Round 2 |
| 067 | closed | isTemporarilyUnblocked in protocol | TBD | | |
| 068 | closed | AyahPoolViewModel hoisted to RootView | TBD | | Round 2 |
| 069 | closed | print → os_log (dup of 047) | TBD | | |
| 070 | closed | foreground flush on RootView scenePhase | TBD | | |
| 071 | closed | DashboardDetailViewModel exists | TBD | | |
| 072 | closed | docs: ScreenTimeRule UserDefaults-backed | TBD | | |
| 073 | closed | tier-lock UI on UnblockDurationSelection | TBD | | |
| 074 | closed | applyFlagUpdate canonicalized in PendingChangeService | TBD | | |
| 075 | closed | DeenScore formula reconciled to spec | TBD | | |
| 076 | closed | isLoading state on remove | TBD | | |
| 077 | closed | StateObject/EnvironmentObject pattern | TBD | | |
| 078 | closed | direct URLSession removed (dup of 027) | TBD | | |

### Infra (090–101)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 090 | open | extension identifier per Apple recipe | TBD | | device-pending |
| 091 | closed | Shield profile name canonical | TBD | | Round 2 reclassified |
| 092 | closed | main app profile name canonical | TBD | | Round 2 reclassified |
| 093 | reviewed-false-positive | NSSpeechRecognitionUsageDescription not needed | TBD | | |
| 094 | closed | tests target sources or design ack | TBD | | Round 2 reclassified |
| 095 | closed | OTHER_LDFLAGS frameworks moved to deps | TBD | | |
| 096 | closed | companyId env var removed | TBD | | |
| 097 | closed | Project.swift main app deps include ActivityReport | TBD | | |
| 098 | closed | Shield target sources include Shared | TBD | | |
| 099 | closed | App Group entitlements consistent | TBD | | |
| 100 | closed | ActivityReport family-controls entitlement | TBD | | |
| 101 | closed | BottomSheet SPM dep removed | TBD | | |

### V1 regression / quality (110–120)

| id | status | claim | verification | result | notes |
|---|---|---|---|---|---|
| 110 | closed | streak skip on unblock sessions | TBD | | |
| 111 | closed | non-locked edit transactional | TBD | | |
| 112 | closed | print → os_log (dup of 062) | TBD | | |
| 113 | closed | RTUVM split into scoring + sequence + thin VM | TBD | | |
| 114 | closed | SessionType.unblock(ruleId:) enum case | TBD | | |
| 115 | closed | tier3 duration single source of truth | TBD | | |
| 116 | closed | save errors propagated, not swallowed | TBD | | |
| 117 | closed | SummaryViewModel async/await (dup of 064) | TBD | | |
| 118 | closed | force unwrap catalog cleared | TBD | | Round 2 |
| 119 | closed | StartView + SetupView deleted | TBD | | |
| 120 | closed | V1 flows verified intact | TBD | | |

---

## Findings from revalidation

(Filled in as Pass 1 progresses. Each row: id | observation | severity | proposed fix.)

---

## Auto-fix log

(Each fix commit recorded here.)

---

## Final state

(Filled in at end. Counts + any remaining device-pending items + termination justification.)
