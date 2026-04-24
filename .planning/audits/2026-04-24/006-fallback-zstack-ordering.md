---
id: 006
title: Fallback placeholder rendered behind DeviceActivityReport in ZStack; hidden when report renders blank view
severity: P2
area: dashboard
status: closed
---

## Problem

`DashboardTabView` wraps the `DeviceActivityReport` and a fallback placeholder in a `ZStack`. In SwiftUI's `ZStack`, views declared first are rendered at the bottom of the z-axis stack (behind later views). The fallback is declared first, so it always renders behind the `DeviceActivityReport` view. When the extension is not yet registered (or returns a blank/empty view), the `DeviceActivityReport` host still renders an opaque view frame that occludes the fallback. Users see a blank white region rather than the intended "loading / not available" placeholder.

## Evidence

`DashboardTabView.swift` lines 24–30:
```swift
ZStack {
    fallbackPlaceholder          // Z-order: bottom (behind)
    DeviceActivityReport(context, filter: filter)   // Z-order: top (in front)
        .id(refreshNonce)
}
```

The expected behavior: show fallback when extension is unavailable; show report when extension renders content. The current stacking order makes this impossible because the report view is always on top regardless of its content.

## Solution

Invert the stack or use conditional rendering. Preferred pattern — conditional rendering with `@State var reportLoaded: Bool`:

```swift
Group {
    if reportLoaded {
        DeviceActivityReport(context, filter: filter)
            .id(refreshNonce)
            .onAppear { reportLoaded = true }
    } else {
        fallbackPlaceholder
            .onAppear { triggerExtensionCheck() }
    }
}
```

Alternatively, if a loaded/error state signal isn't available, keep the ZStack but invert the order and give the report a transparent background so the fallback shows through when the report is empty:

```swift
ZStack {
    DeviceActivityReport(context, filter: filter)  // bottom
        .id(refreshNonce)
    fallbackPlaceholder                             // top, only shown if report is empty
        .opacity(extensionUnavailable ? 1 : 0)
}
```

The conditional rendering approach is cleaner since it avoids rendering both views simultaneously.

## Why

SwiftUI `ZStack` renders children in declaration order, back-to-front. The last-declared child sits on top. Putting the placeholder first and the report second means the report always occludes the placeholder. Apple's `DeviceActivityReport` host view does not expose a loading or error callback, so detecting unavailability requires either a timeout heuristic or an app-side state variable set after the extension is confirmed loaded. The fix must either invert the visual layering or switch to conditional rendering.
