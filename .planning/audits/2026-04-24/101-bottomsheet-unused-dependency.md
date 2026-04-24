---
id: 101
title: BottomSheet SPM dependency — no import found in source; may be unused
severity: P3
area: infra
status: open
---

## Problem

`Tuist/Package.swift:17` and `Project.swift:55` declare `BottomSheet` as an external dependency. No `import BottomSheet` statement was found in any Swift source file under `deenfirst/Sources/`.

## Evidence

`Tuist/Package.swift:17`: `.package(url: "https://github.com/lucaszischka/BottomSheet.git", from: "3.1.1")`

`Project.swift:55`: `.external(name: "BottomSheet")`

Grep for `import BottomSheet` across all `.swift` files in `deenfirst/Sources/` — zero results.

## Solution

1. Verify whether BottomSheet is actually used (search for `BottomSheet(`, `.bottomSheet`, or SwiftUI modifiers from the package).
2. If confirmed unused: remove from `Project.swift` dependencies array and `Tuist/Package.swift`.
3. Run `make install && make generate` after removal.

## Why

Unused SPM dependencies increase build time, Derived Data size, and add supply-chain risk. Worth a quick manual verification before removal since the grep may miss indirect usage via typealiases or conditional compilation.
