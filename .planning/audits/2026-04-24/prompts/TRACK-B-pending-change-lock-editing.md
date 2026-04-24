# TRACK B — PendingChange / LockEditing cluster

**Parallelizable with Tracks A, C, D, E.**
**Depends on:** Wave 1 merged to `main`.
**Estimated time:** ~6 hours.

---

## Copy-paste this prompt into the Track B session

You are implementing Track B of the 2026-04-24 audit remediation for the Deen First iOS app.

Read these before writing any code:
- `.claude/CLAUDE.md`
- `.claude/rules/domain.md` — especially the Lock Editing + Hard Mode business rules
- `.claude/rules/error-handling.md`
- `.claude/rules/naming.md`

Route implementation through the `deenfirst-ios` agent. After implementation is green, spawn `deenfirst-qa` for tests.

### What this track owns

This track fixes the Lock Editing + Pending Change system (the 24-hour delayed-apply mechanism) plus Hard Mode's entanglement with Lock Editing — currently a silent trap that data-loses user rules and locks users into a 48-hour exit path without disclosure.

**Files you own (other tracks will NOT touch these):**
- `deenfirst/Sources/Domain/Services/PendingChangeService.swift`
- `deenfirst/Sources/Domain/Services/ScreenTimeRulesService+LockEditing.swift`
- `deenfirst/Sources/Domain/Entities/PendingRuleChange.swift`
- The Hard Mode confirmation dialog in `deenfirst/Sources/Presentation/MainTabs/BlockingTab/` (audit 044)

**Files you must NOT touch** (other tracks own them):
- `ReciteToUnblock/**`, `UnblockDurationSelection/**`, `Session`, `SessionService` — Track A
- `AyahPoolService.swift`, `AyahPool/**` — Track C
- `Project.swift` — Track D (see coordination note for BGTaskScheduler below)
- `HomeTabViewModel.swift`, `SummaryViewModel`, `DeenScoreCalculator` — Track E

### Audits to implement

Read each audit file under `.planning/audits/2026-04-24/` before touching the relevant code. 13 findings total.

**Data-loss / correctness (highest priority):**
- `042-disable-and-delete-pending-types-identical-behavior.md` (P1) — pending `.disable` type incorrectly calls `applyDelete`, permanently deleting rules the user only wanted disabled.
- `043-disable-hardmode-pending-apply-doesnt-clear-lock.md` (P1) — when `disableHardMode` pending applies, `isLockEditingEnabled` stays true.
- `044-hardmode-force-enables-lock-editing-silently.md` (P1) — enabling Hard Mode silently force-enables Lock Editing with zero UX disclosure.
- `111-non-locked-edit-data-loss-window.md` (P1) — non-locked edit does `try? deleteAppLimit` then creates a new rule; any failure leaves the user with no blocking rule and no error.
- `116-pending-change-save-errors-swallowed.md` (P2) — `try?` on save hides failures.

**Clock / lifecycle:**
- `040-clock-jump-guard-fires-overnight.md` (P1) — clock-jump guard fires on normal overnight sleep (8h+); pending changes may never apply.
- `041-create-pending-change-hard-deletes-previous.md` (P2) — creating a new pending change hard-deletes the prior one instead of cancelling.
- `055-no-background-task-for-pending-apply.md` (P2) — no `BGTaskScheduler` registration for pending-apply; only fires on foreground.

**Logging / hygiene:**
- `045-pending-change-service-optional-injection-silent-fail.md` (P2) — optional dependency injection silently no-ops.
- `046-pending-change-type-enum-mismatch-domain-docs.md` (P3) — `PendingChangeType` cases don't match `.claude/rules/domain.md`.
- `047-pending-change-service-mixed-logging.md` (P2) — mix of `print` and `os_log`.
- `069-pending-change-service-print-not-oslog.md` (P3) — DUPLICATE of 047 for the remaining `print()` calls.
- `074-applyflagudate-duplicated-pendingchange-lockEditing.md` (P2) — `applyFlagUpdate` helper duplicated across `PendingChangeService` and `ScreenTimeRulesService+LockEditing`; canonicalize in `PendingChangeService`.

**Tests:**
- `048-pending-change-overnight-test-missing.md` (P2) — integration test for overnight sleep case; delegate to `deenfirst-qa` after 040 lands.

### Order of work

Commit at each logical slice with conventional-commit prefixes.

1. **Data-loss fix #1 (042).** In `PendingChangeService.applyDuePendingChanges()` (or equivalent dispatch function), `.disable` must route to `applyDisable`, not `applyDelete`. Verify the handler table is correct and the two types have distinct behavior.
   - Commit: `fix(pending-change): .disable routes to applyDisable, not applyDelete (DF-042)`

2. **Data-loss fix #2 (111).** In `ScreenTimeRulesService+LockEditing` (or the non-locked edit path — find it by grep), replace `try? deleteAppLimit` followed by `create` with a transactional update: either `SwiftData context.transaction { }` around update-in-place, or `ManagedSettingsStore` `clear()` + `replace()` atomically. If the update fails, the original rule must remain intact. Never swallow the error.
   - Commit: `fix(lock-editing): non-locked edit becomes transactional update (DF-111)`

3. **Clock guard rework (040).** The current guard compares wall-clock `Date() - lastKnownDate`; this fires during normal overnight sleep. Rework to use monotonic time (`ProcessInfo.processInfo.systemUptime` delta or `CLOCK_MONOTONIC` via `clock_gettime`) as the primary signal:
   - Device slept but wall clock unchanged → apply normally.
   - Wall clock jumped AND monotonic uptime did not advance → real tamper, log + skip silently (P3 per error-handling.md).
   - Wall clock jumped AND monotonic uptime advanced proportionally → benign; apply.
   - Commit: `fix(pending-change): use monotonic time to distinguish sleep from tamper (DF-040)`

4. **Hard Mode entanglement (043 + 044).** Do these together:
   - 043: in the apply path for `.disableHardMode`, also clear `isLockEditingEnabled` on the target rule.
   - 044: when the user enables Hard Mode, present a confirmation dialog disclosing that Lock Editing will auto-enable. Use an existing `ConfirmationDialog` component if one exists; otherwise build a minimal `.confirmationDialog` modifier in the Blocking tab HM toggle view. User must explicitly confirm before HM enables (and LE auto-enables).
   - Commit: `fix(hard-mode): disclose LE auto-enable on enable; clear LE on disable (DF-043, DF-044)`

5. **Canonicalize `applyFlagUpdate` (074).** Single `applyFlagUpdate(rule:flag:value:)` in `PendingChangeService`. `ScreenTimeRulesService+LockEditing` delegates via `DIContainer.shared.pendingChangeService`.
   - Commit: `refactor(pending-change): deduplicate applyFlagUpdate (DF-074)`

6. **Hygiene sweep (045, 046, 047, 069, 116, 041).**
   - 045: make `PendingChangeService` dependencies non-optional. If a required dependency is nil, crash loudly in debug via `preconditionFailure`. No silent no-op paths.
   - 046: reconcile `PendingChangeType` cases with `.claude/rules/domain.md`. Either update the enum OR update the rules file — pick whichever matches product intent; align with Track E if 072 is also editing docs.
   - 047 + 069: convert every remaining `print()` in `PendingChangeService` to `os_log` using `Logger(subsystem: "com.aydev.deenfirst", category: "PendingChange")`.
   - 116: stop swallowing save errors — propagate via `throws` or log at `.error` level.
   - 041: creating a new pending change for the same target should cancel the prior one (mark `isCancelled = true`), not hard-delete it. Keeps history auditable.
   - Commit: `refactor(pending-change): hygiene sweep — logging, injection, errors, cancellation (DF-041, DF-045, DF-046, DF-047, DF-069, DF-116)`

7. **Background task (055).** Register a `BGTaskScheduler` identifier `com.aydev.deenfirst.pending-apply` in the main app. The handler calls `PendingChangeService.applyDuePendingChanges()`.
   - The task HANDLER lives in this branch (main app registration call + handler body).
   - The Info.plist identifier registration lives in `Project.swift`, which Track D owns. COORDINATION:
     - If Track D's PR merges first: rebase, confirm identifier present, done.
     - If this PR opens first: add a section to your PR description titled "Track D coordination" listing the required Info.plist addition: `BGTaskSchedulerPermittedIdentifiers: [com.aydev.deenfirst.pending-apply]`. Do NOT edit Project.swift yourself.
   - Commit: `feat(pending-change): register background task handler (DF-055)`

### Rules

- `PendingChangeService` is `final class`, accessed via `DIContainer.shared`.
- No `try?` that silently discards. If it fails, propagate or log at `.error`.
- Clock guard misfires are P3 per error-handling.md — log and skip; never surface to user.
- BGTaskScheduler identifier naming follows `.claude/rules/naming.md` convention (`com.aydev.deenfirst.<purpose>`).
- Never touch `Project.swift` in this track.
- Never touch `AppLimitConfig` or `ManagedSettingsStore` code outside the files you own.
- When in doubt about the Hard Mode dialog UX, default to the pattern in `.claude/rules/domain.md` § Hard Mode.

### Testing (delegate to `deenfirst-qa` after impl is green)

- 048 overnight integration test: simulate >8h elapsed wall-clock + proportional monotonic advance → apply fires.
- 040 tamper test: simulate wall-clock jump + no monotonic advance → apply skips silently.
- 042 regression: `.disable` pending applies disable, not delete.
- 111 regression: simulated `deleteAppLimit` failure → original rule preserved, user sees error.
- 043/044 regression: full HM on-then-off cycle → `isLockEditingEnabled` ends false.
- 041 regression: new pending change cancels prior one (both persist in store, prior is `isCancelled = true`).

### Verification before PR

- `make generate && make build && make test` all green.
- Run the new overnight integration test locally and paste results in PR description.

### PR

- Target: `main`.
- Title: `fix(pending-change): track B — lock editing + pending change cluster (DF-040, 041, 042, 043, 044, 045, 046, 047, 048, 055, 069, 074, 111, 116)`
- Describe: data-loss fixes, the Hard Mode dialog, and the Track D coordination note for BGTaskScheduler if the Info.plist change isn't yet in Track D's PR.
