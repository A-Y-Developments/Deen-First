---
id: 094
title: DeenFirstTests target does not include Shared/ in sources — tests it via main app dependency
severity: P2
area: infra
status: open
---

## Problem

`DeenFirstTests` has `sources: ["deenfirst/Tests/**"]` and depends on `.target(name: "DeenFirst")`. The `DeenFirst` target includes `sources: ["deenfirst/Sources/**"]` which contains `Shared/`. So `DeenScoreCalculatorTests.swift` can reach `DeenScoreCalculator` only transitively via the main app target — not directly.

This is indirect but functional. The problem is that if `DeenScoreCalculator.swift` is ever moved out of `Sources/**` and into a standalone target (the correct long-term architecture, since it must also be compiled into `DeenFirstActivityReport`), the tests would break without an explicit `Shared/` dependency.

Current state: `Shared/` is compiled twice:
1. Into `DeenFirst` (via `Sources/**` glob)
2. Into `ScreenTimeMonitor` and `DeenFirstActivityReport` (via explicit `Shared/**` sources)

This double-compilation means `AppGroupConstants` and `DeenScoreCalculator` are distinct types across module boundaries — no actual Swift module sharing. This is the correct approach for extension isolation, but it means tests run the main-app copy, not the extension copy.

## Evidence

`Project.swift:246-255`:
```swift
.target(
    name: "DeenFirstTests",
    ...
    sources: ["deenfirst/Tests/**"],
    dependencies: [
        .target(name: "DeenFirst")  // no explicit Shared/** source
    ]
)
```

Test file confirmed at: `deenfirst/Tests/Shared/DeenScoreCalculatorTests.swift:5`.

## Solution

This is acceptable for now since `DeenScoreCalculator` is a pure function with no extension-only behavior. Document the design: the test exercises the main-app compilation of `DeenScoreCalculator`, which is identical source to the extension compilation.

If a future refactor moves `Shared/` into its own Tuist framework target, add it explicitly to `DeenFirstTests` dependencies at that point.

No immediate code change required — flag for future refactor tracking.

## Why

No functional defect today. The risk is future silent test gap if source paths change. Low priority but worth noting for the architect.
