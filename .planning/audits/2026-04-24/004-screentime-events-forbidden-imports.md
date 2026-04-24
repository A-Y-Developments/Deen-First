---
id: 004
title: ScreenTimeEvents.swift compiled into ActivityReport extension (unused) — hygiene issue
severity: P2
area: dashboard
status: open
---

## Problem

`deenfirst/Sources/Shared/ScreenTimeEvents.swift` imports `FamilyControls` + `ManagedSettings` + `DeviceActivity`. It is compiled into the `DeenFirstActivityReport` extension target via the `deenfirst/Sources/Shared/**` sources glob, but:
1. The extension never calls any symbol from this file
2. The extension's `dependencies:` declares only `.sdk(name: "DeviceActivity", type: .framework)` — not FamilyControls or ManagedSettings

## Evidence

`ScreenTimeEvents.swift:1-4`:
```swift
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
```

`Project.swift:212-219` — DeenFirstActivityReport target:
```swift
sources: [
    "DeenFirstActivityReport/**",
    "deenfirst/Sources/Shared/**",   // pulls in ScreenTimeEvents.swift
],
dependencies: [
    .sdk(name: "DeviceActivity", type: .framework),
    // FamilyControls and ManagedSettings NOT listed
],
```

The extension's scene files (`DeenScoreReportScene`, `WeeklyTrendReportScene`, etc.) use only `DeviceActivity` types — `ScreenTimeEvents` is dead weight inside the extension target.

## Reconciliation with infra-agent "build passed"

The infra-agent's `make generate && make build` succeeded. This is because modern Swift uses **autolinking** (`LC_LINKER_OPTION` metadata embedded in a framework's `.swiftmodule`): merely writing `import FamilyControls` in a compiled source file causes the linker to implicitly link `FamilyControls.framework` from the iOS SDK, even if it is not in `dependencies:`. So this is not a build-blocker — it is a hygiene / target-minimalism issue.

Original finding over-stated severity. Downgraded from P1 to P2.

## Solution

Exclude `ScreenTimeEvents.swift` from `DeenFirstActivityReport` sources. Preferred approach — move it to a folder that only the main app + `ScreenTimeMonitor` target glob:

Option A (preferred — move file):
```
deenfirst/Sources/Shared/ScreenTimeEvents.swift  →  deenfirst/Sources/Domain/ScreenTime/ScreenTimeEvents.swift
```
Then update `ScreenTimeMonitor`'s sources in Project.swift to explicitly include the new path:
```swift
sources: [
    "ScreenTimeMonitor/**",
    "deenfirst/Sources/Shared/**",
    "deenfirst/Sources/Domain/ScreenTime/**",   // new
],
```
And remove the main app's explicit inclusion (it already picks it up via `deenfirst/Sources/**`).

Option B (exclude at the glob level for the report extension):
Tuist supports `excluding:` in `sources:` — use it to exclude `ScreenTimeEvents.swift` from `DeenFirstActivityReport` only.

## Why

The `Shared/` folder contract is "code used by 3+ targets." `ScreenTimeEvents.swift` is used by 2 (main app + ScreenTimeMonitor) — the report extension has no use for event creation or token persistence. Putting it in `Shared/` forces unnecessary framework imports into an extension that doesn't need them, inflates binary size (slightly), and blurs the Shared/ contract. Autolinking masked the problem at build time, but the extension still carries dead code with unrelated framework coupling.
