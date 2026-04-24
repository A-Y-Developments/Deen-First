---
id: 111
title: Non-locked rule edit has data-loss window
severity: P1
area: v1-regression
status: closed
---

## Problem

In `ScreenTimeRulesService+LockEditing.swift`, the non-locked edit path (when `isLockEditingEnabled == false`) first **deletes** the existing rule, then attempts to **recreate** it with updated data. The delete is wrapped in `try?`, making it fire-and-forget. If the subsequent create call fails (network error, ManagedSettings error, model context save failure), the rule is permanently gone with no rollback. The user loses their blocking rule silently.

## Evidence

`deenfirst/Sources/Domain/Services/ScreenTimeRulesService+LockEditing.swift:38`
```swift
try? await deleteAppLimit(id: ruleId)   // ← fire-and-forget delete
// ... then:
try await setAppLimitBlock(...)          // if this throws, rule is gone
```

`ScreenTimeRulesService+LockEditing.swift:73` — same pattern for time limit edits.

Reproduction path: edit a rule while Lock Editing is off, simulate a ManagedSettings failure on the re-create call (e.g., revoke FamilyControls authorization mid-edit). The original rule no longer exists.

## Solution

Option A (preferred): Load the existing rule data first, attempt the create, only delete the old rule on success:

```swift
let existing = try getRule(id: ruleId)  // snapshot
do {
    try await setAppLimitBlock(...)      // create new
    try await deleteAppLimit(id: ruleId, skipNew: true)  // remove old on success
} catch {
    // existing rule still intact — rethrow
    throw error
}
```

Option B: Use an update-in-place approach if ManagedSettings supports it, avoiding the delete/create cycle entirely.

## Why

Delete-then-create with `try?` on the delete is a classic TOCTOU-style data-loss pattern. Even a transient system error during the create step leaves the app in an invalid state with no rule. Users rely on blocking rules for accountability — losing them silently is a P1 regression from V1 (where rules were only deleted on explicit user action, never as a side effect of editing).
