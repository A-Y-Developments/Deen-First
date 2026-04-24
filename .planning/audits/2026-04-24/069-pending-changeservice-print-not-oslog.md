---
id: 069
title: PendingChangeService uses print() alongside os_log — inconsistent logging
severity: P3
area: arch
status: closed
---

## Problem

`PendingChangeService.swift` imports `os` and correctly creates a `Logger` instance (`line 24`). However, warning-level events are logged with `print()` (lines 49, 60, 104, 127) while only fault-level events use the logger (line 84). The project rule is `os_log` in extension targets; main app can use `print()` in debug only. But having the logger AND print() in the same service is inconsistent and the `print()` calls will not appear in production logs on device (only simulator console).

## Evidence

`PendingChangeService.swift:24`:
```swift
private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "PendingChangeService")
```

`PendingChangeService.swift:49`:
```swift
print("⚠️ [PendingChangeService] Unknown changeType '\(changeType)' — change not created")
```

`PendingChangeService.swift:84` (correct):
```swift
logger.fault("Clock manipulation suspected: jumped \(Int(elapsed))s — skipping auto-apply")
```

`PendingChangeService.swift:104`:
```swift
print("⚠️ [PendingChangeService] Failed to apply change \(change.id)...")
```

## Solution

Route all `print("⚠️ ...")` through `logger.warning(...)` or `logger.error(...)`. Remove the inconsistency. Since PendingChangeService is in the main app target (not an extension), `print()` is technically allowed in debug, but given a `Logger` is already instantiated it's cleaner to use it consistently.

## Why

Inconsistent logging means some P1-level events (failed apply, unknown changeType) are invisible in production device logs while others are captured. When debugging clock manipulation issues on real hardware, `logger.fault` is visible; `print` is not.
