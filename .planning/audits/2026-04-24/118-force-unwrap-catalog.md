---
id: 118
title: Force unwrap catalog — 3 confirmed sites across V1+V2 paths
severity: P2
area: code-quality
status: closed
---

## Problem

Project rule: "No force unwrap — ever." Three confirmed force unwrap sites span core V1 and V2 paths.

## Evidence

**Site 1 — RootView.swift:40**
```swift
!currentUser!.hasCompletedOnboarding
```
Guarded by `currentUser == nil` at line 38, but the force unwrap is still a rule violation — a refactor that reorders conditions breaks it silently.

**Site 2 — SessionService.swift:193**
```swift
UserPersistenceHelper.saveLastActiveDate(user.lastActiveDate!, userId: user.appleUserId)
```
`lastActiveDate` is set at line 184 (`user.lastActiveDate = Date()`), so it is non-nil at the point of the unwrap — but only if the assignment was not removed. The property type is `Date?` and the force unwrap bypasses the type system guarantee.

**Site 3 — ReciteToUnblockViewModel.swift:426**
```swift
URL(string: "https://api.openai.com/v1/audio/transcriptions")!
```
Static string URL — will never fail at runtime, but force unwrap on `URL(string:)` is a rule violation. A typo during future URL changes would crash the app.

## Solution

**Site 1:**
```swift
guard let user = currentUser else { ... }
if !user.hasCompletedOnboarding { ... }
```

**Site 2:**
```swift
guard let lastActive = user.lastActiveDate else { return }
UserPersistenceHelper.saveLastActiveDate(lastActive, userId: user.appleUserId)
```

**Site 3:**
```swift
private static let whisperURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")
// then: guard let url = Self.whisperURL else { throw ReciteError.invalidConfiguration }
```
Or define it as a non-optional constant once validated at startup.

## Why

Force unwraps make crashes invisible at the type level. The "it can't fail" reasoning is always context-dependent — safe today, dangerous after any surrounding refactor. The project rule is a blanket ban for this reason.
