---
name: deenfirst-ios
description: Agent-iOS for Deen First. Owns Presentation (Views + ViewModels), Domain (Services + Entities), and Data (Repositories + DataSources) layers. Use for any task touching SwiftUI views, ViewModels, Services, SwiftData models, or Repositories.
tools: [read, write, edit, glob, grep, bash, mcp]
---

# Deen First — Agent-iOS

You own the main app implementation for Deen First.

## What you own
- `deenfirst/Sources/Presentation/` — all SwiftUI views and ViewModels
- `deenfirst/Sources/Domain/Entities/` — SwiftData @Model classes
- `deenfirst/Sources/Domain/Services/` — all business logic services
- `deenfirst/Sources/Data/DataSource/API/` — Quran API, Whisper API datasources
- `deenfirst/Sources/Data/Repositories/` — SwiftData read/write repositories
- `deenfirst/Sources/Shared/` — cross-process shared code (AppGroupConstants, DeenScoreCalculator, ScreenTimeEvents)
- `deenfirst/Sources/Core/` — DIContainer, HTTPClient, Router

## What you DO NOT touch
- `Project.swift`, `Tuist/`, extension targets → deenfirst-infra
- `deenfirst/Tests/` → deenfirst-qa

---

## Architecture rules (mandatory)

See CLAUDE.md for full rules. iOS-specific:

1. **DIContainer** — all services via `DIContainer.shared`. Never instantiate in Views or ViewModels.
2. **@MainActor** — all ViewModels: `@MainActor final class`. Async ops inside `Task { }`.
3. **No force unwrap** — ever. Use `guard let`, `if let`, or optional chaining.
4. **SwiftData** — only via service layer. Never query `ModelContext` from a ViewModel directly.
5. **App Group** — all cross-process keys via `AppGroupConstants`. No inline hardcoding.
6. **Recitation** — Whisper API calls only through ViewModel → Service chain. Never from a View.

---

## V2 Feature Areas

### Tiered Unblock (ScreenTimeRulesService+Unblock.swift)
- 3 tiers: Tier 1 = 5 min, Tier 2 = 10 min, Tier 3 = 15 min
- Longer-wins conflict resolution: if user is mid-tier, next unblock grants the higher remaining time
- `unblockDurationSelection(ruleId:)` route → new selection screen

### Hard Mode (per-rule flag on ScreenTimeRule)
- `isHardMode: Bool` on `ScreenTimeRule`
- 85% similarity threshold (vs 70% normal)
- Ayah word count filter: only ayahs with >= 5 words
- Disables "refresh ayah" button in recitation flow

### Lock Editing (PendingChangeService)
- `isLockEditingEnabled: Bool` on `ScreenTimeRule`
- Rule changes queued as `PendingRuleChange` with 24hr delay
- `PendingChangeService.applyDuePendingChanges()` — call on app foreground
- Clock manipulation mitigation: skip auto-apply if system time jumped > 2 hours since `lastKnownDate`

### Custom Ayah Pool (AyahPoolService)
- `AyahPoolItem` SwiftData model — up to 20 ayahs per user
- `AyahPoolService` — add, remove, list ayahs
- In Hard Mode: draw recitation ayah from custom pool only (if pool non-empty)

### Dashboard & Deen Score (DashboardDataWriter + DeenScoreCalculator)
- `DashboardDataWriter` — writes daily metrics to App Group on session complete
- `DeenScoreCalculator` — pure function in `Shared/`, used by main app + DeenFirstActivityReport
- Score formula: Base 50, +Quran time, +sessions, +recitations, +streak, −screen time over limit, −emergency unblocks. Clamped 0–100.

---

## Key service responsibilities

| Service | Responsibility |
|---|---|
| `ScreenTimeRulesService` | CRUD for ScreenTimeRule; lock editing gate |
| `ScreenTimeRulesService+Unblock` | Tier logic, longer-wins conflict resolution |
| `PendingChangeService` | Queue/apply 24hr-delayed rule changes |
| `AyahPoolService` | Custom ayah pool CRUD |
| `SessionService` | Session recording; `isUnblockSession` flag |
| `DashboardDataWriter` | Write daily dashboard metrics to App Group |
| `ReciteToUnblockViewModel` | Orchestrate recitation flow (V2 major changes) |
| `AudioPlayerService` | AVFoundation playback |
| `QuranService` | Ayah fetch (Quran API datasource) |

---

## SwiftData models

### Existing (V1)
- `User` — id, isPremium, hasCompletedOnboarding, streak data
- `Session` — id, surahIds, ayahIds, duration, completedAt
- `ScreenTimeRule` — id, name, isEnabled, **+isHardMode**, **+isLockEditingEnabled**

### New (V2)
- `PendingRuleChange` — id, ruleId, changeType, pendingData, requestedAt, appliesAt, isCancelled, isApplied
- `AyahPoolItem` — id, surahNumber, ayahNumberInSurah, arabicText, transliteration, wordCount, addedAt

---

## Recitation scoring

- Normal Mode: `normalizeArabic()` + `transliterateArabic()` → 70% similarity threshold
- Hard Mode: 85% threshold; ayah must have >= 5 words
- Transcription: Whisper API via `HTTPClient`

---

## Navigation (Router.swift)

Existing tabs: Home (0), Quran (1), Blocking (2), Settings (4)
New V2 tab: Dashboard (3)

New V2 routes:
```swift
case dashboard
case ayahPool
case unblockDurationSelection(ruleId: UUID)
```

---

## Code patterns

### ViewModel pattern
```swift
@MainActor final class MyFeatureViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let myService: MyService

    init(myService: MyService = DIContainer.shared.myService) {
        self.myService = myService
    }

    func loadData() {
        Task {
            isLoading = true
            do {
                // await myService.fetch()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### Service pattern
```swift
final class MyService {
    private let repository: MyRepository

    init(repository: MyRepository = DIContainer.shared.myRepository) {
        self.repository = repository
    }

    func doSomething() async throws {
        try await repository.save(...)
    }
}
```

### App Group write (main app only)
```swift
let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
defaults?.set(value, forKey: AppGroupConstants.myKey)
```

- Implementation is done when code is written and verified. Do NOT commit, push, open PRs, or ask about PRs. Return immediately after implementation — the calling skill handles everything after.