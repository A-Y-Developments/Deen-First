---
id: 090
title: ActivityReport extension point identifier — working tree is correct, committed was wrong
severity: P0
area: infra
status: open
---

## Problem

The committed version of `Project.swift` used `product: .appExtension` with `NSExtension` / `NSExtensionPointIdentifier: "com.apple.deviceactivity.report"` — the old pre-iOS 16 App Extension style. This is wrong for the DeviceActivity Report extension on iOS 17+.

The working tree (current uncommitted) correctly uses:
- `product: .extensionKitExtension`
- `EXAppExtensionAttributes` dict
- `EXExtensionPointIdentifier: "com.apple.deviceactivityui.report-extension"`

## Evidence

`git diff Project.swift` (committed → working tree):
```
-product: .appExtension,
+product: .extensionKitExtension,

-"NSExtension": [
-    "NSExtensionPointIdentifier": "com.apple.deviceactivity.report",
-    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).DeenFirstActivityReportExtension",
+"EXAppExtensionAttributes": [
+    "EXExtensionPointIdentifier": "com.apple.deviceactivityui.report-extension",
```

mindcore reference — `Project.swift:169-176` — uses `product: .extensionKitExtension`. Its `monitorExtension/Info.plist` uses exactly:
```xml
<key>EXAppExtensionAttributes</key>
<dict>
    <key>EXExtensionPointIdentifier</key>
    <string>com.apple.deviceactivityui.report-extension</string>
</dict>
```

The generated `Derived/InfoPlists/DeenFirstActivityReport-Info.plist` (after `make generate` with working tree) shows `CFBundlePackageType: XPC!` — which is the correct package type for an ExtensionKit XPC extension, not the `APPL` or `APPEX` type that `.appExtension` produces.

The extension source itself (`DeenFirstActivityReportExtension.swift:5`) uses `@main struct ... : DeviceActivityReportExtension` — the ExtensionKit entry point protocol, not `NSExtensionPrincipalClass`. A `NSExtensionPrincipalClass` key pointing at a struct conforming to `DeviceActivityReportExtension` would fail to load at runtime.

## Solution

Keep the working tree as-is. Do NOT revert. The working tree is correct.

Additionally, remove the `NSExtensionPrincipalClass` key entirely — it is no longer present in the working tree (correctly omitted). Confirm this does not re-appear after any future `make generate` run.

## Why

Apple migrated `DeviceActivityReport` extensions from App Extension to ExtensionKit in iOS 16.2+. For iOS 17+ targets, the extension must:
1. Use product type `.extensionKitExtension` (generates `CFBundlePackageType: XPC!`)
2. Declare `EXAppExtensionAttributes` / `EXExtensionPointIdentifier` instead of `NSExtension` / `NSExtensionPointIdentifier`
3. Use `@main struct ... : DeviceActivityReportExtension` as entry point (not `NSExtensionPrincipalClass`)

The committed state would produce a bundle that the OS refuses to load as a report extension — the Dashboard would show nothing or crash. The working tree fix is correct and matches the known-working mindcore reference.
