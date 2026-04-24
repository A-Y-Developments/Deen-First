---
id: 067
title: isTemporarilyUnblocked and unblockRemainingSeconds not declared in ScreenTimeRulesService protocol
severity: P2
area: arch
status: closed
---

## Problem

`ScreenTimeRulesService+Unblock.swift` defines `isTemporarilyUnblocked(ruleId:)` and `unblockRemainingSeconds(ruleId:)` on the concrete `ScreenTimeRulesServiceImpl`. These methods are NOT declared in the `ScreenTimeRulesService` protocol (`ScreenTimeRulesService.swift`). Any code that needs these methods must downcast to `ScreenTimeRulesServiceImpl` — breaking the protocol abstraction and making the service untestable via the protocol interface.

## Evidence

`ScreenTimeRulesService.swift` — protocol has no `isTemporarilyUnblocked` or `unblockRemainingSeconds` declaration.

`ScreenTimeRulesService+Unblock.swift:184-198`:
```swift
func isTemporarilyUnblocked(ruleId: UUID) -> Bool { ... }
func unblockRemainingSeconds(ruleId: UUID) -> Int? { ... }
```
These are implementation-only, not surfaced in the protocol.

## Solution

Add to `ScreenTimeRulesService` protocol:
```swift
func isTemporarilyUnblocked(ruleId: UUID) -> Bool
func unblockRemainingSeconds(ruleId: UUID) -> Int?
```
Callers (HomeTabViewModel, BlockingTabViewModel) already use `AppGroupConstants.sharedDefaults` directly to read the same expiry key — they bypass the service entirely. Once these are on the protocol, callers can delegate.

## Why

Consumers (HomeTabViewModel) currently re-read `AppGroupConstants.unblockExpiryKey` directly instead of calling a service method — because the service method isn't on the protocol they hold. This creates a third source of unblock state reads (App Group → ViewModel directly, bypassing service encapsulation).
