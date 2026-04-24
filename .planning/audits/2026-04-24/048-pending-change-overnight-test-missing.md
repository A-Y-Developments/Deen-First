---
id: 048
title: PendingChangeServiceTests missing overnight-gap test case for clock-jump guard
severity: P2
area: lock-editing
status: closed
---

## Problem

`PendingChangeServiceTests.swift` tests the clock-jump guard with an 8000s elapsed gap (fires) and a 3600s gap (passes). Neither test covers a legitimate overnight gap (e.g., 28800s = 8h), which is the primary real-world false-positive scenario described in finding 040. Without this test, the false-positive behavior is not caught by CI.

## Evidence

`Tests/Domain/Services/PendingChangeServiceTests.swift`:
- Test: `clockJump_8000s_skipsApply` — verifies guard fires at 8000s
- Test: `normalGap_3600s_appliesPending` — verifies apply proceeds at 3600s
- Missing: `overnightGap_28800s_skipsApply` — would demonstrate the false positive

## Solution

Add a test that sets `lastKnownDate` to 8h ago, creates a 24h-elapsed pending change, calls `applyExpiredChanges()`, and asserts the change was applied (not skipped). This test will fail under the current 2h threshold, documenting the bug. Once finding 040 is fixed, the test should pass.

```swift
func test_overnightGap_28800s_doesNotSkipApply() async throws {
    let eightHoursAgo = Date().addingTimeInterval(-28800)
    mockDefaults.set(eightHoursAgo, forKey: "lastKnownDate")
    // create expired pending change
    // call applyExpiredChanges
    // assert change was applied
}
```

## Why

Tests should document both the happy path and the known failure modes. The overnight-gap case is the most common real-world trigger of this guard. CI coverage ensures any threshold change is validated.
