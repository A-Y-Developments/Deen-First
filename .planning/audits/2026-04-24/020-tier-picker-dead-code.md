---
id: 020
title: UnblockDurationSelectionView is dead code — never navigated to
severity: P0
area: unblock
status: closed
---

## Problem

`UnblockDurationSelectionView` (the new V2 tier picker with Hard Mode-aware TierCards) is never pushed or presented from any live call site. Every entry point in the app that triggers an unblock flow uses the legacy `UnblockDurationSheet` (wheel picker) instead. The entire tier picker UI, along with all the logic it encapsulates (Hard Mode tier labels, progressive tier requirements, `selectTier()` routing), is unreachable by users.

## Evidence

`RootView.swift:232` — the only reference to `.unblockDurationSelection(ruleId:)` is as a `NavigationDestination` handler, never as a `NavigationLink` or `path.append()` call:

```swift
// RootView.swift line 232
.navigationDestination(for: Route.self) { route in
    switch route {
    case .unblockDurationSelection(let ruleId):
        UnblockDurationSelectionView(ruleId: ruleId)
```

Grep of entire `Sources/` directory:
```
grep -r "unblockDurationSelection" Sources/
# Only: RootView.swift (destination handler)
# Zero: call sites navigating TO this route
```

`BlockingTabView` and `HomeTabView` both present `UnblockDurationSheet` (a wheel picker sheet) — not `UnblockDurationSelectionView`. The Sheet is the live path.

## Solution

Replace `UnblockDurationSheet` with navigation to `UnblockDurationSelectionView`. The call sites are in `BlockingTabView` and wherever the "Unblock" button is wired. Change those to `router.path.append(.unblockDurationSelection(ruleId: rule.id))` (or equivalent sheet-based approach if staying sheet-based). Delete or repurpose `UnblockDurationSheet` once the new picker is wired in.

## Why

All downstream tier logic (Hard Mode tier counts, tier-aware routing to recite vs focus session, TierCard UX) only exists inside `UnblockDurationSelectionView`. Since users never reach it, V2's entire tier selection experience is missing. The feature shipped with legacy V1 UI as the sole unblock entry point.
