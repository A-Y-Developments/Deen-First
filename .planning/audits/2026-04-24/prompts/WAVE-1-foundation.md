# WAVE 1 — Foundation: Dashboard rendering + 5→4 tab migration

**SERIAL. Must merge to `main` before any Wave 2 track starts.**

**Estimated time:** 4–6 hours.
**Depends on:** Wave 0 committed.
**Blocks:** Every Wave 2 track (they all touch or neighbor files this wave restructures).

---

## Copy-paste this prompt into the Wave 1 session

You are implementing Wave 1 of the 2026-04-24 audit remediation for the Deen First iOS app. Read `.claude/CLAUDE.md`, `.claude/rules/domain.md`, `.claude/rules/folder-structure.md`, and `.claude/rules/naming.md` before writing code.

Wave 0 is already committed on `main` (Project.swift fix). PrimaryButton.swift is still dirty in the working tree — you will commit it as part of this wave.

Wave 1 restructures navigation (5 tabs → 4 tabs, Dashboard moves onto Home as a summary card pushing to a detail screen) AND fixes the remaining Dashboard rendering bugs AND cleans up RootView while we're there. Every Wave 2 track depends on these files being stable.

Route implementation through the `deenfirst-ios` agent. Route tests through `deenfirst-qa` after implementation is green. No infra/Tuist changes needed (no new targets — Dashboard detail is not an extension).

### Scope

Read each audit file under `.planning/audits/2026-04-24/` before touching the relevant code:

**Dashboard rendering (4 findings):**
- `002-dashboard-single-context.md` (P0) — DashboardTabView passes only `"DeenScore"` context; wire ALL five: `DeenScore`, `ScreenTimeOverview`, `QuranEngagementToday`, `QuranVsScreenTime`, `WeeklyTrend`.
- `003-weekly-filter-segment-type.md` (P0) — WeeklyTrend uses `.weekly(during:)` (1 segment); rebuild filter to produce 7 daily segments.
- `006-fallback-zstack-ordering.md` (P2) — ZStack fallback order wrong.
- `008-deen-score-formula-doc-mismatch.md` (P2) — reconcile DashboardTabView / DeenScoreCalculator / domain.md.

**Tab migration (3 findings + 1 design doc):**
- `060-five-tab-nav-deviation.md` (P1) — 5 tabs rendered; must become 4.
- `065-dashboard-route-is-dead.md` (P2) — `.dashboard` route has zero call sites and nests a NavigationStack.
- `071-dashboard-tab-no-viewmodel.md` (P2) — DashboardTabView has no ViewModel.
- `MIGRATION-dashboard-to-home.md` — the 10-step design doc. EXECUTE THIS.

**Batched in because we're editing RootView anyway (2 findings):**
- `061-force-unwrap-root-view.md` (P1) — `currentUser!` at RootView.swift:40.
- `070-rootview-lifecycle-missing-foreground-flush.md` (P2) — missing `.applyDuePendingChanges()` on foreground.

**Dead code (1 finding):**
- `119-dead-code-startview-setupview.md` (P3) — delete `StartView.swift` and `SetupView.swift` after grep confirms zero call sites.

**UI polish (uncommitted working-tree change):**
- Commit `deenfirst/Sources/Presentation/Components/PrimaryButton.swift` as a separate commit.

### Order of work

Do these in order. Commit at each logical slice.

1. **Dashboard contexts fix (002).** In `DashboardTabView.swift`, replace the single-context `DeviceActivityReport` with five calls (one per context) OR a `ForEach` over a `[DeviceActivityReport.Context]` array. Context names must match the strings registered in `DeenFirstActivityReportExtension` / `DeenFirstActivityReportScene`. Verify with a grep on those files before typing context names.
   Commit: `fix(dashboard): wire all five DeviceActivityReport contexts (DF-002)`

2. **Weekly filter (003).** The Weekly Trend scene expects 7 daily segments. Build a `DeviceActivityFilter` whose segment interval is `.daily` across a 7-day window. Do NOT use `.weekly(during:)` — that produces 1 segment. Confirm by reading the scene's expected input type.
   Commit: `fix(dashboard): weekly trend renders 7 daily segments (DF-003)`

3. **ZStack + formula (006, 008).** Fix fallback ordering in the ZStack per audit 006. For 008, the formula in domain.md is canonical: `clamp(50 + positives - negatives, 0, 100)`. If `DeenScoreCalculator.swift` is a tiered step-function, rewrite to match the spec. Update DashboardTabView copy if any values are hardcoded.
   Commit: `fix(dashboard): zstack fallback order + deen score formula reconciliation (DF-006, DF-008)`

4. **Tab migration steps 1–2 (MIGRATION doc).** Create three new files (flat — no inner NavigationStack in the detail view):
   - `deenfirst/Sources/Presentation/Dashboard/DashboardDetailView.swift`
   - `deenfirst/Sources/Presentation/Dashboard/DashboardDetailViewModel.swift` — `@MainActor final class`, exposes `dateRange`, `refreshNonce`, `filter`, driven by pull-to-refresh.
   - `deenfirst/Sources/Presentation/Components/DashboardSummaryCard.swift` — reads Deen Score + today's quick stats from `AppGroupConstants.sharedDefaults`; tap → `router.navigate(to: .dashboardDetail)`.
   Design choices (apply as defaults unless you find a blocker):
   - `DashboardSummaryCard` reads App Group directly, NOT via `DeviceActivityReport` (simpler; avoids extension crash risk).
   - `HomeTabViewModel` computes Deen Score on-demand using `calculateDeenScore()` from `Shared/`.
   - Pull-to-refresh on `DashboardDetailView` increments `refreshNonce` (same behavior as current DashboardTabView).
   Commit: `feat(dashboard): add DashboardDetailView, DashboardDetailViewModel, DashboardSummaryCard (DF-071)`

5. **Tab migration steps 3–4.** Modify `HomeTabView.swift` — insert a new `dashboardSummarySection` between `heroSection` and `dailySurahSection`. Modify `HomeTabViewModel.swift` — add `@Published var deenScore: Int`, `@Published var todayFocusSessions: Int`, `@Published var todayRecitationsPassed: Int`. These are synchronous UserDefaults reads via `AppGroupConstants.sharedDefaults`.
   Commit: `feat(home): add dashboard summary card section (DF-060)`

6. **Tab migration steps 5–7.** Update:
   - `Router.swift` — remove `case dashboard`, add `case dashboardDetail`.
   - `RootView.swift` — update `destinationView(for:)`: `case .dashboardDetail: DashboardDetailView().toolbar(.hidden, for: .tabBar)`.
   - `MainTabView.swift` — remove the Dashboard tab (currently tag 3), reindex Settings from tag 4 to tag 3. Home stays 0, Quran stays 1, Blocking stays 2.
   Verify: `grep -rn "\.dashboard" deenfirst/Sources` returns zero call sites for the old route before renaming.
   Commit: `refactor(nav): remove dashboard tab, rename route to dashboardDetail (DF-060, DF-065)`

7. **Tab migration steps 8–10.** Delete `deenfirst/Sources/Presentation/MainTabs/DashboardTab/DashboardTabView.swift` and the `DashboardTab/` folder. Run `make generate` — no Tuist changes needed (no new targets). Update any test files referencing `Router.Route.dashboard`.
   Commit: `chore(nav): delete DashboardTab folder (DF-060)`

8. **RootView hygiene (061, 070).** While RootView is open:
   - Replace `currentUser!` with a safe unwrap — early return to onboarding if nil, per existing patterns in the codebase.
   - Add a `.onChange(of: scenePhase)` observer: when entering `.active`, call `DIContainer.shared.pendingChangeService.applyDuePendingChanges()` (async, inside `Task { }`).
   Commit: `fix(root-view): safe user unwrap + foreground pending-change flush (DF-061, DF-070)`

9. **Dead code (119).** Confirm with grep that `StartView` and `SetupView` have zero usages. Delete both files. Run `make generate`.
   Commit: `chore(cleanup): delete dead StartView and SetupView (DF-119)`

10. **PrimaryButton polish (uncommitted WT).**
    Commit: `chore(ui): primary button polish`

### Delegation

- Code: `deenfirst-ios` agent.
- Tuist or entitlement blockers: `deenfirst-infra` (shouldn't be needed in Wave 1 — flag me if it is).
- Tests after impl is green: `deenfirst-qa` — add:
  - Unit test for `DashboardDetailViewModel` (date range transitions, refreshNonce increments).
  - Unit test for `HomeTabViewModel` Deen Score computation (pure function, deterministic).
  - UI smoke test: tapping DashboardSummaryCard pushes DashboardDetailView.

### Rules

- `@MainActor final class` on every ViewModel.
- All service access via `DIContainer.shared`.
- No force unwrap.
- async/await + do/catch. No completion handlers, no DispatchQueue.main.async.
- `AppGroupConstants.suiteName` for App Group reads — never inline the group name string.
- `DashboardDetailView` is FLAT — no inner NavigationStack (it's pushed into the outer one from RootView).
- DashboardSummaryCard reads are synchronous UserDefaults — no async wrapping.

### Verification before PR

- `make generate && make build && make test` all green.
- **Physical device check required.** DeenFirstActivityReport extension cannot be tested on simulator. On device, confirm:
  - Home tab shows DashboardSummaryCard with real values.
  - Tapping the card pushes DashboardDetailView with all 5 DeviceActivityReport contexts rendering real data (not phantom zero bars).
  - Weekly Trend shows 7 daily bars, not 1.
  - 4 tabs rendered (Home, Quran, Blocking, Settings). Settings responds at tab index 3.
- Document device verification in PR description.

### PR

- Target: `main`.
- Title: `feat(dashboard): wave 1 foundation — 5→4 tabs + dashboard contexts (DF-002, 003, 006, 008, 060, 061, 065, 070, 071, 119)`
- Block Wave 2 from starting until this merges.
