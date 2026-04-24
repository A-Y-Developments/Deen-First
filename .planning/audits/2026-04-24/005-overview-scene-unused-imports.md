---
id: 005
title: ScreenTimeOverviewReportScene imports FamilyControls and ManagedSettings without using either
severity: P3
area: dashboard
status: closed
---

## Problem

`ScreenTimeOverviewReportScene.swift` has `import FamilyControls` and `import ManagedSettings` at lines 2–3, but neither framework is referenced anywhere in the file. The scene only uses `DeviceActivity` types and calls `ScreenTimeOverviewReportBuilder`. These unused imports are dead weight; they also compound the risk flagged in finding 004 by adding more unnecessary framework references inside the extension target.

## Evidence

`DeenFirstActivityReport/ScreenTimeOverviewReportScene.swift` lines 1–5:
```swift
import DeviceActivity
import FamilyControls     // unused
import ManagedSettings    // unused
import SwiftUI
```

Searching for any use of `FamilyControls` or `ManagedSettings` APIs in this file: zero references.

## Solution

Remove both unused import statements:

```swift
import DeviceActivity
import SwiftUI
```

Run `make generate && make build` to confirm the file compiles without them.

## Why

Unused imports do not cause runtime errors but signal copy-paste drift from another file (likely `ScreenTimeEvents.swift` or a monitoring extension file). In a report extension target with a minimal dependency list, any unused framework import is a maintenance hazard: it implies framework availability that may not exist, confuses future readers about what the file actually needs, and triggers Swift's "import is unused" warning in strict configurations.
