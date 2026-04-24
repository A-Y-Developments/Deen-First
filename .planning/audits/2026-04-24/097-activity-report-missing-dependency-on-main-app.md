---
id: 097
title: DeenFirstActivityReport was not a dependency of main app in committed state — working tree fix is correct
severity: P0
area: infra
status: open
---

## Problem

In the committed state (before working tree changes), the main `DeenFirst` target did NOT list `DeenFirstActivityReport` as a dependency. The working tree adds it.

Without this dependency, the extension is not embedded in the app bundle. The OS cannot load the extension. The Dashboard feature cannot function — DeviceActivity will have no registered report extension to call.

## Evidence

`git diff Project.swift` shows:
```
+    .target(name: "DeenFirstActivityReport"),
     // ShieldAction removed...
```

In the committed state, `dependencies` of `DeenFirst` only listed:
- `.external(name: "RevenueCat")`
- `.external(name: "Alamofire")`
- `.external(name: "BottomSheet")`
- `.target(name: "ScreenTimeMonitor")`
- `.target(name: "Shield")`

`DeenFirstActivityReport` was absent.

The `make build` output (working tree) shows `DeenFirstActivityReport` is now built as part of the dependency chain:
```
Target 'DeenFirst' in project 'Deen First'
    ➜ Explicit dependency on target 'DeenFirstActivityReport' in project 'Deen First'
```

## Solution

Keep the working tree as-is. The addition of `.target(name: "DeenFirstActivityReport")` to the main app's `dependencies` array is correct and required.

## Why

App extensions must be embedded in their host app's bundle to be discovered by the OS. A Tuist `.target(name:)` dependency in the host app causes Xcode to embed the extension's `.appex` bundle. Without this, the extension binary exists but is never copied into `DeenFirst.app/PlugIns/` and the OS never registers it. This is likely one of the two root causes (alongside 090) for why the Dashboard was broken.
