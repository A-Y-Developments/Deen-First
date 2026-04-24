---
id: 064
title: DispatchQueue + completion handler in SummaryViewModel violates async/await rule
severity: P1
area: arch
status: closed
---

## Problem

`SummaryViewModel.swift:103` declares `startCalculation(screenWidth:onComplete:)` with an `@escaping () -> Void` completion handler, and `lines 123-128` use `DispatchQueue.main.asyncAfter` to schedule navigation. `lines 136-140` use additional `DispatchQueue.main.asyncAfter` calls for animation. This violates CLAUDE.md hard rule 4 ("No completion handlers — async/await only").

## Evidence

`SummaryViewModel.swift:103`:
```swift
func startCalculation(screenWidth: CGFloat, onComplete: @escaping () -> Void) {
```

`SummaryViewModel.swift:123-128`:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    self.ellipsisTimer?.invalidate()
    self.ellipsisTimer = nil
    self.isCalculating = false
    onComplete()
}
```

`SummaryViewModel.swift:136`:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + (delay * Double(i))) {
```

Additionally `Timer.scheduledTimer(withTimeInterval:repeats:block:)` at line 110 uses a non-`[weak self]` closure on a `@MainActor` class, capturing `self` strongly (technically safe due to @MainActor, but non-idiomatic).

## Solution

Replace `startCalculation` with an `async` function:
```swift
func startCalculation(screenWidth: CGFloat) async {
    // setup...
    try? await Task.sleep(for: .seconds(5))
    ellipsisTimer?.invalidate()
    isCalculating = false
}
```
Call site: `Task { await summaryViewModel.startCalculation(screenWidth: proxy.size.width); onComplete() }`.

For the percentage animation, use `Task { for i in 1...100 { try? await Task.sleep(for: .milliseconds(50)); percentage = i } }`.

## Why

`DispatchQueue` + `@escaping` callbacks are explicitly banned by CLAUDE.md rule 4. This pattern also mixes GCD and Swift concurrency, creating implicit threading assumptions. async/await is composable, cancellable, and the project standard.
