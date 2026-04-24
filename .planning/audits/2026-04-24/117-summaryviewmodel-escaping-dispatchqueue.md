---
id: 117
title: SummaryViewModel uses @escaping closure + DispatchQueue — violates async/await rule
severity: P2
area: code-quality
status: closed
---

## Problem

`SummaryViewModel.startCalculation(screenWidth:onComplete:)` accepts an `@escaping () -> Void` completion handler and drives animation via `Timer.scheduledTimer` and `DispatchQueue.main.asyncAfter`. This violates the project rule: "Async/await — use async/await + do/catch with explicit loading states. No completion handlers."

The method also uses `Timer.scheduledTimer` which is a V1 pattern not compatible with Swift concurrency structured task cancellation.

## Evidence

`deenfirst/Sources/Presentation/Summary/SummaryViewModel.swift`
```swift
func startCalculation(screenWidth: CGFloat, onComplete: @escaping () -> Void) {
    Timer.scheduledTimer(...) { _ in
        // ...
        DispatchQueue.main.asyncAfter(...) {
            onComplete()
        }
    }
}
```

## Solution

Rewrite as an `async` method using `Task.sleep` for the animation delay:

```swift
@MainActor
func startCalculation(screenWidth: CGFloat) async {
    // animation steps using await Task.sleep(nanoseconds:)
    // caller: Task { await viewModel.startCalculation(screenWidth: ...) }
}
```

Or, if animation state is purely UI-driven, move the timer logic into the View using `.task { }` and `@State`.

## Why

Completion handlers create a lifecycle gap — the closure may fire after the ViewModel is deallocated or after the View has been dismissed. `@MainActor` ViewModels combined with completion handlers bypass the actor isolation guarantees Swift concurrency provides. The async/await rule exists precisely to eliminate this class of bug.
