---
id: 100
title: DeenFirstActivityReport has com.apple.developer.family-controls entitlement — mindcore omits it
severity: P2
area: infra
status: closed
---

## Problem

`DeenFirstActivityReport/DeenFirstActivityReport.entitlements` includes `com.apple.developer.family-controls: true`. The mindcore reference project's equivalent extension (`monitorExtension/monitorExtension.entitlements`) also includes it, but the mindcore `ScreenTimeMonitor/ScreenTimeMonitor.entitlements` does NOT have it — it only has the App Group.

The question is whether the ActivityReport extension actually needs `family-controls`. The extension only reads from the App Group shared defaults — it does not call any FamilyControls or DeviceActivity schedule APIs directly.

## Evidence

`DeenFirstActivityReport/DeenFirstActivityReport.entitlements:5`:
```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

`Project.swift:218` — ActivityReport only links `DeviceActivity` framework (no FamilyControls).

mindcore `monitorExtension/monitorExtension.entitlements:3-4` — also has `family-controls: true` (suggesting Apple may require it for DeviceActivityReport extensions).

mindcore `ScreenTimeMonitor/ScreenTimeMonitor.entitlements` — only has App Group (no family-controls).

## Solution

Retain `family-controls: true` in `DeenFirstActivityReport.entitlements`. The mindcore known-working example includes it. Apple likely requires it for an extension that registers as a `com.apple.deviceactivityui.report-extension` even if no direct FamilyControls API calls are made in the extension code.

## Why

Removing the entitlement risks an OS refusal to load the extension. The presence is consistent with the working reference. No action needed — this is a documentation/awareness finding only.
