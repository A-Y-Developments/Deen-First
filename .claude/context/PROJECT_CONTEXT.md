# Deen First — Project Context

## Linear

- **Team:** Deen First
- **Team ID:** c3b07603-6cd1-40f7-ae85-7bf3f7a7471c
- **Team Key:** DF
- **Project:** Deen First V2
- **Project ID:** 57949de6-f6f2-4adc-9668-d117f75d1c80
- **PRD Doc:** https://linear.app/adithya-workspace/document/deen-first-v2-product-requirements-document-a6b8ef44d73c
- **Tech Spec:** https://linear.app/adithya-workspace/document/deen-first-v2-technical-specification-4a5776074cc9

## Timeline

| Milestone | Target |
|---|---|
| M0 — Foundation & Data Models | 2026-03-27 |
| M1 — Tiered Unblock System | 2026-04-01 |
| M2 — Hard Mode | 2026-04-03 |
| M3 — Lock Editing | 2026-04-06 |
| M4 — Custom Ayah Pool | 2026-04-07 |
| M5 — Dashboard & Deen Score | 2026-04-08 |
| M6 — QA & Ship | 2026-04-09 |

## Architecture

```
Presentation (View + ViewModel)
  └── Domain (Service + Entity)
        └── Data (Repository + DataSource)

Cross-process:
  Main App ──writes──► App Group (group.com.aydev.deenfirst)
  Extensions ──reads──► App Group + DeviceActivity framework
```

## Key Directories

```
deenfirst/Sources/
├── Core/
│   ├── DataDependency/DIContainer.swift     ← all service access
│   ├── Networking/HTTPClient.swift
│   └── SceneNavigation/Router.swift         ← Route enum + NavigationPath
├── Domain/
│   ├── Entities/                            ← SwiftData @Model classes
│   └── Services/                            ← business logic
├── Data/
│   ├── DataSource/API/                      ← Quran API, Whisper API
│   └── Repositories/                        ← SwiftData read/write
├── Presentation/
│   ├── MainTabs/
│   │   ├── HomeTab/
│   │   ├── QuranTab/
│   │   ├── BlockingTab/
│   │   ├── DashboardTab/                    ← NEW V2
│   │   └── SettingsTab/
│   ├── ReciteToUnblock/                     ← 4 files — core V2 change area
│   └── Components/                          ← 23 shared components
├── Shared/                                  ← shared with extensions
│   ├── AppGroupConstants.swift
│   ├── ScreenTimeEvents.swift
│   └── DeenScoreCalculator.swift            ← NEW V2
└── Utils/

deenfirst/Sources/Domain/Entities/
├── ScreenTimeRule.swift                     ← +isHardMode, +isLockEditingEnabled (V2)
├── PendingRuleChange.swift                  ← NEW V2
├── AyahPoolItem.swift                       ← NEW V2
├── user.swift
└── session.swift

deenfirst/Sources/Domain/Services/
├── ScreenTimeRulesService.swift             ← +lock editing gate (V2)
├── ScreenTimeRulesService+Unblock.swift     ← +tier logic, longer-wins (V2)
├── PendingChangeService.swift               ← NEW V2
├── AyahPoolService.swift                    ← NEW V2
├── DashboardDataWriter.swift                ← NEW V2
├── SessionService.swift                     ← +isUnblockSession flag (V2)
├── ReciteToUnblockViewModel.swift           ← major changes V2
├── AudioPlayerService.swift
├── QuranService.swift
└── ...
```

## Xcode Targets

| Target | Type | Bundle |
|---|---|---|
| `DeenFirst` | Main App | `$(BASE_BUNDLE_ID)` |
| `ScreenTimeMonitor` | DeviceActivityMonitor Ext | `...ScreenTimeMonitor` |
| `Shield` | ShieldConfiguration Ext | `...Shield` |
| `DeenFirstActivityReport` | **NEW** DeviceActivityReport Ext | `...ActivityReport` |

## App Group

Suite: `group.com.aydev.deenfirst`

All cross-process keys defined in `AppGroupConstants.swift`. V2 adds date-keyed Dashboard keys.

## Navigation (Router.swift Route enum)

**Existing tabs (V1):** Home, Quran, Blocking, Settings
**New tab (V2):** Dashboard (index 3, before Settings)

**New V2 routes:**
```swift
case dashboard
case ayahPool
case unblockDurationSelection(ruleId: UUID)
```

## SwiftData Models

**V1 existing:**
- `User` — id, isPremium, hasCompletedOnboarding, streak data
- `Session` — id, surahIds, ayahIds, duration, completedAt
- `ScreenTimeRule` — id, name, isEnabled, **+isHardMode**, **+isLockEditingEnabled** (V2)

**V2 new:**
- `PendingRuleChange` — id, ruleId, changeType, pendingData, requestedAt, appliesAt, isCancelled, isApplied
- `AyahPoolItem` — id, surahNumber, ayahNumberInSurah, arabicText, transliteration, wordCount, addedAt

## Recitation Scoring

- Normal Mode: 70% similarity threshold
- Hard Mode: 85% similarity threshold
- Ayah word count filter in Hard Mode: >= 5 words
- Whisper API transcription → Arabic similarity scoring via `normalizeArabic()` + `transliterateArabic()`

## Environments

| | Debug | Release |
|---|---|---|
| RevenueCat | `TUIST_REVENUECAT_API_KEY` | `TUIST_REVENUECAT_PROD_KEY` |
| OpenAI | `TUIST_OPENAI_API_KEY` | same |
| Bundle ID | `$(TUIST_BASE_BUNDLE_ID)` | same |
| Bypass Paywall | `BYPASS_PAYWALL=true` | `false` |

All env vars loaded from `.env` file via `make env`.
