---
id: 091
title: Shield provisioning profile name inconsistency with other targets
severity: P1
area: infra
status: closed
---

## Problem

The distribution provisioning profile names are inconsistent between targets. After the working tree fix, two targets use the no-space format "DeenFirst" while Shield still uses the with-space format "Deen First":

- Main app: `"Deen First Distribution"` (with space)
- ScreenTimeMonitor: `"DeenFirst ScreenTimeMonitor Distribution"` (no space — fixed in working tree)
- Shield: `"Deen First Shield Distribution"` (with space — NOT fixed)
- ActivityReport: `"DeenFirst ActivityReport Distribution"` (no space — fixed in working tree)

## Evidence

`Project.swift:10-14`:
```swift
let appDistributionProfile = "Deen First Distribution"
let screenTimeMonitorDistributionProfile = "DeenFirst ScreenTimeMonitor Distribution"
let shieldDistributionProfile = "Deen First Shield Distribution"   // still with space
let activityReportDistributionProfile = "DeenFirst ActivityReport Distribution"
```

Working tree diff only fixed `screenTimeMonitorDistributionProfile` and `activityReportDistributionProfile`. Shield was not updated.

## Solution

Decide on a single naming convention and align all four profiles. The no-space "DeenFirst" format appears to be the intended standard (based on the working tree changes). Either:

Option A — fix Shield to match the others:
```swift
let shieldDistributionProfile = "DeenFirst Shield Distribution"
```
Then rename the provisioning profile in Apple Developer portal to match.

Option B — standardize everything to "Deen First" (with space) and update ScreenTimeMonitor + ActivityReport:
```swift
let screenTimeMonitorDistributionProfile = "Deen First ScreenTimeMonitor Distribution"
let activityReportDistributionProfile = "Deen First ActivityReport Distribution"
```

Option A is preferred (fewer changes, keeps working tree fix).

## Why

Profile name mismatches silently succeed in Debug (Automatic signing) but fail at App Store upload or CI Release builds when Xcode looks up the named profile and can't find an exact match. Mixed naming is also a maintenance hazard — the next person editing profiles won't know which convention applies.
