# HIGH-LEVEL SYSTEM DESIGN
# Deen First - Quran Reading & Screen Time Management

**Version:** 4.0 (Audit Sync)
**Date:** March 19, 2026
**Related Document:** DEEN_FIRST_PRD.md v4.0

---

## 1. SYSTEM OVERVIEW

### 1.1 Technology Stack

```
┌─────────────────────────────────────────────────┐
│          iOS App (Swift/SwiftUI)                │
├─────────────────────────────────────────────────┤
│  Platform: iOS 17+                              │
│  Language: Swift 5.9+                           │
│  UI Framework: SwiftUI                          │
│  Architecture: Clean Architecture + MVVM        │
│  Database: SwiftData (local only)               │
│  Auth: Sign in with Apple (native)              │
│  Monetization: RevenueCat SDK                   │
│  Screen Time: FamilyControls framework          │
│  Audio: AVFoundation (background enabled)       │
│  Networking: Alamofire                          │
│  Storage: SwiftData + UserDefaults (App Groups) │
│           + Keychain                            │
└─────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│           External Services                      │
├─────────────────────────────────────────────────┤
│  • QuranAPI.pages.dev (text + audio)            │
│  • AlQuranAPI (secondary text/audio source)     │
│  • Apple Authentication Services                │
│  • RevenueCat (Subscription Management)         │
│  • OpenAI Whisper API (recitation transcription)│
└─────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│          Device-Level Integration                │
├─────────────────────────────────────────────────┤
│  • FamilyControls (Screen Time API)             │
│  • ManagedSettings (App Blocking)               │
│  • DeviceActivity (Usage monitoring)            │
│  • AVAudioSession (Background Audio)            │
│  • AVAudioRecorder (Recitation recording)       │
│  • Apple In-App Purchase                        │
│  • UserNotifications (Push notifications)       │
└─────────────────────────────────────────────────┘
```

### 1.2 Architecture Pattern

**Clean Architecture + MVVM (3 Layers)**

```
┌────────────────────────────────────────────────────────┐
│                PRESENTATION LAYER                       │
│  ┌──────────────┐        ┌──────────────────────┐     │
│  │    Views     │───────▶│     ViewModels       │     │
│  │ (SwiftUI)    │        │  (@ObservableObject) │     │
│  └──────────────┘        └──────────────────────┘     │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│                   DOMAIN LAYER                          │
│  ┌──────────────┐        ┌──────────────────────┐     │
│  │   Services   │───────▶│      Entities        │     │
│  │ (Business    │        │   (Data Models)      │     │
│  │  Logic)      │        │                      │     │
│  └──────────────┘        └──────────────────────┘     │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│                    DATA LAYER                           │
│  ┌──────────────┐        ┌──────────────────────┐     │
│  │ Repositories │───────▶│    DataSources       │     │
│  │ (Data Access)│        │ (SwiftData/Network)  │     │
│  └──────────────┘        └──────────────────────┘     │
└────────────────────────────────────────────────────────┘
```

---

## 2. APP STRUCTURE

### 2.1 App State Machine (RootView)

State checks on every launch — in priority order:

```
Not logged in
    → AuthView

Logged in, onboarding not complete
    → SurveyView (or resume at incomplete step)

Logged in, not premium
    → PaywallView

Premium, Screen Time not authorized
    → PermissionView

Premium, Screen Time authorized, setup not complete
    → AppToBlock (setup flow)

All complete
    → MainTabView
```

**Foreground lifecycle**:
- Re-block apps if temporary unblock timer expired
- Re-block emergency unblock if midnight passed
- Clean up orphaned sessions
- Reset daily streaks if applicable

**Subscription monitoring**:
- `SubscriptionMonitor` class listens to RevenueCat `customerInfoStream`
- On expiry: posts notification → all shields removed → paywall shown

### 2.2 4-Tab Navigation

```
MainTabView
    ├─ Tab 1: Home
    │   ├─ Streak badge
    │   ├─ Daily Surah recommendation
    │   ├─ Active Blocks overview with countdown timers
    │   └─ "Start Focus Session" quick action
    │
    ├─ Tab 2: Quran
    │   ├─ Surah list (searchable)
    │   ├─ QuranReadingView (full surah text)
    │   └─ Focus Session flow:
    │       SelectSurahView → AyahRangeSelectionView
    │       → FocusSectionView → ActiveSessionView
    │       → SessionFinishView
    │
    ├─ Tab 3: Blocking
    │   ├─ App Limits (usage-based rules)
    │   ├─ Time Limits (schedule-based rules)
    │   └─ Per-rule countdown timers + unblock actions
    │
    └─ Tab 4: Settings
        ├─ Profile + subscription info
        ├─ Preferences (reciter, translation)
        ├─ Emergency Unblock
        └─ Support + Account
```

---

## 3. KEY FEATURE FLOWS

### 3.1 Onboarding Flow (First-Time User)

```
Auth (Sign in with Apple)
    ↓
Survey Step 1–4 (motivation, distraction, goals, time comparison)
    ↓
CalculateSurvey (processing transition)
    ↓
Summary Step 1–3 (personalized insights)
    ↓
HowAppWork Step 1–3 (feature education)
    ↓
FinalSummary
    ↓
Paywall (subscribe or trial)
    ↓
PermissionSetup (FamilyControls authorization)
    ↓
AppToBlock Step 1–3 (select apps, set limits, set schedule)
    ↓
SetupSummary
    ↓
MainTabView (Home tab)
```

### 3.2 Subscription Status Check (Every Launch)

```
App launches → RootView appears
    ↓
Check RevenueCat customerInfo
    ↓
Is premium?
    ├─ YES → proceed through state checks → MainTabs
    └─ NO  → remove all shields → PaywallView
```

### 3.3 Focus Session Flow

```
User enters Focus Session (from Home or Quran tab)
    ↓
SelectSurahView (multi-select from 114 surahs)
    ↓
AyahRangeSelectionView (optional: pick start/end ayah)
    ↓
FocusSectionView (review surahs, confirm reciter, confirm blocked apps)
    ↓
"Start Session" tapped:
    1. Save selected surahs to UserDefaults (persist for next session)
    2. Apply Shield to selected apps (ManagedSettingsStore)
    3. Fetch audio URL for first surah
    4. Start audio playback
    5. Start session timer
    ↓
ActiveSessionView:
    - Current surah name + reciter
    - Elapsed timer
    - Progress: "2 / 3 surahs"
    - Play/Pause, Skip
    - Background audio continues when phone locked
    ↓
Auto-play next surah when current finishes
    ↓
Session ends (user taps End or all surahs finish):
    1. Check subscription status
    2a. If premium: remove session shield only
    2b. If expired: remove ALL shields → show paywall
    3. Save Session to SwiftData
    4. Update streak
    5. Navigate to SessionFinishView
```

### 3.4 Recite to Unblock Flow

```
User taps "Unblock" on a blocked app rule card
    ↓
ReciteToUnblockView opens
    ↓
App shows random short Ayah (< 20 words)
    - Arabic text
    - Transliteration
    - Play button (hear reciter)
    ↓
User taps Record
    - AVAudioRecorder captures microphone audio
    ↓
Recording sent to OpenAI Whisper API (gpt-4o-mini-transcribe)
    ↓
Transcription returned
    ↓
Similarity scoring:
    - Arabic normalization (hamza variants, ta marbuta → ha, alef variants)
    - Transliteration normalization (strip diacritics, lowercase)
    - Word-based set intersection
    - Base score adjustment for short ayahs (1-2 words: +30%, 3-4 words: +20%)
    - Pass threshold: ≥ 70%
    ↓
Score ≥ 70% → UnblockDurationSheet:
    - User selects duration (5, 15, 30 min, etc.)
    - Apps temporarily unblocked for selected duration
    - Expiry timestamp saved to SharedDefaults
    - Reblocked on timer expiry or next app foreground
    ↓
Score < 70% → ReciteAlertView:
    - Show score, option to retry or dismiss
```

### 3.5 Emergency Unblock Flow

```
User opens Settings tab → Emergency Unblock section
    ↓
Check quota: remaining uses this week (max 2, resets Monday)
    ↓
User taps toggle → confirm
    ↓
All ManagedSettings shields cleared
    ↓
Expiry timestamp set to midnight
    ↓
Display: countdown to midnight, remaining weekly quota
    ↓
At midnight OR next app foreground:
    - Check if expiry passed
    - Re-apply all configured shields
    - Decrement weekly quota
```

### 3.6 App Blocking Mechanics

**App Limit (usage-based)**:
- DeviceActivity monitors usage against threshold
- When threshold reached: extension fires `eventDidReachThreshold` → applies shield
- Resets at midnight (`intervalDidStart`)
- Activity name: `daily_{ruleId}`
- Event prefix: `limitReached_app_` or `limitReached_category_`

**Time Limit (schedule-based)**:
- DeviceActivity schedule set to custom time window
- Immediate shield if currently within window
- Event prefix: `timeLimit_app_` or `timeLimit_category_`
- Activity name: `timeLimit_{ruleId}`

**All Day**:
- DeviceActivity full-day schedule
- Immediate shield if today is active
- Event prefix: `allDay_app_` or `allDay_category_`
- Activity name: `allDay_{ruleId}`

**Session Blocking (temporary)**:
- Direct ManagedSettingsStore manipulation (no DeviceActivity)
- Shield applied on session start, removed on session end

**Subscription expiry**:
- `store.clearAllSettings()` removes all shields
- All DeviceActivity monitoring stopped

### 3.7 Streak System

```
User reads any surah OR starts a focus session
    ↓
Check last engagement date
    ↓
Same day as today → no change
    ↓
Yesterday → streak +1 (update longestStreak if exceeded)
    ↓
More than 1 day gap → streak reset to 1
    ↓
Save lastEngagementDate = today
```

No minimum time requirement. One engagement per day is sufficient.

### 3.8 Caching Strategy

| Data | Cache | Storage | TTL |
|------|-------|---------|-----|
| Surah list (metadata) | Yes | SwiftData | Indefinite |
| Surah content (text + translation) | Yes | SwiftData | 30 days |
| Audio files | No | Streaming only | — |
| Screen Time rules | Yes | App Groups UserDefaults | Until deleted |
| Application tokens | Yes | App Groups UserDefaults | Until deleted |

---

## 4. SERVICES ARCHITECTURE

### 4.1 Service Catalog

| Service | Responsibility |
|---------|---------------|
| `QuranService` | Fetch surahs, ayahs, audio URLs; cache management |
| `AuthService` | Sign in with Apple, user record management |
| `ScreenTimeRulesService` | CRUD for App Limit + Time Limit rules |
| `ScreenTimeRulesService+Unblock` | Temporary unblock with expiry |
| `ScreenTimeRulesService+EmergencyUnblock` | Emergency unblock with quota |
| `SessionService` | Focus session tracking, streak updates |
| `SubscriptionService` | RevenueCat integration, expiry handling |
| `AudioPlayerService` | AVFoundation background playback |
| `AyahAudioPlayerService` | Single-ayah playback (for Recite to Unblock) |
| `DeviceActivityManager` | FamilyControls setup, monitoring |
| `ManagedSettingsWrapper` | Shield application/removal |
| `NotificationPermissionService` | Request push notification permission |
| `NotificationSchedulingService` | Schedule streak reminders |
| `QuranPreferencesService` | User reciter + translation preferences |

### 4.2 Repository Catalog

| Repository | Responsibility |
|------------|---------------|
| `QuranRepository` | Quran API + local cache access |
| `ScreenTimeRulesRepository` | App Group UserDefaults for rules |
| `UserRepository` | SwiftData user record CRUD |

### 4.3 Dependency Injection

All services registered in `DIContainer.shared` (singleton, lazy initialization):

```
DIContainer
    ├─ LocalDataSource (SwiftData)
    ├─ QuranAPIDataSource / AlQuranAPIDataSource
    ├─ UserRepository → AuthService
    ├─ QuranRepository → QuranService
    ├─ ScreenTimeRulesRepository → ScreenTimeRulesService
    ├─ SessionService
    ├─ SubscriptionService
    ├─ AudioPlayerService
    ├─ AyahAudioPlayerService
    ├─ DeviceActivityManager
    ├─ NotificationPermissionService
    ├─ NotificationSchedulingService
    └─ QuranPreferencesService
```

ViewModels get dependencies via `DIContainer.shared.{service}` in their `init()`.

---

## 5. DATA MODELS

### 5.1 SwiftData Entities

**User**
- `id: String` (Apple User ID, unique)
- `authProvider: String` ("apple")
- `email: String`, `name: String`, `createdAt: Date`
- `hasCompletedOnboarding: Bool`
- `isPremium: Bool`, `subscriptionExpiryDate: Date?`
- `currentStreak: Int`, `longestStreak: Int`, `lastEngagementDate: Date?`
- Relationships: `sessions`, `blockedApps`, `appTimeLimits`

**Session**
- `id: String` (UUID), `userId: String`
- `sessionType: String` ("read" | "listen")
- `surahNumber: Int`, `durationSeconds: Int`
- `reciterId: Int?`, `isCompleted: Bool`, `createdAt: Date`

### 5.2 App Groups UserDefaults (Screen Time)

Shared across main app and extensions via `group.com.aydev.deenfirst`:

| Key | Type | Content |
|-----|------|---------|
| `timeLimitRules` | `[ScreenTimeRule]` | App Limit rules |
| `timeLimitRules` (timeLimit) | `[ScreenTimeRule]` | Time-window rules |
| `allDayRules` | `[ScreenTimeRule]` | All-day rules |
| `tokenMapping` | `[String: Data]` | ApplicationToken storage |
| `categoryTokens` | `[String: Data]` | ActivityCategoryToken storage |
| Emergency unblock expiry | `Date?` | Expiry timestamp |
| Temporary unblock data | `[String: Date]` | Per-rule expiry timestamps |

### 5.3 Domain Model Structs

**ScreenTimeRule** (Codable, stored in UserDefaults)
- `id: UUID`, `name: String`
- `selection: FamilyActivitySelection`
- `type: RuleType` (.timeLimit | .timeLimit | .allDay)
- `limitSeconds: Int?` (for App Limit)
- `startTime: DateComponents?`, `endTime: DateComponents?` (for Time Limit)
- `daysActive: Set<String>?`
- `unblockAllowedAfterLimit: Int`, `durationOptions: [Int]`
- `createdAt: Date`

**AppLimitConfig** — configuration for usage-based rules
**TimeLimitConfig** — configuration for time-window rules
**SurahWithRange** — surah + selected ayah start/end for focus sessions
**OnboardingSurvey** — stored survey answers

### 5.4 API Response Models

**Surah**: number, name (Arabic), englishName, englishNameTranslation, revelationType, numberOfAyahs, ayahs?

**Ayah**: number, text (Arabic), numberInSurah, translation?

**Reciter** (static): id, name — available: Mishary Alafasy (7), Abdul Basit (2), Saad Al-Ghamdi (5), Abu Bakr Al-Shatri (3)

**AyahAudio / ReciterAudio**: audioUrl response

---

## 6. NAVIGATION ROUTING

### 6.1 Router Routes (complete list)

```
auth
paywall(isFromSettings: Bool, currentPlan: String?)
permissionSetup
setupAppToBlock
setupSummary
mainTabs
quranReading(surahId: Int)
blocks
appLimit
editAppLimit(id: UUID)
timeLimit
editTimeLimit(id: UUID)
focusSection
selectSurah(surahs: [SurahWithRange])
ayahRange(surah: Surah)
activeSession(surahs: [SurahWithRange], ayahs: [Ayah])
sessionFinish(duration: TimeInterval, surahCount: Int)
survey(step: Int, answers: SurveyAnswers)
calculateSurvey(answers: SurveyAnswers)
summary(step: Int, answers: SurveyAnswers)
howAppWork(step: Int)
finalSummary
subscription
preferences
support
reciteToUnlock
emergencyUnblock
```

### 6.2 Navigation Flows

**First-Time User**:
```
Auth → Survey(1) → Survey(2) → Survey(3) → Survey(4)
→ CalculateSurvey → Summary(1) → Summary(2) → Summary(3)
→ HowAppWork(1) → HowAppWork(2) → HowAppWork(3)
→ FinalSummary → Paywall → PermissionSetup
→ AppToBlock(Step1) → AppToBlock(Step2) → AppToBlock(Step3)
→ SetupSummary → MainTabs
```

**Returning User (Active Subscription)**:
```
Auth → (all state checks pass) → MainTabs
```

**Returning User (Expired Subscription)**:
```
Auth → Check subscription → EXPIRED
→ Remove all shields → PaywallView
```

**Mid-Session Expiry**:
```
Active listening session
→ Session ends (user tap or all surahs finish)
→ Check subscription → EXPIRED
→ Remove all shields → PaywallView
```

---

## 7. API INTEGRATION

### 7.1 Quran APIs

**Primary**: QuranAPI.pages.dev (`https://quranapi.pages.dev/api`)
- `GET /surah` — all 114 surahs
- `GET /surah/{number}?lang=en` — surah detail with translation
- `GET /surah/{number}/audio/{reciterId}` — audio URL

**Secondary**: AlQuranAPI
- Complementary data source, separate DataSource + DTOs
- `AlQuranAPIDataSource.swift` + `AlQuranAPIDTOs.swift`

**Caching**:
- Surah list: cached indefinitely in SwiftData
- Surah content: cached 30 days with expiry timestamp
- Audio: not cached (stream via AVPlayer)

### 7.2 OpenAI Whisper API

**Purpose**: Recitation transcription for Recite to Unblock feature only.

**Model**: `gpt-4o-mini-transcribe`

**Flow**:
1. AVAudioRecorder captures user recitation (WAV/M4A)
2. Audio file POSTed to Whisper API endpoint
3. Transcription text returned
4. Local similarity algorithm runs (no data retained externally)

**Similarity algorithm**:
- Arabic normalization: hamza variants unified, ta marbuta → ha, alef variants unified
- Transliteration normalization: strip diacritics, lowercase
- Word-based set intersection: `|intersection| / |union|`
- Base score boost for short ayahs (1-2 words: +30%, 3-4 words: +20%, 5+: 0%)
- Pass threshold: ≥ 70%

### 7.3 RevenueCat

- Initialized in `DeenFirstApp.swift` on launch
- `SubscriptionMonitor` streams `customerInfoStream` for real-time updates
- Entitlement ID: `premium`
- Products: `com.aydev.deenfirst.monthly`, `com.aydev.deenfirst.yearly`

---

## 8. SCREEN TIME API ARCHITECTURE

### 8.1 Extension Architecture

```
Main App (Deen First)
    - Rule configuration
    - Shield management
    - Emergency/temporary unblock
    ↓
App Groups (group.com.aydev.deenfirst)
    - ScreenTimeRule data
    - Token mappings
    - Unblock expiry timestamps
    ↓
Extensions:
    ┌─────────────────────────────┐
    │  DeviceActivityMonitor      │
    │  - Usage threshold events   │
    │  - Interval start/end hooks │
    │  - Shield application       │
    └─────────────────────────────┘
    ┌─────────────────────────────┐
    │  ShieldConfiguration        │
    │  - Custom blocked screen UI │
    │  - Deen First branding      │
    └─────────────────────────────┘
```

### 8.2 Three Rule Types Implemented

| Rule Type | Trigger | Schedule | Immediate Shield |
|-----------|---------|----------|-----------------|
| App Limit | Usage threshold reached | Daily 00:00–23:59 | No |
| Time Limit | Entering time window | Custom start/end | Yes (if in window) |
| All Day | Day becomes active | Daily 00:00–23:59 | Yes (if today active) |

### 8.3 Event Naming Convention

| Type | App Event | Category Event | Activity Name |
|------|-----------|----------------|--------------|
| App Limit | `limitReached_app_{uuid}` | `limitReached_category_{uuid}` | `daily_{ruleId}` |
| Time Limit | `timeLimit_app_{uuid}` | `timeLimit_category_{uuid}` | `timeLimit_{ruleId}` |
| All Day | `allDay_app_{uuid}` | `allDay_category_{uuid}` | `allDay_{ruleId}` |

### 8.4 Emergency Unblock Implementation

- Clears `ManagedSettingsStore` entirely (all shields removed)
- Stops all DeviceActivity monitoring
- Saves expiry (midnight) to shared UserDefaults
- On next app foreground or midnight: re-applies all configured shields
- Weekly quota: 2 uses, tracked in shared UserDefaults, resets Monday

### 8.5 Temporary Unblock (Recite to Unblock result)

- Per-rule expiry timestamp saved to shared UserDefaults
- `ScreenTimeRulesService+Unblock` handles apply/clear
- On foreground check: any expired temporary unblocks are re-blocked
- Does not affect DeviceActivity monitoring (monitoring continues, just shield temporarily lifted)

### 8.6 App Group Configuration

**Identifier**: `group.com.aydev.deenfirst`

Shared between:
- Main app target (`deenfirst`)
- DeviceActivityMonitor extension (`com.aydev.deenfirst.ScreenTimeMonitor`)
- ShieldConfiguration extension (`com.aydev.deenfirst.Shield`)

### 8.7 Testing Notes

- Screen Time API does **not** work in Simulator — physical device required (iOS 17+)
- TestFlight is valid for Screen Time testing
- Emergency unblock quota resets weekly — test with manual date advancement

---

## 9. AUDIO PLAYBACK

### 9.1 AudioPlayerService (Focus Sessions)

- `AVAudioSession` category: `.playback`, mode: `.default` (background enabled)
- `AVPlayer` for streaming from URL
- `MPNowPlayingInfoCenter` for Control Center / Lock Screen metadata
- Auto-play next surah on `AVPlayerItemDidPlayToEndTime`
- `Info.plist`: `UIBackgroundModes: [audio]`

### 9.2 AyahAudioPlayerService (Recite to Unblock preview)

- Single ayah playback
- Used in ReciteToUnblockView for user to hear the ayah before recording
- Shorter, simpler player without session-level tracking

---

## 10. NOTIFICATIONS

### 10.1 NotificationPermissionService

- Requests UNUserNotificationCenter authorization on appropriate flow step
- Stores granted/denied state

### 10.2 NotificationSchedulingService

- Schedules streak reminder notifications
- Triggered from RootView lifecycle hooks
- Respects user notification preferences

---

## 11. PERFORMANCE CONSIDERATIONS

### 11.1 Data Loading

- Surah list loaded once on first launch, cached indefinitely
- Surah content loaded on-demand, cached 30 days
- ViewModels load data on `.onAppear` via `Task { }`

### 11.2 Audio Streaming

- AVPlayer handles buffering automatically
- Audio prefetching begins when surah selected
- Memory released on session end (`audioPlayer.stop()`)

### 11.3 Screen Time Rule Timers

- BlockingTabViewModel manages per-rule countdown timers
- Timer objects invalidated on view disappear
- HomeTabViewModel mirrors same logic for active blocks on home screen

### 11.4 Subscription Monitoring

- RevenueCat `customerInfoStream` (async stream) avoids polling
- `SubscriptionMonitor` (separate class from app delegate) handles stream lifecycle
- Local `isPremium` state updated without blocking main thread

---

## 12. DEVELOPMENT STANDARDS

### 12.1 Document Structure

```
📄 DEEN_FIRST_PRD.md          → Feature requirements (no code)
📄 DEEN_FIRST_SYSTEM_DESIGN.md → Architecture & flows (this file)
📄 PROJECT_RULES.md            → Code patterns & conventions
📄 PROJECT_SETUP.md            → Build system & Tuist config
📄 SCREEN_TIME_API_GUIDE.md    → Screen Time API reference implementation
📄 REVENUECAT_SETUP.md         → RevenueCat setup guide
```

### 12.2 Build System

**Tuist** for Xcode project generation.

```
make           # Clean → install → generate
make generate  # Regenerate Xcode project
make build     # Build to simulator
make clean     # Clean derived data
make install   # Fetch dependencies
```

**When to regenerate**: After adding any new Swift file.

### 12.3 Build Verification

```bash
xcodebuild -workspace deenfirst.xcworkspace \
  -scheme deenfirst \
  -destination 'generic/platform=iOS Simulator' \
  build 2>&1 | grep -E "(BUILD|error:)" | tail -10
```

Build once at end of work session. Fix all errors at once rather than per-file.

### 12.4 Code Style Checklist

Before committing:
- [ ] All ViewModels have `@MainActor`
- [ ] Services follow Protocol + Impl pattern
- [ ] Dependencies injected via DIContainer
- [ ] File names: PascalCase views, snake_case entities
- [ ] No force unwraps (`!`)
- [ ] Error handling with `do/catch`
- [ ] Loading states managed (isLoading before/after)
- [ ] Navigation uses Router
- [ ] No business logic in Views
- [ ] Async work wrapped in `Task { }`

---

## 13. BUNDLE IDs & CONFIGURATION

| Target | Bundle ID |
|--------|-----------|
| Main App | `com.aydev.deenfirst` |
| DeviceActivityMonitor | `com.aydev.deenfirst.ScreenTimeMonitor` |
| ShieldConfiguration | `com.aydev.deenfirst.Shield` |
| App Group | `group.com.aydev.deenfirst` |

| Product | ID | Price | Trial |
|---------|-----|-------|-------|
| Monthly | `com.aydev.deenfirst.monthly` | $4.99/mo | 3 days |
| Yearly | `com.aydev.deenfirst.yearly` | $29.99/yr | 7 days |
| Entitlement | `premium` | — | — |

---

**END OF SYSTEM DESIGN v4.0**
