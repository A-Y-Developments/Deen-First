---
id: 074
title: applyFlagUpdate helper duplicated in PendingChangeService and ScreenTimeRulesService+LockEditing
severity: P2
area: code-quality
status: open
---

## Problem

The `applyFlagUpdate(ruleId:update:)` private helper that reads a rule, applies a mutation, and writes it back is implemented twice:

1. `PendingChangeService.swift:187-196` — `private func applyFlagUpdate`
2. `ScreenTimeRulesService+LockEditing.swift:151-158` — `private func applyFlagUpdate`

Both call `repository.getRule(id:)`, apply a closure mutation, then call `repository.setAppLimitRule/setTimeLimitRule`. The implementations are functionally identical.

## Evidence

`PendingChangeService.swift:187-196`:
```swift
private func applyFlagUpdate(ruleId: UUID, update: (inout ScreenTimeRule) -> Void) {
    guard var rule = screenTimeRulesRepository.getRule(id: ruleId) else { ... }
    update(&rule)
    switch rule.type {
    case .appLimit: screenTimeRulesRepository.setAppLimitRule(rule)
    case .timeLimit: screenTimeRulesRepository.setTimeLimitRule(rule)
    }
}
```

`ScreenTimeRulesService+LockEditing.swift:151-158`:
```swift
private func applyFlagUpdate(ruleId: UUID, update: (inout ScreenTimeRule) -> Void) {
    guard var rule = repository.getRule(id: ruleId) else { return }
    update(&rule)
    switch rule.type {
    case .appLimit: repository.setAppLimitRule(rule)
    case .timeLimit: repository.setTimeLimitRule(rule)
    }
}
```

## Solution

Move `applyFlagUpdate` to `ScreenTimeRulesRepository` as a default method or to `ScreenTimeRulesServiceImpl` and expose it via a protocol method `applyFlagUpdate(ruleId:update:)`. `PendingChangeService` calls the service method instead of the repository directly.

## Why

DRY violation. Any bug in flag update logic (e.g. needing to reapply shields after a flag change) must be fixed in two places. The `PendingChangeService` reaching directly into `screenTimeRulesRepository` also bypasses the service layer for what is a write operation.
