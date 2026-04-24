---
id: 060
title: Dashboard is a separate tab — user wants 4-tab navigation
severity: P1
area: nav
status: open
---

## Problem

`MainTabView.swift` renders 5 tabs: Home (0), Quran (1), Blocking (2), Dashboard (3), Settings (4). The desired V2 design is 4 tabs with Dashboard content embedded in Home tab, not as a standalone tab.

## Evidence

`MainTabView.swift:28-29`:
```swift
DashboardTabView()
    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
    .tag(3)
```
`MainTabView.swift:33-34`:
```swift
SettingsTabView()
    .tabItem { Label("Settings", systemImage: "gear") }
    .tag(4)
```

HomeTabView currently has 3 sections: `heroSection`, `dailySurahSection`, `activeBlocksSection` — no dashboard summary card.

## Solution

Remove `DashboardTabView()` tab from `MainTabView`. Add a `DashboardSummaryCard` component to `HomeTabView` between `activeBlocksSection` and the bottom. Provide a tap-to-expand route via `Router.Route.dashboard`. See companion doc `MIGRATION-dashboard-to-home.md` for full breakdown.

## Why

The 5-tab layout deviates from the agreed product design. Dashboard is a supporting surface, not a primary navigation destination. Housing it under Home reduces tab bar cognitive load and is consistent with V1's 4-tab pattern.
