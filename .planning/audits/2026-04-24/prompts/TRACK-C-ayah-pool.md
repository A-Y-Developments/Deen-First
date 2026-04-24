# TRACK C — Ayah Pool cluster

**Parallelizable with Tracks A, B, D, E.**
**Depends on:** Wave 1 merged to `main`.
**Estimated time:** ~4 hours.

---

## Copy-paste this prompt into the Track C session

You are implementing Track C of the 2026-04-24 audit remediation for the Deen First iOS app.

Read these before writing any code:
- `.claude/CLAUDE.md`
- `.claude/rules/domain.md` — especially the Custom Ayah Pool business rules
- `.claude/rules/error-handling.md`
- `.claude/rules/naming.md`

Route implementation through the `deenfirst-ios` agent. After implementation is green, spawn `deenfirst-qa` for tests.

### What this track owns

This track fixes the Custom Ayah Pool feature end-to-end: eligibility rules, nudge logic, UX feedback on add/remove, and VM instantiation hygiene.

**Files you own (other tracks will NOT touch these):**
- `deenfirst/Sources/Domain/Services/AyahPoolService.swift`
- `deenfirst/Sources/Domain/Entities/AyahPoolItem.swift`
- `deenfirst/Sources/Presentation/AyahPool/**`

**Files you must NOT touch** (other tracks own them):
- `ReciteToUnblock/**` — Track A (audits 030 and 051 live there and are handled by Track A; you ONLY expose the canonical constant from AyahPoolService)
- `PendingChangeService.swift`, `LockEditing` — Track B
- `Project.swift` — Track D
- `HomeTabViewModel.swift`, `SummaryViewModel`, Shared helpers — Track E

### Audits to implement

Read each audit file under `.planning/audits/2026-04-24/` before touching the relevant code. 11 findings total.

- `029-showpoolnudge-never-reset.md` (P2) — the `showPoolNudge` flag is set but never reset after the user adds eligible ayahs.
- `031-poolnudgedatekey-hardcoded-inline.md` (P2) — the nudge date key is hardcoded inline; move to `AppGroupConstants`.
- `049-ayah-pool-add-does-not-reject-short-ayahs.md` (P1) — `addAyah` accepts `wordCount < 5` ayahs that are ineligible in Hard Mode (silent trap later).
- `050-ayah-pool-remove-swallows-errors.md` (P2) — `removeAyah` uses `try?`; errors vanish.
- `051-max-pool-size-constant-triplicated.md` (P2) — the `20` constant is triplicated across files. YOUR JOB: expose `static let maxPoolSize: Int = 20` on `AyahPoolService`. Track A will read it from here — do NOT edit RTUVM.
- `052-pool-nudge-fires-in-normal-mode.md` (P1) — nudge must only fire when `rule.isHardMode && pool.isEmpty`, not on `pool.isEmpty` alone.
- `053-domain-doc-pool-draw-mode-contradiction.md` (P3) — `.claude/rules/domain.md` contradicts itself on pool draw modes; reconcile.
- `054-partial-add-selected-no-partial-feedback.md` (P2) — when user adds N ayahs and only M succeed, UI gives no partial feedback.
- `068-viewmodel-instantiation-in-ayahpoolview.md` (P2) — `AyahPoolViewModel` is instantiated inside `AyahPoolView`'s body.
- `076-ayahpoolviewmodel-task-no-loading-state-on-remove.md` (P3) — no `isLoading` state during remove.
- `030-similarity-threshold-magic-numbers.md` — NOTE: listed for context but Track A owns this (thresholds live in RTUVM / the new RecitationScoringService). SKIP in this track.

### Order of work

Commit at each logical slice with conventional-commit prefixes.

1. **Eligibility at add time (049).** In `AyahPoolService.addAyah(...)`, validate `wordCount >= 5` before inserting. On rejection throw a typed error, e.g.:
   ```swift
   enum AyahPoolError: Error {
       case ayahTooShort(wordCount: Int, minimum: Int)
       case poolFull(max: Int)
   }
   ```
   The VM surfaces the rejection to the user (not a silent swallow).
   - Commit: `fix(ayah-pool): reject wordCount<5 on add (DF-049)`

2. **Expose canonical constant (051).** On `AyahPoolService` declare `static let maxPoolSize: Int = 20` at the top. Replace every inline `20` inside AyahPoolService / the pool view layer with `Self.maxPoolSize`. Enforce the cap inside the service with `AyahPoolError.poolFull(max: maxPoolSize)`. Track A will read `AyahPoolService.maxPoolSize` from RTUVM.
   - Commit: `refactor(ayah-pool): expose maxPoolSize as canonical constant (DF-051)`

3. **Nudge predicate (052).** In `AyahPoolViewModel` (or wherever `showPoolNudge` is decided), the predicate becomes `rule.isHardMode && pool.isEmpty`. If there are multiple rules, the nudge fires when ANY rule has `isHardMode == true` AND the pool is empty.
   - Commit: `fix(ayah-pool): nudge only in hard mode with empty pool (DF-052)`

4. **Reset nudge flag (029).** After the user successfully adds at least one eligible ayah, reset `showPoolNudge` to false. Store the flag via `AppGroupConstants.sharedDefaults` so it survives cross-process reads.
   - Commit: `fix(ayah-pool): reset showPoolNudge after successful add (DF-029)`

5. **AppGroupConstants key (031).** In `deenfirst/Sources/Shared/AppGroupConstants.swift`, add `static let poolNudgeDate = "com.aydev.deenfirst.poolNudgeDate"` (and any sibling keys the audit lists). Replace every inline literal with the constant. Follow naming convention from `.claude/rules/naming.md`.
   - Commit: `refactor(ayah-pool): move poolNudgeDateKey to AppGroupConstants (DF-031)`

6. **VM instantiation pattern (068).** Move `@StateObject var viewModel = AyahPoolViewModel(...)` OUT of the View body. Options:
   - Parent view creates the VM via a factory and passes it down as `@EnvironmentObject` or initializer injection.
   - Or: add an `AyahPoolViewFactory` in the same folder that builds the VM from `DIContainer.shared` and returns a fully-wired `AyahPoolView`.
   - Pick whichever matches the rest of `.claude/rules/folder-structure.md` — if other views use factories, follow that pattern.
   - Commit: `refactor(ayah-pool): move ViewModel instantiation out of View body (DF-068)`

7. **Loading state on remove (076).** Add `@Published var isRemoving = false` (or a per-item map) to `AyahPoolViewModel`. Set true before the await, false after. Surface via progress indicator in the row.
   - Commit: `feat(ayah-pool): loading state during remove (DF-076)`

8. **Remove errors (050).** In `AyahPoolViewModel.removeAyah`, replace `try?` with `do/catch`; on error set `errorMessage` for the user and log at `.error`.
   - Commit: `fix(ayah-pool): surface remove errors instead of swallowing (DF-050)`

9. **Partial-add feedback (054).** `AyahPoolService.addAyahs(_:)` returns a result struct:
   ```swift
   struct AddAyahsResult {
       let added: [AyahPoolItem]
       let rejected: [(surahNumber: Int, ayahNumberInSurah: Int, reason: AyahPoolError)]
   }
   ```
   VM renders a user-facing toast/banner: "Added 7 of 10. 3 ayahs rejected (too short)."
   - Commit: `feat(ayah-pool): partial-add UX feedback (DF-054)`

10. **Docs reconciliation (053).** Update `.claude/rules/domain.md` so the Custom Ayah Pool section says:
    - Normal mode: pool is optional; system falls back to standard ayah selection if pool is empty.
    - Hard mode: pool is exclusive when non-empty; if pool is empty in HM, nudge the user to add ayahs.
    Make the prose internally consistent. Coordinate with Track B on 046 (enum mismatch) and Track E on 072 (ScreenTimeRule docs) if they're editing domain.md concurrently — grep-check before committing to avoid stomping.
    - Commit: `docs(domain): reconcile ayah pool draw modes (DF-053)`

### Rules

- `AyahPoolService` is `final class`, accessed via `DIContainer.shared`.
- The `wordCount >= 5` eligibility rule lives in `AyahPoolService`. NOT inline in RTUVM, NOT inline in the View.
- Max 20 items enforced at service level via `maxPoolSize`.
- `@MainActor final class` on `AyahPoolViewModel`.
- `AppGroupConstants.suiteName` for every App Group read/write; never inline the group name.
- No `try?` unless the failure is genuinely P3 and you log it.

### Testing (delegate to `deenfirst-qa` after impl is green)

- Unit test: `addAyah` rejects `wordCount < 5` with `AyahPoolError.ayahTooShort`.
- Unit test: `addAyah` rejects when pool is full with `AyahPoolError.poolFull`.
- Unit test: `addAyahs` returns correct partial-add result on mixed input.
- Unit test: nudge predicate fires only when `rule.isHardMode && pool.isEmpty`.
- Unit test: `showPoolNudge` flag resets after a successful add.
- Unit test: remove surfaces error to `errorMessage` instead of swallowing.

### Verification before PR

- `make generate && make build && make test` all green.

### PR

- Target: `main`.
- Title: `fix(ayah-pool): track C — ayah pool cluster (DF-029, 031, 049, 050, 051, 052, 053, 054, 068, 076)`
- Describe: eligibility enforcement, nudge predicate, partial-add UX, VM pattern change.
