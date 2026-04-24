---
id: 042
title: PendingChangeType .disable and .delete both call applyDelete — identical behavior
severity: P1
area: lock-editing
status: closed
---

## Problem

`PendingChangeService.applyChange()` routes `.disable` and `.delete` to the same `applyDelete` implementation. A user creating a pending "disable rule" change will have their rule *deleted* (not disabled) when it applies.

## Evidence

`Domain/Services/PendingChangeService.swift` lines 131-134:
```swift
case .disable:
    try await applyDelete(change)
case .delete:
    try await applyDelete(change)
```

`applyDelete` (inferred from naming and symmetry with other apply methods) deletes the `ScreenTimeRule` from SwiftData — it does not flip `isEnabled = false`.

## Solution

Implement a separate `applyDisable` path:
```swift
case .disable:
    try await applyDisable(change)
case .delete:
    try await applyDelete(change)
```

```swift
private func applyDisable(_ change: PendingRuleChange) async throws {
    guard let rule = try await rulesService.fetchRule(id: change.ruleId) else { return }
    rule.isEnabled = false
    try await rulesService.saveRule(rule)
    try await screenTimeRulesService.deactivateRule(rule)
}
```

## Why

`PendingChangeType.disable` and `.delete` are semantically distinct — disabling preserves the rule for re-enabling later; deleting is permanent. Routing both to `applyDelete` silently destroys user configuration. This is a data-loss bug for any user who queues a "disable" pending change.
