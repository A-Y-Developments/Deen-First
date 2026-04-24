# MIGRATION: Dashboard → Home Tab (5 tabs → 4 tabs)

## Current State

`MainTabView.swift` renders 5 tabs:
- 0: Home (`HomeTabView`)
- 1: Quran (`QuranTabView`)
- 2: Blocking (`BlockingTabView`)
- 3: Dashboard (`DashboardTabView`) ← to remove
- 4: Settings (`SettingsTabView`) ← becomes tag 3

`HomeTabView` sections: `heroSection` · `dailySurahSection` · `activeBlocksSection`

`DashboardTabView` renders a `DeviceActivityReport` widget (DeenScore context) with a date range picker (Today / This Week) and a pull-to-refresh nonce.

Router has a `.dashboard` route that pushes `DashboardTabView()` — currently dead (no call sites) and creates a nested NavigationStack.

---

## Desired State

4 tabs: Home · Quran · Blocking · Settings

Dashboard content lives on **Home tab** as a summary card. Tapping the card navigates to a full dashboard detail screen via the Router.

---

## Recommended Home Tab Layout (top → bottom)

```
┌──────────────────────────────────┐
│  heroSection                     │  greeting + streak + Start Focus Session
├──────────────────────────────────┤
│  DashboardSummaryCard            │  Deen Score ring + today's quick stats
│  (new)                           │  "View Full Dashboard →" tap target
├──────────────────────────────────┤
│  dailySurahSection               │  (unchanged)
├──────────────────────────────────┤
│  activeBlocksSection             │  (unchanged)
└──────────────────────────────────┘
```

`DashboardSummaryCard` shows:
- Deen Score value (read from `AppGroupConstants.streakCurrentKey` + today's session data)
- 2–3 quick stats: Focus sessions today · Recitations passed · Streak
- Tap → `router.navigate(to: .dashboardDetail)`

---

## Router Changes

Replace dead `.dashboard` route with `.dashboardDetail`:

```swift
// Remove:
case dashboard

// Add:
case dashboardDetail
```

In `RootView.destinationView(for:)`:
```swift
case .dashboardDetail:
    DashboardDetailView()
        .toolbar(.hidden, for: .tabBar)
```

---

## Files to ADD

| File | Purpose |
|---|---|
| `Presentation/Components/DashboardSummaryCard.swift` | Summary card for Home tab |
| `Presentation/Dashboard/DashboardDetailView.swift` | Full dashboard push destination (no inner NavigationStack) |
| `Presentation/Dashboard/DashboardDetailViewModel.swift` | ViewModel for detail view (date range, refreshNonce, filter) |

Note: `DashboardDetailView` replaces `DashboardTabView` for the push case. It must NOT contain a `NavigationStack` (it's pushed into the outer one from `RootView`).

---

## Files to MODIFY

| File | Change |
|---|---|
| `MainTabView.swift` | Remove `DashboardTabView` tab (tag 3), reindex Settings to tag 3 |
| `HomeTabView.swift` | Add `dashboardSummarySection` between `heroSection` and `dailySurahSection` |
| `HomeTabViewModel.swift` | Add `deenScore: Int` and today's quick stats (read from App Group via `AppGroupConstants.sharedDefaults`) |
| `Router.swift` | Replace `.dashboard` with `.dashboardDetail` |
| `RootView.swift` | Update `destinationView` case |

---

## Files to DELETE

| File | Reason |
|---|---|
| `Presentation/MainTabs/DashboardTab/DashboardTabView.swift` | Replaced by `DashboardDetailView` + `DashboardSummaryCard` |

The `DashboardTab/` folder can be removed entirely. Move any reusable filter logic to `DashboardDetailViewModel`.

---

## Cascade Impact

### DIContainer
No changes needed. `DashboardDataWriter` and `DeenScoreCalculator` are already registered/accessible.

### HomeTabViewModel
Add computed properties reading from `AppGroupConstants.sharedDefaults`:
- `var deenScore: Int` — calls `calculateDeenScore(...)` with today's stored metrics
- `var todayFocusSessions: Int`
- `var todayRecitationsPassed: Int`

These are synchronous reads from UserDefaults — no async needed.

### Tab Indexing
`MainTabView.swift` uses `selectedTab: Int` and the closures `onViewAllSurahs` (tab 1) and `onViewAllBlocks` (tab 2) in `HomeTabView`. No index changes needed — Quran stays 1, Blocking stays 2.

Settings moves from tag 4 → tag 3 (no functional impact; just update the `.tag(3)` and `.tag(4)` values).

### Router `.dashboard` callers
`grep -rn "\.dashboard"` in Sources — currently zero call sites. Safe to rename to `.dashboardDetail` without breaking any existing navigation.

---

## Migration Steps (ordered)

1. Create `DashboardDetailView.swift` + `DashboardDetailViewModel.swift` (flat, no NavigationStack)
2. Add `DashboardSummaryCard.swift` component
3. Update `HomeTabView` to include `dashboardSummarySection`
4. Update `HomeTabViewModel` to expose Deen Score + quick stats
5. Update `Router.swift` — replace `.dashboard` with `.dashboardDetail`
6. Update `RootView.swift` — update `destinationView` case
7. Update `MainTabView.swift` — remove Dashboard tab, reindex Settings
8. Delete `DashboardTabView.swift` and `DashboardTab/` folder
9. Run `make generate` — no Tuist changes needed (no new targets)
10. Update `Router.Route.dashboard` references in any tests

---

## Open Questions

- Should `DashboardSummaryCard` show `DeviceActivityReport` (requires extension process) or read from App Group directly? App Group read is simpler and avoids the extension crash-silently issue.
- Is the Deen Score computed on-demand in HomeTabViewModel or pre-computed and cached in App Group by `DashboardDataWriter`? Currently it's computed in the extension only — needs a pure-function call in HomeTabViewModel using `calculateDeenScore()` from `Shared/`.
- Should pull-to-refresh on the dashboard detail page force a `refreshNonce` increment (same as current `DashboardTabView`) or trigger a full data reload from App Group?
