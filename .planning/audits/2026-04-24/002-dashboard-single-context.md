---
id: 002
title: DashboardTabView hosts only "DeenScore" context; 4 of 5 sections never render
severity: P0
area: dashboard
status: open
---

## Problem

`DashboardTabView` creates exactly one `DeviceActivityReport` view with context `"DeenScore"`. The extension declares five scenes: `DeenScoreReportScene`, `ScreenTimeOverviewReportScene`, `QuranEngagementReportScene`, `QuranVsScreenTimeReportScene`, and `WeeklyTrendReportScene`. The four contexts `"ScreenTimeOverview"`, `"QuranEngagementToday"`, `"QuranVsScreenTime"`, and `"WeeklyTrend"` are never instantiated in the host. These four dashboard sections are architecturally unreachable — not just empty, but never loaded from the extension at all.

## Evidence

`DashboardTabView.swift` line 19 (only context declaration):
```swift
private let context = DeviceActivityReport.Context(rawValue: "DeenScore")
```

Lines 24–30 (only `DeviceActivityReport` instantiation):
```swift
ZStack {
    fallbackPlaceholder
    DeviceActivityReport(context, filter: filter)
        .id(refreshNonce)
}
```

`DeenFirstActivityReportExtension.swift` — declared scenes:
```swift
var body: some DeviceActivityReportScene {
    DeenScoreReportScene()
    ScreenTimeOverviewReportScene()
    QuranEngagementReportScene()
    QuranVsScreenTimeReportScene()
    WeeklyTrendReportScene()
}
```

The four missing contexts: `"ScreenTimeOverview"`, `"QuranEngagementToday"`, `"QuranVsScreenTime"`, `"WeeklyTrend"` — zero references in `DashboardTabView.swift`.

## Solution

Add one `DeviceActivityReport` instantiation per context. Each section needs its own filter appropriate to its data range:

```swift
// Screen Time Overview (today)
DeviceActivityReport(
    DeviceActivityReport.Context(rawValue: "ScreenTimeOverview"),
    filter: makeTodayFilter()
)

// Quran Engagement Today
DeviceActivityReport(
    DeviceActivityReport.Context(rawValue: "QuranEngagementToday"),
    filter: makeTodayFilter()
)

// Quran vs Screen Time
DeviceActivityReport(
    DeviceActivityReport.Context(rawValue: "QuranVsScreenTime"),
    filter: makeTodayFilter()
)

// Weekly Trend — must use daily-segmented filter (see finding 003)
DeviceActivityReport(
    DeviceActivityReport.Context(rawValue: "WeeklyTrend"),
    filter: makeSevenDayDailyFilter()
)
```

Each of these should be embedded inside its own scroll section. A single shared `DeviceActivityReport` cannot drive multiple contexts simultaneously.

## Why

`DeviceActivityReport(context:filter:)` is a host view that renders exactly one scene from the extension, identified by `context.rawValue`. There is no mechanism to render multiple scenes through a single host view. Each section of the dashboard is a separate `DeviceActivityReport` instantiation with its own context string. Without instantiating the remaining four, their extension scenes are compiled but never executed.
