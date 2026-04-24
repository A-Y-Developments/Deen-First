---
id: 095
title: FamilyControls/DeviceActivity/ManagedSettings linked via OTHER_LDFLAGS instead of SDK dependencies
severity: P2
area: infra
status: open
---

## Problem

The main app target links `FamilyControls`, `DeviceActivity`, and `ManagedSettings` via `OTHER_LDFLAGS`:

```swift
"OTHER_LDFLAGS": .string(
    "$(inherited) -framework FamilyControls -framework DeviceActivity -framework ManagedSettings"
)
```

The extension targets (ScreenTimeMonitor, Shield, DeenFirstActivityReport) all use the idiomatic Tuist approach:

```swift
.sdk(name: "DeviceActivity", type: .framework)
.sdk(name: "ManagedSettings", type: .framework)
.sdk(name: "FamilyControls", type: .framework)
```

## Evidence

`Project.swift:64-66` — main app uses `OTHER_LDFLAGS` for framework linking.
`Project.swift:121-123` — ScreenTimeMonitor uses `.sdk(name:type:)`.
`Project.swift:170-171` — Shield uses `.sdk(name:type:)`.
`Project.swift:218` — DeenFirstActivityReport uses `.sdk(name:type:)`.

mindcore `Project.swift` — does not use `OTHER_LDFLAGS` at all for these frameworks. No OTHER_LDFLAGS override in the main app either.

## Solution

Replace `OTHER_LDFLAGS` with explicit SDK dependencies on the main app target:

```swift
dependencies: [
    .external(name: "RevenueCat"),
    .external(name: "Alamofire"),
    .external(name: "BottomSheet"),
    .target(name: "ScreenTimeMonitor"),
    .target(name: "Shield"),
    .target(name: "DeenFirstActivityReport"),
    .sdk(name: "FamilyControls", type: .framework),
    .sdk(name: "DeviceActivity", type: .framework),
    .sdk(name: "ManagedSettings", type: .framework),
],
```

Remove the `OTHER_LDFLAGS` entry from `settings.base`.

## Why

`OTHER_LDFLAGS` with `-framework` bypasses Tuist's dependency graph, can cause duplicate symbol warnings in some Xcode versions, and is inconsistent with the rest of the project. The `.sdk(name:type:)` API is the correct Tuist idiom. The build currently succeeds either way — this is a P2 consistency/maintenance issue, not a functional blocker.
