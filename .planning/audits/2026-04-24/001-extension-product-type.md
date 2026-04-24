---
id: 001
title: DeenFirstActivityReport committed as wrong product type (.appExtension)
severity: P0
area: dashboard
status: open
---

## Problem

The committed state of `Project.swift` declares `DeenFirstActivityReport` as `product: .appExtension` with `NSExtension.NSExtensionPointIdentifier = "com.apple.deviceactivity.report"`. This is the legacy NSExtension format. iOS 17 DeviceActivity Report extensions must be `product: .extensionKitExtension` (ExtensionKit) with `EXAppExtensionAttributes.EXExtensionPointIdentifier = "com.apple.deviceactivityui.report-extension"`. With the wrong product type and identifier, the system never registers the extension and `DeviceActivityReport(context:filter:)` renders nothing in the host app.

There is an uncommitted working-tree change in `Project.swift` that switches to the correct values, but it has not been committed or tested.

## Evidence

`Project.swift` lines 199–210 (committed state, before working-tree diff):
```swift
product: .appExtension,
// ...
"NSExtension": [
    "NSExtensionPointIdentifier": "com.apple.deviceactivity.report",
    "NSExtensionPrincipalClass":
        "$(PRODUCT_MODULE_NAME).DeenFirstActivityReportExtension",
],
```

Working-tree diff (correct but uncommitted):
```diff
-product: .appExtension,
+product: .extensionKitExtension,
-"NSExtension": [
-    "NSExtensionPointIdentifier": "com.apple.deviceactivity.report",
-    "NSExtensionPrincipalClass":
-        "$(PRODUCT_MODULE_NAME).DeenFirstActivityReportExtension",
+"EXAppExtensionAttributes": [
+    "EXExtensionPointIdentifier": "com.apple.deviceactivityui.report-extension",
```

Reference (mindcore, `/Users/adithyafp_/Projects/mindcore/monitorExtension/Info.plist`):
```xml
<key>EXAppExtensionAttributes</key>
<dict>
    <key>EXExtensionPointIdentifier</key>
    <string>com.apple.deviceactivityui.report-extension</string>
</dict>
```

`DeenFirstActivityReportExtension.swift` already uses `@main` and `DeviceActivityReportExtension` (ExtensionKit protocol) — so the Swift code is correct; only the Tuist manifest is wrong in the committed state.

## Solution

1. Commit the working-tree change to `Project.swift` as-is (it is already correct).
2. Remove `NSExtensionPrincipalClass` from the infoPlist block — ExtensionKit uses `@main`, not a principal class key.
3. Run `make generate` to regenerate the Xcode project.
4. Rebuild and verify the extension appears in the OS extension registry (Settings → Screen Time → App Activity).

## Why

`com.apple.deviceactivity.report` is the extension point for the old `NSExtension`-based DeviceActivity monitor (ScreenTimeMonitor target). Report extensions introduced in iOS 16+ use ExtensionKit (`product: .extensionKitExtension`) and the point identifier `com.apple.deviceactivityui.report-extension`. Using the wrong product type means Tuist generates a legacy app extension bundle structure; the OS DeviceActivity UI framework never discovers it when `DeviceActivityReport(context:filter:)` is instantiated in the host.
