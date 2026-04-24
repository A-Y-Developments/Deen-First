---
id: 071
title: DashboardTabView has no ViewModel — local @State drives all logic
severity: P2
area: arch
status: open
---

## Problem

`DashboardTabView.swift` is a purely self-contained `View` with no ViewModel. All state (`dateRange`, `refreshNonce`) and all logic (filter construction) live directly in the view body. For a V2 feature area listed as a key deliverable, this bypasses the required Presentation architecture (`View + ViewModel`).

The folder `Presentation/MainTabs/DashboardTab/` contains only one file (`DashboardTabView.swift`) — there is no `DashboardTabViewModel.swift`.

## Evidence

`DashboardTabView.swift:27-28`:
```swift
@State private var dateRange: DateRange = .today
@State private var refreshNonce = 0
```

`DashboardTabView.swift:79-98`: `filter: DeviceActivityFilter` is computed inline inside the view body.

No `DashboardTabViewModel.swift` exists in `deenfirst/Sources/Presentation/MainTabs/DashboardTab/`.

## Solution

Extract a `DashboardTabViewModel` (`@MainActor final class`) that owns:
- `dateRange: DateRange`
- `refreshNonce: Int`
- `var filter: DeviceActivityFilter { ... }`
- `func refresh()`

The View references it via `@StateObject` or `@EnvironmentObject`.

This becomes moot if Dashboard moves into Home tab (finding 060), where a ViewModel already exists — in that case, add dashboard-related state to `HomeTabViewModel`.

## Why

CLAUDE.md architecture mandate: Presentation layer = View + ViewModel. Logic in View bodies makes testing impossible and violates the project pattern. Even if the current logic is simple (2 @State vars), the pattern must be consistent.
