---
id: 123
title: Disabling Hard Mode also clears Lock Editing — contradicts DF-16 product spec
severity: P2
area: lock-editing
ticket: DF-16
status: fixed
resolution: option 1 (restore spec) — user decision 2026-05-29
---

## Resolution (applied 2026-05-29)

User chose **restore the spec** (lock persists when Hard Mode is disabled):
- `PendingChangeService.swift` `.disableHardMode` case: removed `$0.isLockEditingEnabled = false`; now sets only `$0.isHardMode = false`.
- `HardModeLockEditingIntegrationTests.swift:324-327`: flipped to `XCTAssertTrue(... isLockEditingEnabled ...)` — Lock Editing must remain ON when only Hard Mode is disabled.
- Supersedes prior finding `../2026-04-24/043-...` (its symmetry-based "fix" contradicted the DF-16 product spec and is now reverted).

---

## Problem

DF-16's product spec is explicit and reasoned:

> "When Hard Mode is turned OFF (after 24hr delay via PendingChangeService): **Lock Editing remains ON — it must be turned off separately by the user.**"
> Acceptance criterion: "**Lock Editing does NOT turn off automatically when Hard Mode is turned off.**"

The current code does the opposite: applying a `.disableHardMode` pending change clears **both** flags.

This is **not** ticket-drift (code correct / ticket stale). The contradicting behavior was introduced by code-quality audit finding `../2026-04-24/043-disable-hardmode-pending-apply-doesnt-clear-lock.md`, whose rationale is an internal-consistency argument ("Hard Mode and Lock Editing are force-coupled on enable but decoupled on disable; this asymmetry means…") — an auditor's symmetry guess, **not** a documented product decision, and it never referenced or reconciled against DF-16. The asymmetry 043 "fixed" was the intended product design.

## Evidence

- Spec: DF-16 acceptance criteria (Linear), quoted above.
- Code (the regression): `deenfirst/Sources/Domain/Services/PendingChangeService.swift:192-196`
  ```swift
  case .disableHardMode:
      applyFlagUpdate(ruleId: change.ruleId) {
          $0.isHardMode = false
          $0.isLockEditingEnabled = false   // <- contradicts DF-16
      }
  ```
- Corroborating signal: a **separate** `.disableLockEditing` PendingChangeType exists (`PendingChangeService.swift:197-198`) precisely so Lock Editing can be turned off on its own — exactly DF-16's "turned off separately by the user." If disabling Hard Mode auto-cleared the lock, a distinct disable-lock operation would be redundant.
- The integration test `HardModeLockEditingIntegrationTests.swift:324-327` asserts the *current* (043) behavior. A test asserting X is not evidence X is intended — it encodes whatever 043 decided.
- Accountability impact: turning off Hard Mode currently *also* removes the 24h edit lock in one step, weakening the friction that DF-16/022 call the core V2 value proposition. Per spec, exiting the locked state should require its own separate 24h wait.

## Solution

**Needs a product decision** — do not auto-fix. Two outcomes:

1. **If DF-16 is authoritative (recommended by the evidence):** remove the `$0.isLockEditingEnabled = false` line in the `.disableHardMode` case so the lock persists; flip `HardModeLockEditingIntegrationTests.swift:324-327` to assert Lock Editing stays ON; close finding 043 as a misclassification (it contradicted the spec). One-line code change + one test change.
2. **If the coupled-disable behavior is genuinely wanted:** keep the code, and update DF-16's acceptance criteria + add a UX disclosure when disabling Hard Mode that Lock Editing will also lift.

## Why

P2 (043 originally rated it P1): it's a one-path behavior (disable Hard Mode on a locked rule), but it directly contradicts an explicit, reasoned product criterion and silently weakens the V2 accountability model. The core issue is that two audits (043 and this conformance pass) reached opposite conclusions because 043 never checked the product spec — this is exactly the conflict a Linear-conformance audit exists to surface.
