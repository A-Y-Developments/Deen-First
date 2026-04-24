# TRACK E — Quality sweep

**Parallelizable with Tracks A, B, C, D.**
**Depends on:** Wave 1 merged to `main`.
**Estimated time:** ~3 hours.

---

## Copy-paste this prompt into the Track E session

You are implementing Track E of the 2026-04-24 audit remediation for the Deen First iOS app.

Read these before writing any code:
- `.claude/CLAUDE.md`
- `.claude/rules/error-handling.md` — especially the ViewModel loading-state pattern
- `.claude/rules/folder-structure.md`
- `.claude/rules/naming.md`

Route implementation through the `deenfirst-ios` agent. After implementation is green, spawn `deenfirst-qa` for tests.

### What this track owns

This track is a sweep of small, independent quality fixes that don't belong to any other cluster. It touches many files lightly — avoid overlapping with Track A (ReciteToUnblock, Session), Track B (PendingChange, LockEditing), Track C (AyahPool), Track D (Project.swift, extensions).

**Files you own (lightly):**
- `deenfirst/Sources/Presentation/MainTabs/HomeTab/HomeTabViewModel.swift` — for 066 countdown dedup
- `deenfirst/Sources/Presentation/MainTabs/BlockingTab/BlockingTabViewModel.swift` — for 066 countdown dedup only
- `deenfirst/Sources/Presentation/MainTabs/OverviewTab/` — SummaryViewModel 064/117
- `deenfirst/Sources/Domain/Entities/ScreenTimeRule.swift` — for 035 isHardMode caching
- `deenfirst/Sources/Shared/DeenScoreCalculator.swift` — for 075 formula reconciliation (note: Wave 1 may have already touched this for 008 — rebase cleanly)
- `deenfirst/Sources/Shared/UnblockCountdownCalculator.swift` — NEW file for 066
- `deenfirst/Sources/Domain/Services/UnblockService.swift` — for 063 suite name only
- `.claude/rules/domain.md` — for 072 docs-only fix

**Files you must NOT touch:**
- `ReciteToUnblockViewModel.swift`, `Session`, `UnblockDurationSelection/**`, `ScreenTimeRulesService+Unblock.swift` — Track A
- `PendingChangeService.swift`, `ScreenTimeRulesService+LockEditing.swift` — Track B
- `AyahPoolService.swift`, `AyahPool/**` — Track C
- `Project.swift`, `Tuist/Package.swift`, `Extensions/**` — Track D
- `DashboardTabView`, `DashboardDetailView`, `DashboardSummaryCard` — Wave 1 shipped these; don't re-shape them here

### Audits to implement

Read each audit file under `.planning/audits/2026-04-24/` before touching the relevant code. 11 findings total.

- `005-overview-scene-unused-imports.md` (P3) — delete unused imports in the Overview scene.
- `007-quran-reading-no-background-handling.md` (P2) — Quran reading doesn't pause/resume on backgrounding; add `scenePhase` observer.
- `035-ishardmode-computed-property-no-cache.md` (P2) — `isHardMode` is a computed property re-evaluated on every read; cache as a stored property on the rule.
- `063-hardcoded-suitename-unblock-service.md` (P3) — `UnblockService` hardcodes the App Group suite name; replace with `AppGroupConstants.suiteName`.
- `064-dispatachqueue-completion-handler-summaryviewmodel.md` (P1)
- `117-summaryviewmodel-escaping-dispatchqueue.md` (P1) — DUPLICATE of 064. One fix closes both. Convert `SummaryViewModel` from `DispatchQueue` + `@escaping` completion handlers to async/await + `@MainActor final class`. Explicit `@Published isLoading` + `errorMessage` per error-handling.md.
- `066-countdown-logic-duplicated-home-blocking.md` (P2) — unblock countdown-to-expiry logic duplicated across `HomeTabViewModel` and `BlockingTabViewModel`. Extract to a pure helper in `Shared/`.
- `072-screentimerule-not-swiftdata.md` (P2) — **DOCS ONLY**. Update `.claude/rules/domain.md` to reflect that `ScreenTimeRule` is a `Codable struct` in App Group UserDefaults, NOT a SwiftData `@Model`. Do NOT migrate storage.
- `075-deenscoreformula-mismatch-spec.md` (P2) — reconcile `DeenScoreCalculator` implementation against the spec in `domain.md`: `clamp(50 + positives - negatives, 0, 100)`. If Wave 1's audit 008 already reconciled this, verify and close. If not, do the reconcile here; whichever side has the correct product intent wins (if unsure, default to the spec: rewrite code to match).

### Order of work

Commit at each logical slice with conventional-commit prefixes.

1. **SummaryViewModel async/await (064 / 117).** In `SummaryViewModel`:
   - Mark the class `@MainActor final class`.
   - Replace every completion handler with `async throws`.
   - Replace every `DispatchQueue.main.async { ... }` with direct property mutation (you're on the main actor already).
   - Add `@Published var isLoading = false` and `@Published var errorMessage: String?`.
   - Every async op follows the pattern in `.claude/rules/error-handling.md`: set `isLoading = true` + clear error → do/catch → set `isLoading = false`.
   - Update callers (views that pass completions) to `await` or use `Task { }` inside `onAppear` / button handlers.
   - Commit: `refactor(summary): migrate to async/await with explicit loading state (DF-064, DF-117)`

2. **Countdown dedup (066).** Create `deenfirst/Sources/Shared/UnblockCountdownCalculator.swift`:
   ```swift
   struct UnblockCountdownCalculator {
       static func remaining(expiresAt: Date, now: Date = Date()) -> TimeInterval { ... }
       static func formatted(remaining: TimeInterval) -> String { ... }
   }
   ```
   Pure static functions — no state, no side effects, no dependencies on SwiftData or network (so it's safe to live in `Shared/`). Replace the duplicated logic in `HomeTabViewModel` and `BlockingTabViewModel` with calls to this helper.
   - Commit: `refactor(countdown): extract UnblockCountdownCalculator to Shared (DF-066)`

3. **Deen Score formula (075).** First check whether Wave 1's 008 fix already landed the reconcile:
   ```
   git log --oneline main -- deenfirst/Sources/Shared/DeenScoreCalculator.swift
   ```
   - If Wave 1 fixed it: verify implementation matches `clamp(50 + positives - negatives, 0, 100)` from `domain.md`, and close 075 with a note in the PR.
   - If not: rewrite `DeenScoreCalculator` to the spec formula. Keep it pure (no SwiftData, no network — it's in `Shared/` for a reason). Add comments ONLY where a weight or coefficient needs explanation.
   - Commit (if code changed): `fix(deen-score): reconcile calculator to spec formula (DF-075)`

4. **isHardMode caching (035).** In `deenfirst/Sources/Domain/Entities/ScreenTimeRule.swift`: `isHardMode` is currently a computed property (the audit specifies where). Convert to a stored `Codable` property. Since `ScreenTimeRule` is a `Codable struct` in UserDefaults (see 072), add a custom `Decodable init` that defaults to `false` for legacy rules missing the field. Follow the existing V2-compatibility pattern that was used for `isLockEditingEnabled`.
   - Commit: `refactor(rule): cache isHardMode as stored property with backfill (DF-035)`

5. **Quran background handling (007).** In the Quran reading view (find via grep for `AVFoundation` or audio playback code), add:
   ```swift
   @Environment(\.scenePhase) private var scenePhase
   // .onChange(of: scenePhase) { _, phase in
   //     handleScenePhase(phase)
   // }
   ```
   On `.background`: pause any active recitation/playback. On `.active` return: restore state (resume paused playback if user had it playing, otherwise remain paused).
   - Commit: `fix(quran): pause/resume reading on background (DF-007)`

6. **Suite name constant (063).** In `UnblockService.swift`, replace the hardcoded suite name string with `AppGroupConstants.suiteName`.
   - Commit: `refactor(unblock): use AppGroupConstants.suiteName (DF-063)`

7. **Unused imports (005).** In the Overview scene file (audit lists the exact imports), remove unused `import` statements. Run `make build` to confirm nothing silently broke.
   - Commit: `chore(overview): remove unused imports (DF-005)`

8. **Docs update (072).** In `.claude/rules/domain.md`: find the "Core Entities (SwiftData @Model)" section. Move `ScreenTimeRule` out of that list. Add a new paragraph (or a "UserDefaults-backed Entities" subsection) explaining that `ScreenTimeRule` is a `Codable struct` persisted via App Group UserDefaults through `ScreenTimeRulesRepository`, because it needs cross-process access without SwiftData. Also note that `isHardMode` and `isLockEditingEnabled` are V2 fields added with a backward-compatible `Decodable` init.
   - COORDINATION: Track B (046) and Track C (053) may also be editing `domain.md`. Before committing, run `git pull` / rebase; if there's a conflict, hand-merge so all three doc updates coexist.
   - Commit: `docs(domain): clarify ScreenTimeRule is UserDefaults-backed, not SwiftData (DF-072)`

### Rules

- async/await only. No `DispatchQueue.main.async`. No `@escaping` completion handlers.
- `@MainActor final class` on every ViewModel you touch.
- Every async VM op sets explicit `isLoading` before/after per error-handling.md.
- `AppGroupConstants.suiteName` for every App Group access; never inline.
- Keep `Shared/` files pure — no SwiftData, no network, no `@Model`. `UnblockCountdownCalculator` and `DeenScoreCalculator` must remain importable by extension targets.
- 072 is DOCS-ONLY. Do NOT attempt a SwiftData migration of `ScreenTimeRule`.

### Testing (delegate to `deenfirst-qa` after impl is green)

- Unit test `SummaryViewModel`: loading state transitions (isLoading flips true → false), error path sets `errorMessage`, success path populates data.
- Unit test `UnblockCountdownCalculator.remaining` and `.formatted` with known inputs (30s, 5min, 1h, expired).
- Regression test for 110 / 028 (from Track A) is NOT your job — mention to QA if they ask.

### Verification before PR

- `make generate && make build && make test` all green.

### PR

- Target: `main`.
- Title: `refactor(quality): track E — quality sweep (DF-005, 007, 035, 063, 064, 066, 072, 075, 117)`
- Describe: list each audit and the file it touched; note any cross-track conflicts on `domain.md` (072, 046, 053) and how you resolved them.
