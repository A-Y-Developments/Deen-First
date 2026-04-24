---
id: 029
title: showPoolNudge never reset to false — nudge banner persists for entire ViewModel lifetime
severity: P2
area: unblock
status: open
---

## Problem

`ReciteToUnblockViewModel.showPoolNudge` is set to `true` by `maybeShowPoolNudge()` but is never reset to `false` within the same ViewModel instance. Once shown, the nudge banner remains visible for the remainder of the session (until the ViewModel is deallocated). This means after dismissing the nudge and retrying, the banner immediately reappears.

## Evidence

`ReciteToUnblockViewModel.swift`:

```swift
@Published var showPoolNudge: Bool = false   // never set to false after being true

private func maybeShowPoolNudge() {
    // ... date check logic ...
    showPoolNudge = true
    // no corresponding reset
}
```

No call to `showPoolNudge = false` exists anywhere in the file. The nudge dismiss handler (if any) in the View calls `vm.dismissPoolNudge()` but that method either doesn't exist or doesn't reset the flag.

## Solution

Add a `dismissPoolNudge()` method that sets `showPoolNudge = false` and call it from the View's dismiss action:

```swift
func dismissPoolNudge() {
    showPoolNudge = false
}
```

Also call `showPoolNudge = false` inside `retry()` and `resetToStart()` so the nudge doesn't re-appear on ayah retry.

## Why

Published booleans controlling transient UI (banners, nudges, toasts) must be explicitly reset. The nudge is designed to appear once per session or once per N days — but a stuck `true` makes it appear on every retry within the same ViewModel lifecycle, breaking the intended UX cadence.
