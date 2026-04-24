---
id: 112
title: 15 print() calls in ScreenTimeMonitor extension
severity: P1
area: arch
status: open
---

## Problem

`ScreenTimeMonitor/DeviceActivityMonitorExtension.swift` contains 15 `print()` calls. The project rule (CLAUDE.md) is explicit: "os_log not print() — in extensions." `print()` in an extension target is a violation because:
1. Output is not captured in the system log visible via Console.app or `log stream`.
2. `print()` is a no-op in release builds of extension targets in many configurations.
3. The rule exists precisely to ensure observability in extension processes that run out-of-process.

## Evidence

```
grep -c 'print(' ScreenTimeMonitor/DeviceActivityMonitorExtension.swift
# → 15
```

Lines identified: 24, 36, 42, 60, 71, 80, 104, 117, 163, 168, 213, 218, 225, 232, 245.

## Solution

Replace every `print(...)` with `os_log` / `Logger`:

```swift
import os
private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "ScreenTimeMonitor")

// Before:
print("DeviceActivity event: \(event)")
// After:
logger.debug("DeviceActivity event: \(event, privacy: .public)")
```

Run a project-wide grep after the fix to confirm no `print(` remain in any extension directory (`ScreenTimeMonitor/`, `Shield/`, `DeenFirstActivityReport/`).

## Why

Extensions run in a separate process. `print()` goes to stdout, which is not captured in the unified logging system. Debugging extension misbehavior in production is impossible without `os_log`. This is a hard architecture rule, not a style preference.
