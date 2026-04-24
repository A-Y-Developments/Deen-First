---
id: 065
title: Router.Route.dashboard is dead — routed to DashboardTabView not a push detail screen
severity: P2
area: nav
status: closed
---

## Problem

`Router.swift:35` defines `.dashboard` as a route. `RootView.swift:235` resolves it by pushing `DashboardTabView()` as a navigation destination. But `DashboardTabView` itself contains a `NavigationStack`, creating a nested NavigationStack anti-pattern. Simultaneously, DashboardTabView is also mounted as a tab in MainTabView — so the same view is reachable both as a tab and as a pushed navigation destination, with conflicting NavigationStack contexts.

## Evidence

`Router.swift:35`:
```swift
case dashboard
```

`RootView.swift:234-236`:
```swift
case .dashboard:
    DashboardTabView()
```

`DashboardTabView.swift:31`:
```swift
NavigationStack {
    ScrollView { ... }
}
```

Pushing a view that owns its own `NavigationStack` into the outer `NavigationStack` (from `RootView`) creates a nested stack — navigation bar appears doubled and back button behavior is broken.

## Solution

Once the dashboard moves to Home tab (see finding 060 and MIGRATION doc), `.dashboard` route should either be removed entirely or replaced with a dedicated `DashboardDetailView` (no inner NavigationStack) for the push case. If a detail push is needed, create a flat `DashboardDetailView` without its own NavigationStack.

## Why

Nested NavigationStacks are unsupported in SwiftUI and produce undefined behavior including doubled navigation bars and broken back gesture. The `.dashboard` route has no callers that push it programmatically (zero call sites found in source), making it currently dead code in addition to being architecturally broken.
