---
id: 007
title: QuranReadingViewModel records session time only on onDisappear; reading time lost on app background
severity: P2
area: dashboard
status: open
---

## Problem

`QuranReadingViewModel` (or equivalent) tracks Quran reading time by recording a start timestamp when the reading view appears and writing elapsed seconds to `DashboardDataWriter` when the view disappears (`onDisappear`). If the user backgrounds the app mid-session without dismissing the reading view, `onDisappear` is not called on iOS. The session time is lost entirely — it is never written to the App Group and therefore never reflected in the Deen Score or the Dashboard.

This is a silent data-loss bug. The user did the reading; the app doesn't record it.

## Evidence

Pattern identified in reading flow — `onDisappear` is the sole write trigger for reading session time. iOS lifecycle: when the app moves to the background, `scenePhase` changes to `.background` but `onDisappear` is NOT called for views that are still on screen. The view is only unmounted (and `onDisappear` called) when the view is actually removed from the hierarchy.

`RootView.swift` calls `flush()` on `willEnterForeground` (line 110) — this re-stamps `dataLastUpdatedAtKey` but does not account for an in-progress session whose time has not yet been recorded.

## Solution

Add a `scenePhase` observer to the reading ViewModel or view that records partial session time on `.background` transition:

```swift
// In the reading view or its ViewModel:
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .background {
        viewModel.recordPartialSession()
    } else if newPhase == .active {
        viewModel.resumeSession()
    }
}
```

Where `recordPartialSession()`:
1. Calculates elapsed seconds since `sessionStart`
2. Calls `dashboardDataWriter.recordQuranReading(seconds: elapsed)`
3. Calls `dashboardDataWriter.flush()`
4. Resets `sessionStart` to `nil` (or marks session as "partial")

And `resumeSession()` resets `sessionStart = Date()` so elapsed time from `active` onward is correctly tracked.

## Why

On iOS, `onDisappear` fires only when a view is removed from the SwiftUI view hierarchy. Backgrounding the app suspends it without removing any views. `ScenePhase.background` is the correct hook for mid-session persistence. Without it, any reading session where the user backgrounds the app before closing the reader is silently dropped from the Deen Score calculation, causing the dashboard to undercount Quran engagement.
