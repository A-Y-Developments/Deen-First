---
id: 062
title: print() used throughout ScreenTimeMonitor extension (must use os_log)
severity: P1
area: infra
status: closed
---

## Problem

`DeviceActivityMonitorExtension.swift` contains 15 `print()` calls. CLAUDE.md hard rule 10 states: "os_log not print() in extensions." `ScreenTimeMonitor` is a separate extension target. `print()` does not appear in device logs and is silently dropped in extension sandboxes — critical reblock events will be invisible in production diagnostics.

## Evidence

`ScreenTimeMonitor/DeviceActivityMonitorExtension.swift` — representative lines:
- Line 24: `print("✅ Reset daily quota for rule: \(ruleId)")`
- Line 60: `print("🚦 THRESHOLD REACHED: \(event.rawValue)")`
- Line 104: `print("🔒 [TempUnblock] Window expired for rule: \(ruleId)")`
- Lines 213, 218, 225, 232, 245: error/success prints

Full list: lines 24, 36, 42, 60, 71, 80, 104, 117, 163, 168, 213, 218, 225, 232, 245.

## Solution

Add `import os` and a logger at the top of `DeviceActivityMonitorExtension.swift`:
```swift
import os
private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "ScreenTimeMonitor")
```
Replace every `print(...)` with the appropriate log level:
- Operational success → `logger.info(...)`
- Guards/skips → `logger.debug(...)`
- Errors (`❌`) → `logger.error(...)`

## Why

Extension processes run in a separate sandbox. `print()` output is not captured by Instruments or Console for extension targets. `os_log` (via `Logger`) is the only reliable observability mechanism in extension targets and is mandated by CLAUDE.md rule 10.
