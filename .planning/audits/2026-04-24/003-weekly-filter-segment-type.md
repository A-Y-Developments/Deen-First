---
id: 003
title: "This Week" filter uses .weekly segment; WeeklyTrendReportScene requires 7 daily segments
severity: P0
area: dashboard
status: open
---

## Problem

`DashboardTabView`'s "This Week" filter case produces a `DeviceActivityFilter` with `.weekly(during:)` segment mode. This delivers exactly ONE aggregate segment to the extension covering the entire week. `WeeklyTrendReportScene` iterates over `context.totalActivity(for:)` expecting one segment per day (7 segments, one per day offset -6 through 0). With a single weekly segment, the scene receives one data point instead of seven; the chart is always empty (all days zero) except potentially for whichever day happens to be the start of the week segment.

The scene's own source comment makes this expectation explicit: *"The host is expected to drive this scene with a 7-day daily-segmented DeviceActivityFilter."*

## Evidence

`DashboardTabView.swift` — `makeFilter()` function, `.thisWeek` case:
```swift
case .thisWeek:
    let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now)
        ?? DateInterval(start: .now, duration: 86_400 * 7)
    return DeviceActivityFilter(
        segment: .weekly(during: interval),   // ONE segment, not 7
        users: .all,
        devices: .init([.iPhone])
    )
```

`WeeklyTrendReportScene.swift` — how segments are consumed:
```swift
func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData.TotalActivitySegment>) async -> WeeklyTrendReport {
    var screenTimeSecondsByDay: [String: Int] = [:]
    for await segment in data {
        let dayKey = DashboardDateKeys.dayKey(for: segment.dateInterval.start)
        // ...accumulate by dayKey
    }
    return WeeklyTrendReportBuilder.build(screenTimeSecondsByDay: screenTimeSecondsByDay, ...)
}
```

With `.weekly` segment mode, `data` yields one segment; `screenTimeSecondsByDay` ends up with a single key (the week-start day), all other 6 days remain zero.

## Solution

Replace the `.thisWeek` filter with a 7-day daily-segmented filter:

```swift
case .thisWeek:
    let today = Calendar.current.startOfDay(for: .now)
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: today)!
    let interval = DateInterval(start: sevenDaysAgo, end: .now)
    return DeviceActivityFilter(
        segment: .daily(during: interval),   // 7 segments, one per day
        users: .all,
        devices: .init([.iPhone])
    )
```

This produces one segment per calendar day over the rolling 7-day window, matching `WeeklyTrendReportScene`'s iteration logic.

## Why

`DeviceActivityFilter.Segment` controls how the OS buckets collected usage data before passing it to the extension. `.weekly(during:)` produces one bucket for the entire week. `.daily(during:)` produces one bucket per calendar day within the interval. The scene iterates segments assuming one-per-day bucketing; using the wrong segment type silently produces 6 phantom-zero bars on the chart. This is a silent data bug — no crash, no error, just wrong chart data.
