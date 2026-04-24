---
id: 096
title: companyId env var declared but never used in Project.swift
severity: P3
area: infra
status: open
---

## Problem

`Project.swift:3` declares `let companyId = Environment.companyId.getString(default: "")` but `companyId` is never referenced anywhere in the file. The bundle IDs are all driven by `baseBundleId` instead.

## Evidence

`Project.swift:3`:
```swift
let companyId = Environment.companyId.getString(default: "")
```

Grep confirms `companyId` has zero uses beyond its declaration (only the `let` line appears in search results).

`.env` correctly contains `TUIST_COMPANY_ID` (maps to `Environment.companyId`) and `TUIST_BASE_BUNDLE_ID` (maps to `Environment.baseBundleId`). The `baseBundleId` is the one actually used.

Contrast with mindcore `Project.swift:4`: `let companyId = Environment.companyId.getString(default: "app.adit")` — and mindcore actually uses it: `bundleId: "\(companyId).mindcore"`.

## Solution

Remove line 3 from `Project.swift`:
```swift
// DELETE:
let companyId = Environment.companyId.getString(default: "")
```

Also remove `TUIST_COMPANY_ID` from `.env` and `.env.template` if it is only serving this dead variable. Verify it has no other use first.

## Why

Dead code in the project manifest is confusing — it looks like a pattern copied from mindcore that was never fully adapted. The `.env` has 12 TUIST_ vars and keeping unused ones adds cognitive overhead when onboarding.
