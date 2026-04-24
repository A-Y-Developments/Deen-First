---
id: 028
title: isUnblockSession set on Session after repository.save() — flag not persisted on crash
severity: P1
area: unblock
status: closed
---

## Problem

In `ActiveSessionViewModel`, a new `Session` is saved to the repository before `isUnblockSession` and `unlockRuleId` are set on it. If the app is killed between the `save()` call and the subsequent mutations, the persisted Session row has `isUnblockSession = false` and `unlockRuleId = nil`, losing the unblock context. This also means `DashboardDataWriter.recordFocusSession` (called in `endSession`) receives a session without the flag, potentially misattributing the session type.

## Evidence

`ActiveSessionViewModel.swift` lines ~119–125:

```swift
let newSession = try await sessionRepository.save(session)  // line 119 — saved without flag
newSession.isUnblockSession = isUnblockSession               // line 124 — mutated after save
newSession.unlockRuleId = unlockRuleId                       // line 125 — mutated after save
self.session = newSession
```

`SessionService.swift` — `startSession()` returns the Session from the repository; the `isUnblockSession` parameter is passed to `SessionService` but the field is set on the returned object after the repository write.

SwiftData `@Model` mutations after save are persisted lazily — if the context is never saved again before termination, the mutation is lost.

## Solution

Pass `isUnblockSession` and `unlockRuleId` to `startSession()` as parameters so they are set on the Session *before* the first `context.save()`:

```swift
func startSession(
    type: Session.SessionType,
    surahNumbers: [Int],
    reciterId: Int?,
    isUnblockSession: Bool = false,
    unlockRuleId: UUID? = nil
) async throws -> Session
```

Inside the service, construct the Session with all fields before calling `context.insert()` + `context.save()`.

## Why

SwiftData inserts are only durable after `context.save()`. Mutating properties after save means a second implicit or explicit save is required. The current pattern relies on a subsequent app lifecycle event to flush the mutation — a fragile assumption, especially for a session that may end due to the same crash that interrupts startup.
