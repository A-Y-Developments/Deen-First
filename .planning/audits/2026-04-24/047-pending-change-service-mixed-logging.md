---
id: 047
title: PendingChangeService mixes print() and Logger — violates logging rule
severity: P3
area: lock-editing
status: closed
---

## Problem

`PendingChangeService.swift` uses `Logger` (os_log) for the clock-jump warning but uses bare `print()` at 5 other call sites (lines 47, 60, 104, 124, 189). Project rules require `os_log` / `Logger` throughout; `print()` is only permitted in the main app during debug.

## Evidence

`Domain/Services/PendingChangeService.swift`:
- Line 84: `logger.warning("Clock jump detected...")`  — uses Logger
- Lines 47, 60, 104, 124, 189: `print("...")` — bare print

(Also filed as finding 069 in the arch/nav audit area; recorded here for lock-editing completeness.)

## Solution

Replace all `print()` calls with `logger.debug(...)` or `logger.info(...)` as appropriate. `Logger` is already imported and initialized; it's a mechanical substitution.

## Why

Consistency with project logging rule. `print()` is stripped by the compiler in release builds on some configurations and produces no structured output for log aggregation tools.
