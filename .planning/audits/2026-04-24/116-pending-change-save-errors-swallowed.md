---
id: 116
title: PendingChangeService save mutations wrapped in try? — state loss on failure
severity: P2
area: code-quality
status: open
---

## Problem

`PendingChangeService` mutates in-memory state (marks a change as cancelled or applied) but then wraps the persistence call in `try?`. If the save fails, the in-memory state diverges from disk — on next launch the change appears active again, double-applying or re-offering a cancelled edit.

Two affected sites:
- `cancelPendingChange`: sets `isCancelled = true`, then `try? localDataSource.savePendingChanges()`
- `applyExpiredChanges` (line 101): sets `isApplied = true`, then `try? localDataSource.savePendingChanges()`

## Evidence

`deenfirst/Sources/Domain/Services/PendingChangeService.swift:70`
```swift
isCancelled = true
try? localDataSource.savePendingChanges()   // ← swallowed
```

`PendingChangeService.swift:101` — identical pattern for `isApplied = true`.

Neither site logs on failure.

## Solution

Propagate or log the error:

```swift
do {
    try localDataSource.savePendingChanges()
} catch {
    logger.error("Failed to persist cancelled pending change: \(error.localizedDescription)")
    // Optionally: rethrow if the caller can surface this to the user
}
```

For cancel: surface an error to the UI (P1 user flow — they think the change is cancelled but it will re-apply). For apply: log as P2 (the change was applied to ManagedSettings; only the persisted flag is missing — it may double-apply on next launch).

## Why

Silent `try?` on state mutations that have no in-memory compensating rollback creates ghost state. The clock manipulation guard (040) already shows the complexity of reasoning about PendingChangeService correctness — adding silent persistence failures makes it harder to trust the feature works end-to-end.
