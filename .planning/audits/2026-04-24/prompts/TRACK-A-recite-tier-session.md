# TRACK A — Recite / Tier / Session cluster

**Parallelizable with Tracks B, C, D, E.**
**Depends on:** Wave 1 merged to `main` (Dashboard + tab migration).
**Estimated time:** ~8 hours. Largest track.

---

## Copy-paste this prompt into the Track A session

You are implementing Track A of the 2026-04-24 audit remediation for the Deen First iOS app.

Read these before writing any code:
- `.claude/CLAUDE.md`
- `.claude/rules/domain.md`
- `.claude/rules/folder-structure.md`
- `.claude/rules/naming.md`
- `.claude/rules/error-handling.md`

Route implementation through the `deenfirst-ios` agent. After implementation is green, spawn `deenfirst-qa` for tests.

### What this track owns

This track fixes the ReciteToUnblock, UnblockDurationSelection, and Session domain. It's the biggest cluster — a 631-line god-object split, a SessionType enum migration that touches persistence, tier wiring, Hard Mode correctness, and Whisper extraction.

**Files you own (other tracks will NOT touch these):**
- `deenfirst/Sources/Presentation/ReciteToUnblock/**`
- `deenfirst/Sources/Presentation/UnblockDurationSelection/**`
- `deenfirst/Sources/Domain/Entities/session.swift`
- `deenfirst/Sources/Domain/Services/SessionService.swift`
- `deenfirst/Sources/Domain/Services/ScreenTimeRulesService+Unblock.swift`
- `deenfirst/Sources/Data/DataSource/API/WhisperAPIDataSource.swift` (NEW — create this)
- Any new service files you create under `deenfirst/Sources/Domain/Services/` for the 113 split

**Files you must NOT touch** (other tracks own them):
- `PendingChangeService.swift`, `ScreenTimeRulesService+LockEditing.swift` — Track B
- `AyahPoolService.swift`, `AyahPoolViewModel.swift`, `Presentation/AyahPool/**` — Track C
- `Project.swift`, `Tuist/Package.swift`, extension plists — Track D
- `HomeTabViewModel.swift`, `SummaryViewModel` — Track E

### Audits to implement

Read each audit file under `.planning/audits/2026-04-24/` before touching the relevant code. 20 findings total.

**Refactors (LAND THESE FIRST — everything else builds on them):**
- `113-recitetounblock-viewmodel-631-lines.md` (P2) — extract `RecitationScoringService` + `AyahSequenceProvider`; keep `ReciteToUnblockViewModel` as the state-machine coordinator only.
- `114-isunblocksession-bool-not-sessiontype-case.md` (P2) — migrate `Session.isUnblockSession: Bool + unlockRuleId: UUID?` to `SessionType.unblock(ruleId:)` enum case. Write a SwiftData lightweight migration if existing store has production data.

**Persistence + streak correctness (land after 114):**
- `028-isunblocksession-set-after-repository-save.md` (P1) — session type must be set BEFORE `repository.save()`, not after.
- `110-streak-incremented-on-unblock-session.md` (P1) — streak must NOT bump on `SessionType.unblock` sessions.
- `115-tier3-duration-duplicated-active-session-vm.md` (P2) — Tier 3 duration constant duplicated between `ActiveSessionViewModel` and `UnblockDurationSelectionViewModel`; single source of truth.

**Tier wiring + logic:**
- `020-tier-picker-dead-code.md` (P0) — `UnblockDurationSelectionView` is never navigated to; wire it into the live flow from BlockingTabView. The current dead `UnblockDurationSheet` tier-3 branch dies.
- `021-tier3-live-path-crashes.md` (P0) — `ayahCount` returns 0 in `UnblockDurationSheet`; fix or remove as part of 020.
- `022-progressive-tier-unlock-not-enforced.md` (P1) — user must complete a lower tier before the next tier is selectable.
- `023-max-3-tiers-not-implemented.md` (P1) — cap at 3 tiers per blocking session; after Tier 3 completes or all three used, no more retries.
- `026-accept-tier1-downgrade-wrong-index-check.md` (P1) — `acceptTier1Downgrade` checks `== 1` but fails for Hard Mode Tier 2 index 2.
- `073-unblockdurationselection-missing-tier-lock.md` (P1) — picker renders all 3 tier cards unconditionally; must lock based on progression.
- `077-unblockdurationselection-stateobject-not-environmentobject.md` (P3) — fix StateObject / EnvironmentObject inconsistency.
- `067-istemporarilyunblocked-not-in-protocol.md` (P2) — add `isTemporarilyUnblocked` to the service protocol.

**Hard Mode + copy:**
- `024-handlepass-ignores-hardmode-minutes.md` (P1) — `handlePass` must grant 20 minutes (not 15) for Hard Mode Tier 3.
- `025-awaiting-next-ayah-hardcoded-strings.md` (P1) — "Ayah 1 Complete" hardcoded; must render dynamically for HM Tier 2 (3 ayahs).

**Whisper extraction (replaces raw URLSession):**
- `027-callwhisperapi-uses-urlsession-and-force-unwrap.md` (P1) — extract into `WhisperAPIDataSource.swift` routed through `HTTPClient` (Alamofire wrapper).
- `078-recitetounblockviewmodel-direct-urlsession-call.md` (P1) — DUPLICATE of 027; one fix closes both.
- `118-force-unwrap-catalog.md` (P2) — remove force unwraps flagged in the catalog (most are in RTUVM and die with the 113 split).
- `093-speech-recognition-plist-key-missing.md` (P3) — demoted on re-verify; if plist already has `NSSpeechRecognitionUsageDescription`, close the audit with a note. If missing, add via Project.swift and coordinate with Track D before opening your PR.

**Constants + magic numbers (LIVE INSIDE RTUVM — do them here, not Track C):**
- `030-similarity-threshold-magic-numbers.md` (P2) — extract `0.70` and `0.85` into named constants at the top of the new `RecitationScoringService`.
- `051-max-pool-size-constant-triplicated.md` (P2) — `maxPoolSize = 20` appears in 3 places; the canonical constant lives in `AyahPoolService` (Track C owns that file). Your job here: READ it from `AyahPoolService` — do NOT modify AyahPoolService itself. If the constant is not yet exposed there, file a note in your PR for Track C to expose it; in the meantime, use the value via a local `private let maxPoolSize = AyahPoolService.maxPoolSize` or equivalent.

### Order of work

Commit at each logical slice with conventional-commit prefixes.

1. **Split the god-object (113).**
   - Create `deenfirst/Sources/Domain/Services/RecitationScoringService.swift` — protocol + `final class RecitationScoringServiceImpl`. Owns Whisper call + similarity calculation. Injected into RTUVM via DIContainer.
   - Create `deenfirst/Sources/Domain/Services/AyahSequenceProvider.swift` — protocol + impl. Owns pool-vs-standard selection + Hard Mode word-count filter (`wordCount >= 5`) + sequence building.
   - Register both in `DIContainer.shared`.
   - `ReciteToUnblockViewModel` becomes a thin state-machine coordinator: receives a scored result from `RecitationScoringService`, drives `UnblockTier` transitions, calls `ScreenTimeRulesService+Unblock` to grant.
   - Keep `processRecitationOutcome` as the public seam (existing `TieredUnblockIntegrationTests` already use this seam).
   - Commit: `refactor(recite): extract RecitationScoringService and AyahSequenceProvider (DF-113)`

2. **Whisper extraction (027 / 078 / 118).**
   - Create `deenfirst/Sources/Data/DataSource/API/WhisperAPIDataSource.swift` — protocol + impl, routed through `HTTPClient`. No raw `URLSession`. No force-unwrapped URLs. API key injected via existing pattern (check DIContainer for current key injection).
   - `RecitationScoringService` depends on `WhisperAPIDataSource` (not HTTPClient directly).
   - Remove every force unwrap listed in `118-force-unwrap-catalog.md`.
   - Commit: `refactor(recite): extract WhisperAPIDataSource and remove force unwraps (DF-027, DF-078, DF-118)`

3. **Session enum migration (114).**
   - On `Session` entity (`deenfirst/Sources/Domain/Entities/session.swift`): replace `isUnblockSession: Bool` + `unlockRuleId: UUID?` with `type: SessionType` where `SessionType` is:
     ```swift
     enum SessionType: Codable, Hashable {
         case normal
         case unblock(ruleId: UUID)
     }
     ```
   - Write a SwiftData lightweight migration if `modelContainer` uses a versioned schema; check `DIContainer.swift` for the schema definition.
   - Update `SessionService` and every call site.
   - Commit: `refactor(session): migrate isUnblockSession to SessionType enum (DF-114)`

4. **Persistence + streak + duration (028, 110, 115).**
   - 028: set `type` BEFORE `repository.save()` — not after.
   - 110: streak increment logic in `SessionService` must skip when `session.type` is `.unblock`.
   - 115: extract Tier 3 duration constant into a single source of truth (e.g., `UnblockTier.tier3.durationMinutes`); both `ActiveSessionViewModel` and `UnblockDurationSelectionViewModel` read from it.
   - Commit: `fix(session): correct persistence order, skip streak on unblock, dedupe tier3 duration (DF-028, DF-110, DF-115)`

5. **Tier wiring (020, 021).**
   - Wire `UnblockDurationSelectionView` into the live flow from BlockingTabView. The current dead `UnblockDurationSheet` tier-3 branch is deleted.
   - Fix the `ayahCount` crash for Tier 3 (or remove the crashing path as part of deleting the old sheet).
   - Commit: `fix(tier): wire UnblockDurationSelectionView into live flow, kill dead tier3 branch (DF-020, DF-021)`

6. **Tier rules (022, 023, 026, 073, 077, 067).**
   - 022: progressive unlock — disable Tier 2 until Tier 1 is completed; disable Tier 3 until Tier 2 is completed.
   - 023: 3-tier-per-session cap — track `usedTiers: Set<UnblockTier>` on the blocking session; after all three used or Tier 3 completes, no more retries until a fresh session.
   - 026: fix the index check in `acceptTier1Downgrade` so it works for HM Tier 2 index 2.
   - 073: tier picker renders cards with a locked/unlocked state based on progression.
   - 077: use the correct property wrapper pattern (`@StateObject` at the owner, `@EnvironmentObject` for children).
   - 067: add `var isTemporarilyUnblocked: Bool { get }` to the unblock service protocol.
   - Commit: `feat(tier): progressive unlock, 3-tier cap, correct index check, tier-lock UI (DF-022, DF-023, DF-026, DF-073, DF-077, DF-067)`

7. **Hard Mode (024, 025).**
   - 024: `handlePass` in HM grants 20 minutes at Tier 3, not 15. Verify the minutes table against `.claude/rules/domain.md`.
   - 025: dynamic ayah copy — for HM Tier 2 (3 ayahs), render "Ayah 1 Complete", "Ayah 2 Complete", etc. Remove the hardcoded string.
   - Commit: `fix(hard-mode): correct tier3 minutes and dynamic ayah copy (DF-024, DF-025)`

8. **Constants (030, 051).**
   - 030: extract `0.70` and `0.85` thresholds into named constants inside `RecitationScoringService`.
   - 051: replace every inline `20` with a read from `AyahPoolService.maxPoolSize`.
   - Commit: `refactor(recite): extract similarity thresholds and pool size constants (DF-030, DF-051)`

9. **Plist (093).** Verify `NSSpeechRecognitionUsageDescription` exists in the main-app Info.plist / Project.swift infoPlist block. If present → close audit with a note. If missing → you will need to coordinate with Track D (Project.swift owner). Either:
   - Wait for Track D to merge, rebase, verify, close; or
   - Open a small PR-comment on Track D's branch asking them to add it; or
   - Add it yourself to Project.swift and flag Track D in your PR description so they don't clobber.
   - Commit (if needed): `fix(recite): add NSSpeechRecognitionUsageDescription to main app plist (DF-093)`

### Rules

- `@MainActor final class` on every ViewModel.
- `RecitationScoringService` and `AyahSequenceProvider` are `final class`, accessed via `DIContainer.shared`, protocol-first for testability.
- No force unwraps anywhere in your diff.
- No completion handlers. async/await + do/catch only.
- Explicit `isLoading` + `errorMessage` on all async VM operations.
- `WhisperAPIDataSource` wraps `HTTPClient`, not raw `URLSession`.
- For the 114 migration: if production data exists, use SwiftData lightweight migration. Do NOT destructively replace the schema.

### Testing (delegate to `deenfirst-qa` after impl is green)

- Unit tests for `RecitationScoringService` with a mocked `HTTPClient`.
- Unit tests for `AyahSequenceProvider`: pool empty vs non-empty; Hard Mode word-count filter; sequence length for HM T1/T2/T3.
- State-machine tests for `ReciteToUnblockViewModel`: T1 → T2 → T3 progression, longer-wins, 3-tier cap, progressive unlock.
- Regression test for 110: streak does NOT increment on `SessionType.unblock`.
- Regression test for 028: session type is persisted before the VM exits the save path (survives a simulated crash between save and post-save code).
- Regression test for 024: HM Tier 3 grants 20 minutes.
- Regression test for 026: HM Tier 2 index 2 accepts the downgrade correctly.

### Verification before PR

- `make generate && make build && make test` all green.
- If Tier logic changed, run the `TieredUnblockIntegrationTests` suite locally and paste results in the PR description.

### PR

- Target: `main`.
- Title: `refactor(recite): track A — unblock/tier/session cluster (DF-020, 021, 022, 023, 024, 025, 026, 027, 028, 030, 051, 067, 073, 077, 078, 093, 110, 113, 114, 115, 118)`
- Describe: what moved where (113 split), the SessionType migration, and any coordination notes for Track D (if 093 required a Project.swift change).
