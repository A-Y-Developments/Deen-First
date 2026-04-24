---
id: 045
title: pendingChangeService optional injection silently no-ops lock-editing gate
severity: P2
area: lock-editing
status: closed
---

## Problem

`ScreenTimeRulesService+LockEditing.swift` holds `pendingChangeService` as an optional and guards all lock-editing paths with `guard let pending = pendingChangeService`. If the service is not injected (misconfiguration), lock-editing silently does nothing — edits go through unguarded. There is no crash, no error logged to the user, only a warning print.

## Evidence

`ScreenTimeRulesService+LockEditing.swift` (approx):
```swift
private var pendingChangeService: PendingChangeService?

func editRuleWithLockCheck(...) async throws {
    guard let pending = pendingChangeService else {
        print("PendingChangeService not injected")
        return  // silently skips the entire lock gate
    }
    ...
}
```

This means: if `DIContainer` fails to wire `pendingChangeService`, all lock-editing protection disappears without the developer noticing during testing.

## Solution

Make the dependency non-optional. Inject via initializer:
```swift
init(rulesDataSource: ScreenTimeRulesDataSource,
     pendingChangeService: PendingChangeService) {
    self.pendingChangeService = pendingChangeService
}
```

If circular dependency prevents this, use a `preconditionFailure` in the guard instead of a silent return:
```swift
guard let pending = pendingChangeService else {
    preconditionFailure("PendingChangeService must be injected before use")
}
```

## Why

Optional injection of a security-critical dependency (the lock gate) makes the system fail open: misconfiguration = no protection. Non-optional injection or a fatal guard ensures the misconfiguration is caught immediately at startup rather than silently bypassed in production.
