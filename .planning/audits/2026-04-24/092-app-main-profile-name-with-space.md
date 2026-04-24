---
id: 092
title: Main app distribution profile also uses "Deen First" (with space) — unresolved inconsistency
severity: P2
area: infra
status: closed
---

## Problem

The main app distribution profile `"Deen First Distribution"` uses a space, while the intent of the working tree changes appears to be standardizing on the no-space "DeenFirst" format. This inconsistency was not addressed by the working tree fix.

## Evidence

`Project.swift:11`:
```swift
let appDistributionProfile = "Deen First Distribution"
```

All four profile names after partial fix:
- `"Deen First Distribution"` — space
- `"DeenFirst ScreenTimeMonitor Distribution"` — no space
- `"Deen First Shield Distribution"` — space
- `"DeenFirst ActivityReport Distribution"` — no space

## Solution

Align with whatever profile name is registered in the Apple Developer portal for the main app. If it's "Deen First Distribution" (with space), that is fine — but then Shield must also stay with space. If standardizing to no-space, update `appDistributionProfile` and `shieldDistributionProfile` to match.

This is a naming audit only — the actual profile must exist in the portal to match exactly. Verify in the Apple Developer portal which name is registered.

## Why

Profile name string is case- and space-sensitive. Mismatch causes "No profile for team" errors only at manual/CI Release builds, not Debug. Low risk if the portal profile actually matches, but needs verification.
