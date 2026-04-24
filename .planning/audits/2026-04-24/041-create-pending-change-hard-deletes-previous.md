---
id: 041
title: createPendingChange hard-deletes previous change, losing audit trail
severity: P2
area: lock-editing
status: open
---

## Problem

When a second pending change is created for the same rule, `createPendingChange` hard-deletes the existing `PendingRuleChange` record before inserting the new one. This means the previous requested-at timestamp, the original payload, and the cancellation history are all permanently lost. If the second creation fails mid-flight (after delete, before insert), the rule has no pending change at all.

## Evidence

`Domain/Services/PendingChangeService.swift` lines 43-44:
```swift
if let existing = try? await localDataSource.fetchPendingChange(for: ruleId) {
    localDataSource.deletePendingChange(existing)  // hard delete, no try
```

`cancelPendingChange` (line 69) by contrast soft-marks `isCancelled = true`. The two paths are inconsistent: cancel is non-destructive, replace is destructive.

`localDataSource.deletePendingChange` is called without `try` — if it throws internally, the error is silently discarded.

## Solution

Soft-cancel the existing change instead of deleting it:
```swift
if let existing = try? await localDataSource.fetchPendingChange(for: ruleId) {
    existing.isCancelled = true
    try localDataSource.save()
}
```

This preserves history and eliminates the delete-then-fail race. The `fetchPendingChange` query should filter by `!isCancelled` so cancelled records don't surface in the active path.

## Why

Hard-deleting on replace is a write-ordering hazard: if the process is interrupted after delete but before the new insert, the rule silently has no pending change. Soft-cancellation is idempotent and recoverable. Consistency with the existing `cancelPendingChange` path is a secondary benefit.
