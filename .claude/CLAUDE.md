# Deen First — Project Rules

## What is Deen First
Islamic productivity app for iOS. Blocks distracting apps and builds a Quran reading habit through Screen Time APIs. V2 adds meaningful accountability friction: Tiered Unblock, Hard Mode, Lock Editing, Custom Ayah Pool, Dashboard & Deen Score.

**Platform:** iOS 17+ only. Swift. SwiftUI. Tuist. No Android.

---

## Stack (locked)

- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **State:** `@Published` + `@StateObject` / `@ObservedObject`; `@MainActor final class` ViewModels
- **Data:** SwiftData (`@Model`)
- **Build:** Tuist (`Project.swift` + `Tuist/`)
- **Screen Time:** `DeviceActivity` + `ManagedSettings` + `FamilyControls`
- **Recitation:** OpenAI Whisper API (via `HTTPClient`)
- **Subscriptions:** RevenueCat (`Purchases`)
- **Audio:** `AVFoundation`
- **Auth:** Sign in with Apple
- **Notifications:** `UserNotifications`
- **Cross-process:** App Groups (`group.com.aydev.deenfirst`)
- **HTTP:** `Alamofire` via `HTTPClient`

---

## Architecture (mandatory — no exceptions)

```
Presentation (View + ViewModel)
  └── Domain (Service + Entity)
        └── Data (Repository + DataSource)
```

### Hard rules

1. **DIContainer** — all services accessed via `DIContainer.shared`. Never instantiate services directly in Views or ViewModels.
2. **@MainActor** — all ViewModels are `@MainActor final class`. Use `Task { }` for async ops.
3. **No force unwrap** — ever. Use `guard let`, optional chaining, or `if let`.
4. **Async/await** — use async/await + do/catch with explicit loading states. No completion handlers.
5. **SwiftData** — `@Model` entities only. Access via service layer — never query ModelContext directly from ViewModels.
6. **App Group** — cross-process data via `AppGroupConstants`. Never hardcode keys inline.
7. **No direct Whisper/API calls from Views** — always goes through ViewModel → Service.
8. **Tuist** — all target/dependency changes go in `Project.swift`. Never manually edit `.xcodeproj`.
9. **Extensions** — ScreenTimeMonitor, Shield, DeenFirstActivityReport are separate targets. No SwiftData in extensions. No network calls in DeenFirstActivityReport.
10. **os_log not print()** — in extensions. Main app can use print() in debug only.

---

## Tuist Commands

```bash
make generate    # tuist generate (after Project.swift changes)
make install     # tuist install (after Package.swift changes)
make build       # xcodebuild release build
make test        # xcodebuild tests
make clean       # tuist clean
make edit        # open Project.swift in Xcode
```

Run `make generate` after any `Project.swift` change before coding.

---

## Agent Roles

4 agents — route to the correct one based on ticket labels:

| Label | Agent | Domain |
|---|---|---|
| `Agent-iOS` | `deenfirst-ios` | Main app: Views, ViewModels, Services, Entities, Repositories |
| `Agent-Infra` | `deenfirst-infra` | Tuist, extensions, App Groups, signing, CI |
| `Agent-QA` | `deenfirst-qa` | XCTest unit + integration tests |
| `Human Touch` | — | Manual QA steps requiring physical device |

---

## Branching Strategy

- **`main`** = latest codebase (trunk). All new work branches from here and PRs back into it.
- **`release/v1.0.0`** = snapshot of V1 state. Used as base for V1 hotfixes only.
- V1 hotfix flow: branch from `release/v1.0.0` → fix → merge into `release/v1.0.0` → cherry-pick to `main`.
- No long-lived integration branches.

## Linear Workflow

- All work starts from a Linear ticket (`/linear-start`)
- Branches: `feature/df-{number}-{slug}` (e.g. `feature/df-12-hard-mode-toggle`), cut from `main`
- Commit format: `feat(scope): message` / `fix(scope): message`
- PRs target `main` and are linked to Linear ticket before merge
- Milestone runner: `/run-milestone`

---

## Commit Format

```
feat(scope): concise message
fix(scope): concise message
refactor(scope): concise message
chore(scope): concise message
```

Examples:
- `feat(lock-editing): add PendingChangeService with 24hr delay`
- `fix(recite): correct threshold in Hard Mode`
- `chore(tuist): add DeenFirstActivityReport target`

No AI attribution in commits, PRs, or code comments.

---

## Critical Don'ts

- Never hardcode App Group suite name — always use `AppGroupConstants.suiteName`
- Never query SwiftData from Views — always through ViewModel → Service
- Never skip `make generate` after `Project.swift` changes
- Never add new Xcode targets manually — always through `Project.swift`
- Never use completion handlers — async/await only
- Never `print()` in extension targets — use `os_log`
- Never make network calls inside `DeenFirstActivityReport` extension
- Never write to App Group from extension — read only for `DeenFirstActivityReport`
- Never test `DeenFirstActivityReport` on simulator — physical device only
