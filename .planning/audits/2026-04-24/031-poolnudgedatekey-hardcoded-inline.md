---
id: 031
title: poolNudgeDateKey hardcoded inline in ViewModel — should be in AppGroupConstants
severity: P2
area: arch
status: closed
---

## Problem

`ReciteToUnblockViewModel` defines `poolNudgeDateKey` as an inline string literal directly in the ViewModel file. This violates the project rule that all App Group keys are defined in `AppGroupConstants` and never hardcoded inline.

## Evidence

`ReciteToUnblockViewModel.swift` line ~115:

```swift
private let poolNudgeDateKey = "com.aydev.deenfirst.poolNudgeDate"
```

Project rule (CLAUDE.md and tuist.md): "App Group — cross-process data via `AppGroupConstants`. Never hardcode keys inline." and "Shared suite name always via `AppGroupConstants.suiteName`. Never hardcode `\"group.com.aydev.deenfirst\"` inline anywhere."

`AppGroupConstants.swift` is the designated home for all such key strings.

## Solution

Add to `AppGroupConstants.swift`:

```swift
static let poolNudgeDateKey = "com.aydev.deenfirst.poolNudgeDate"
```

Update `ReciteToUnblockViewModel.swift` to reference:

```swift
private let poolNudgeDateKey = AppGroupConstants.poolNudgeDateKey
```

## Why

Inline key strings fragment the cross-process data contract across multiple files. If another component (extension or background service) needs to read the nudge date, it would need to duplicate the literal. Centralizing in `AppGroupConstants` makes the contract discoverable and prevents typos causing silent misses.
