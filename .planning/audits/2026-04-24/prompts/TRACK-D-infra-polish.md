# TRACK D — Infra polish: Project.swift + signing + extensions hygiene

**Parallelizable with Tracks A, B, C, E.**
**Depends on:** Wave 1 merged to `main` (which already includes the Wave 0 Project.swift P0 commit).
**Estimated time:** ~3 hours.

---

## Copy-paste this prompt into the Track D session

You are implementing Track D of the 2026-04-24 audit remediation for the Deen First iOS app.

Read these before writing any code:
- `.claude/CLAUDE.md`
- `.claude/rules/tuist.md` — read fully. Every rule here matters.
- `.claude/rules/folder-structure.md`
- `.claude/rules/naming.md`
- `.claude/rules/error-handling.md` — for logging conventions

Route implementation through the `deenfirst-infra` agent (this track is infra-owned). Use `deenfirst-ios` only if you need to adjust imports in main-app source files as a side effect of audit 004. No tests to delegate — infra changes are validated by `make build` and signing.

### What this track owns

This track finishes the Tuist / entitlements / extension hygiene pass. Wave 0 already fixed the P0 extension product-type issue (001, 090, 097) and bumped version + partial profile-name fixes. Track D closes the long tail: signing naming consistency, target sources, entitlements audit, SPM cleanup, extension logging.

**Files you own (other tracks will NOT touch these):**
- `Project.swift`
- `Tuist/Package.swift`
- `Extensions/ScreenTimeMonitor/**` — logging conversion only
- `Extensions/Shield/**` — plist / entitlement only
- `Extensions/DeenFirstActivityReport/**` — plist / entitlement only
- `deenfirst/Sources/Shared/ScreenTimeEvents.swift` — per audit 004

**Files you must NOT touch:**
- Main-app source files except the narrow moves required by audit 004.
- Anything inside `Presentation/**`, `Domain/Services/**`, `Data/**` — other tracks own those.

### Audits to implement

Read each audit file under `.planning/audits/2026-04-24/` before touching the relevant code. 12 findings total.

**Signing + naming:**
- `091-shield-profile-name-inconsistency.md` (P1) — Shield profile named `"Deen First Shield Distribution"` (with space) conflicts with other targets' `"DeenFirst ..."` (no space).
- `092-app-main-profile-name-with-space.md` (P2) — main app profile name still has inconsistency.

**Target config:**
- `094-tests-target-missing-shared-sources.md` (P2) — the tests target sources block doesn't include `Shared/`; tests can't import shared types.
- `095-main-app-frameworks-in-other-ldflags.md` (P2) — stray frameworks in `OTHER_LDFLAGS` that should be handled via `dependencies` or `frameworks`.
- `096-companyid-env-var-unused.md` (P3) — `companyId` environment variable is referenced but unused; delete.
- `101-bottomsheet-unused-dependency.md` (P3) — `BottomSheet` SPM dependency has no call sites; remove from `Tuist/Package.swift`.

**Extension config:**
- `098-shield-missing-shared-sources.md` (P3) — Shield target sources don't include `Shared/`.
- `099-app-group-entitlements-consistent.md` (P3) — verify every target with App Group needs has the entitlement, and no target without the need has it.
- `100-activity-report-family-controls-entitlement.md` (P2) — DeenFirstActivityReport needs `com.apple.developer.family-controls` entitlement to render blocking data.

**Extension imports (must be done BEFORE target sources changes):**
- `004-screentime-events-forbidden-imports.md` (P2) — `Shared/ScreenTimeEvents.swift` imports something forbidden for extension targets. Either split the file into an extension-safe core + a main-app-only extension, or move the forbidden import path elsewhere. The fix must preserve the "extensions only pull from Shared/" rule.

**Logging:**
- `062-print-in-screentimemonitor-extension.md` (P1)
- `112-print-in-screentimemonitor-extension.md` (P1) — DUPLICATE of 062. One fix closes both.
  Replace all `print()` in `Extensions/ScreenTimeMonitor/**` with `os_log` via:
  ```swift
  import os
  private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "ScreenTimeMonitor")
  ```

### Cross-track coordination

- **Track A — audit 093.** `NSSpeechRecognitionUsageDescription`. If Track A hasn't already added this to Project.swift, add it here as part of your infoPlist pass (main app target). If Track A's PR is open with that key, rebase and leave their version.
- **Track B — audit 055 (BGTaskScheduler).** Track B registers a background task handler with identifier `com.aydev.deenfirst.pending-apply`. Add this identifier to Project.swift main-app `infoPlist`:
  ```swift
  "BGTaskSchedulerPermittedIdentifiers": ["com.aydev.deenfirst.pending-apply"]
  ```
  If Track B's PR comments ask you to add it, include it. If neither track has mentioned it yet, check Track B's branch / PR description before opening your own PR.

### Order of work

Run `make generate && make build` after each logical chunk — NOT just at the end. Tuist changes are fragile and the sooner you catch a mistake the cheaper it is.

1. **Audit 004 first.** This determines whether `ScreenTimeEvents.swift` stays in `Shared/` or splits. Decide BEFORE editing Project.swift target sources, because Shield and ActivityReport include `Shared/` by glob (audit 098 also depends on this).
   - If the forbidden import can be isolated: move it to a main-app-only file (e.g., `deenfirst/Sources/Domain/Services/ScreenTimeEventsPublisher.swift`) and keep the pure types in `Shared/ScreenTimeEvents.swift`.
   - If not: split into `Shared/ScreenTimeEvents+Core.swift` (extension-safe) and `Shared/ScreenTimeEvents+AppOnly.swift` (excluded from extension target sources).
   - After the move: grep confirms no `import SwiftData`, no `import Alamofire`, no network imports survive in anything the extensions pull from `Shared/`.
   - Commit: `refactor(shared): isolate extension-safe ScreenTimeEvents core (DF-004)`

2. **Target sources + entitlements sweep (094, 095, 098, 099, 100).** In one disciplined pass over `Project.swift`:
   - 094: tests target sources include `Shared/**/*.swift`.
   - 095: remove stray entries from main app `OTHER_LDFLAGS`; express framework needs via `dependencies` on the target.
   - 098: Shield target sources include `Shared/**/*.swift`.
   - 099: run through every target's `entitlements` block; every target using App Groups has `com.apple.security.application-groups`. Every target NOT using App Groups does NOT have it. ActivityReport needs App Group READ but not write — document in a comment.
   - 100: ActivityReport target entitlements block adds `com.apple.developer.family-controls = [true]`.
   - After this chunk: `make generate && make build && make test` must pass.
   - Commit: `fix(tuist): target sources + entitlements sweep (DF-094, DF-095, DF-098, DF-099, DF-100)`

3. **Signing profile names (091, 092).** Audit every `provisioningProfileSpecifier` string across all targets. Canonical form: `"DeenFirst <Target> Distribution"` (no space in "DeenFirst"). Fix any lingering `"Deen First ..."`. Wave 0 already fixed some; sweep for the rest.
   - Commit: `fix(tuist): unify provisioning profile names to DeenFirst (no space) (DF-091, DF-092)`

4. **SPM cleanup (101) + env var cleanup (096).**
   - 101: remove `BottomSheet` from `Tuist/Package.swift` dependencies. Run `make install && make generate`.
   - 096: delete the `companyId` env var reference from Project.swift.
   - Commit: `chore(tuist): remove unused BottomSheet dep and companyId env var (DF-096, DF-101)`

5. **ScreenTimeMonitor logging (062 / 112).** In every `.swift` file under `Extensions/ScreenTimeMonitor/`:
   - At top: `import os` + `private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "ScreenTimeMonitor")`.
   - Replace every `print("...")` with a level-appropriate `logger.<level>("...")`:
     - Routine state: `logger.info(...)`
     - Unexpected conditions that don't fail: `logger.warning(...)` (or `.notice` if you prefer)
     - Failures: `logger.error(...)`
   - Privacy: for any user-identifying string (rule names, user IDs) use `"\(value, privacy: .private)"`.
   - After this chunk: extension compiles; `os_log` entries appear in Console.app filtered on subsystem `com.aydev.deenfirst`.
   - Commit: `refactor(screentime-monitor): print to os_log (DF-062, DF-112)`

6. **Optional: plist additions (093, 055).** Only if the cross-track coordination notes above say so. Otherwise skip.
   - Commit (if needed): `fix(tuist): add infoPlist keys for speech recognition + BGTaskScheduler (DF-093, DF-055)`

### Rules

- Never edit `.xcodeproj` — changes only via `Project.swift`.
- App Group suite name ONLY via `AppGroupConstants.suiteName` in source; never inline `"group.com.aydev.deenfirst"`.
- No `SwiftData`, no `Alamofire`, no network imports inside ANY file under an extension target's sources (or under `Shared/` if that file is pulled in by an extension target).
- ActivityReport extension: READ-ONLY to App Group. Do not add write paths anywhere in its source.
- After ANY `Project.swift` change, run `make generate` before `make build`. After any `Package.swift` change, run `make install` before `make generate`.
- Never commit unless `make build && make test` pass.

### Verification before PR

- `make clean && make install && make generate && make build && make test` all green from a clean state.
- **Archive build locally.** Signing issues won't show up in `make build` — they surface during archive. Run a local archive to validate provisioning profile names; `codesign` will fail on any stale `"Deen First ..."` profile name that escaped audits 091/092.
- **Physical device check.** Confirm the ActivityReport extension loads:
  - Filter `Console.app` on subsystem `com.aydev.deenfirst` — you should see both main-app and extension log entries.
  - Open the dashboard (post-Wave-1 UI) — the extension process should render content, not fall back silently.

### PR

- Target: `main`.
- Title: `chore(tuist): track D — infra polish + signing + extension hygiene (DF-004, 062, 091, 092, 094, 095, 096, 098, 099, 100, 101, 112)`
- Describe: list every target whose sources/entitlements changed; note any cross-track coordination items (093, 055) that landed here or were deferred.
