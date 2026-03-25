# PRODUCT REQUIREMENTS DOCUMENT (PRD)
# Deen First - Quran Reading & Screen Time Management

**Version:** 4.0 (Audit Sync)
**Date:** March 19, 2026
**App Name:** Deen First

---

## 1. EXECUTIVE SUMMARY

### 1.1 Product Overview
Deen First is a premium iOS productivity app that combines Quran reading with screen time management using Apple's Screen Time API. The app blocks distracting applications, builds daily Quran engagement habits through streak tracking, and provides multiple unblock mechanisms including recitation-based unlocking. Targets Gen Z Muslims struggling with phone addiction and doom scrolling.

### 1.2 Core Value Proposition
- **Problem**: Gen Z Muslims struggle with phone addiction and neglect Quran reading
- **Solution**: Block distracting apps with daily limits; build consistent Quran habits through streak-based gamification and focus sessions
- **Unique Angle**: Premium Quran app with native Screen Time API integration, recitation-based unblocking, and emergency access controls
- **Business Model**: Subscription-only with free trials (no free tier)

### 1.3 Target Audience
- **Primary**: Gen Z Muslims (ages 16-28)
- **Secondary**: Muslim parents managing children's screen time
- **Characteristics**: Tech-savvy, aware of phone addiction, want to reconnect with Quran, willing to pay for premium experience

### 1.4 Monetization
- **Monthly**: $4.99/month with 3-day free trial
- **Yearly**: $29.99/year with 7-day free trial
- **No free tier**: Must subscribe (after trial) to access app features
- **Payment**: Apple In-App Purchase
- **Subscription Management**: RevenueCat SDK

---

## 2. PRODUCT SCOPE

### 2.1 In Scope (Implemented V1)

**Authentication & Monetization**
- Sign in with Apple (only)
- RevenueCat subscription management
- Hard paywall (no free tier)
- Monthly and yearly subscription options
- Restore purchases functionality
- Subscription expiration handling (remove Screen Time shields when expired)

**Onboarding**
- 4-screen survey (motivation, distraction timing, goals, time comparison)
- Education/summary screens (3 summary screens + 3 "How App Works" screens)
- Social media time calculation vs Quran time comparison
- Paywall presentation (after survey)
- Screen Time API permission flow
- App selection and time limit setup (multi-step: Step 1, 2, 3)
- Setup summary screen

**Core Navigation**
- **4-tab bottom navigation**: Home, Quran, Blocking, Settings

**Home Tab**
- Personalized greeting (As-salamu alaykum, [Name])
- Streak badge (current + longest streak)
- Daily Surah recommendation (deterministic per day)
- Active Blocks overview with countdown timers
- Quick "Start Focus Session" button

**Quran Tab**
- Browse all 114 surahs with search (Arabic/English/number)
- Full surah reading with Arabic text and English translation
- Bismillah display (except Surah 9)
- Focus session launcher (select surahs + ayah ranges)

**Blocking Tab**
- App Limits: block apps until daily usage quota is reached
- Time Limits: block apps during specified time windows
- Day selection per rule (weekdays, weekends, specific days)
- Category and individual app selection via FamilyControls
- Edit / delete rules
- Per-rule countdown timers
- Real-time timer updates

**Settings Tab**
- Profile section (name, email, premium badge)
- Subscription management (plan, status, renewal date)
- User preferences:
  - Default reciter selection (from available reciters)
  - Translation language selection
- Support section
- Emergency Unblock feature (within Settings)
- Sign out / Delete account

**Focus Session (Quran listening + blocking)**
- Select surahs and ayah ranges for session
- Block selected apps during session
- Active session screen: current surah, reciter, timer, playback controls
- Auto-play next surah in queue
- Background audio support (continues when app backgrounded)
- Control Center and Lock Screen audio controls
- Session finish screen with duration and surah count stats
- Session saved to history and streak updated

**Recite to Unblock**
- Triggered from blocked app rule cards
- Displays random short ayah (under 20 words) with Arabic text and transliteration
- Audio playback of the ayah (with selected reciter)
- User records their recitation (microphone)
- Transcription via OpenAI Whisper API
- Similarity scoring: Arabic normalization + transliteration matching, word-based intersection
- Pass threshold: 70% similarity
- Success: temporarily unblock apps for selected duration (e.g., 5 min)
- Failure: allow retry or dismiss

**Emergency Unblock**
- Accessible from Settings tab
- Instantly removes all blocking until midnight
- Weekly quota limit (2 uses per week)
- Displays remaining quota and time until reset
- Countdown timer when active

**Streak Tracking**
- Consecutive days of Quran engagement
- Engagement = reading any surah or starting a focus session (no minimum time)
- Streak resets if user misses a full day
- Displayed on Home tab with current + longest streak
- Session history saved locally

**Screen Time Integration**
- FamilyControls authorization
- App blocking via Shield
- Daily time limit enforcement
- Time range scheduling
- Automatic shield removal on subscription expiration
- Temporary unblock with expiry timestamp
- Reblock on app foreground if timer expired
- Emergency unblock until midnight

**Audio Playback**
- Background audio support
- Control Center integration
- Lock screen controls
- Auto-play next surah in queue
- Multiple reciters available

**Notifications**
- Push notification permission request
- Notification scheduling service (streak reminders etc.)

### 2.2 Out of Scope (Not Implemented)

- Google Sign In
- Cloud sync / backend (local-only SwiftData)
- Full offline mode (text caching only, no audio downloads)
- Social features / sharing
- Prayer time blocking integration (entity exists but feature not active)
- Tafsir (commentary)
- Bookmarking specific ayahs
- Advanced analytics / heatmaps
- Verse-by-verse audio during reading

---

## 3. TECHNICAL ARCHITECTURE

### 3.1 Tech Stack
- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: Clean Architecture + MVVM
- **Database**: SwiftData (local persistence only)
- **Authentication**: Sign in with Apple
- **Monetization**: RevenueCat SDK
- **Networking**: Alamofire (HTTP client)
- **Screen Time**: FamilyControls framework (iOS 16+)
- **Quran APIs**: AlQuranAPI + QuranAPI.pages.dev
- **Audio**: AVFoundation (background playback)
- **Transcription**: OpenAI Whisper API (for Recite to Unblock)
- **Dependency Injection**: DIContainer pattern
- **Storage**: SwiftData + UserDefaults (app groups) + Keychain

### 3.2 Architecture Layers

```
Presentation Layer (Views + ViewModels)
    ↓ calls
Domain Layer (Services + Entities)
    ↓ calls
Data Layer (Repositories + DataSources)
    ↓ calls
External (Quran APIs, RevenueCat, OpenAI Whisper)
```

### 3.3 Folder Structure

```
deenfirst/Sources/
├── Core/
│   ├── DataDependency/DIContainer.swift
│   ├── Networking/
│   │   ├── HTTPClient.swift
│   │   └── NetworkLoggingInterceptor.swift
│   └── SceneNavigation/Router.swift
├── Domain/
│   ├── Entities/
│   │   ├── user.swift
│   │   ├── session.swift
│   │   ├── surah.swift
│   │   ├── ayah.swift
│   │   ├── reciter.swift
│   │   ├── OnboardingSurvey.swift
│   │   ├── ScreenTimeRule.swift
│   │   ├── AppLimitConfig.swift
│   │   ├── TimeLimitConfig.swift
│   │   ├── SurahWithRange.swift
│   │   ├── PrayerTime.swift
│   │   ├── AyahAudio.swift
│   │   ├── ReciterAudio.swift
│   │   └── TranslationLanguage.swift
│   └── Services/
│       ├── QuranService.swift
│       ├── AuthService.swift
│       ├── ScreenTimeRulesService.swift
│       ├── ScreenTimeRulesService+Unblock.swift
│       ├── ScreenTimeRulesService+EmergencyUnblock.swift
│       ├── SessionService.swift
│       ├── SubscriptionService.swift
│       ├── AudioPlayerService.swift
│       ├── AyahAudioPlayerService.swift
│       ├── DeviceActivityManager.swift
│       ├── ManagedSettingsWrapper.swift
│       ├── NotificationPermissionService.swift
│       ├── NotificationSchedulingService.swift
│       └── QuranPreferencesService.swift
├── Data/
│   ├── DataSource/
│   │   ├── API/
│   │   │   ├── AlQuranAPIDataSource.swift
│   │   │   ├── AlQuranAPIDTOs.swift
│   │   │   ├── QuranAPIDataSource.swift
│   │   │   └── QuranAPIDTOs.swift
│   │   └── LocalDataSource.swift
│   └── Repositories/
│       ├── QuranRepository.swift
│       ├── ScreenTimeRulesRepository.swift
│       └── UserRepository.swift
├── Presentation/
│   ├── Auth/
│   │   ├── AuthView.swift
│   │   └── AuthViewModel.swift
│   ├── Paywall/
│   │   ├── PaywallView.swift
│   │   └── PaywallViewModel.swift
│   ├── Setup/
│   │   ├── PermissionView.swift
│   │   ├── PermissionSetupViewModel.swift
│   │   ├── AppToBlock.swift
│   │   ├── AppToBlockStep1View.swift
│   │   ├── AppToBlockStep2View.swift
│   │   ├── AppToBlockStep3View.swift
│   │   ├── StarterPageView.swift
│   │   ├── SetupViewModel.swift
│   │   └── SetupSummary.swift
│   ├── Survey/
│   │   ├── SurveyView.swift
│   │   ├── SurveyViewModel.swift
│   │   ├── SurveyStep1View.swift
│   │   ├── SurveyStep2View.swift
│   │   ├── SurveyStep3View.swift
│   │   └── SurveyStep4View.swift
│   ├── Summary/
│   │   ├── Summary1View.swift
│   │   ├── Summary2View.swift
│   │   ├── Summary3View.swift
│   │   ├── SummaryViewModel.swift
│   │   ├── CalculateSurveyView.swift
│   │   ├── FinalSummaryView.swift
│   │   ├── HowAppWork1View.swift
│   │   ├── HowAppWork2View.swift
│   │   └── HowAppWork3View.swift
│   ├── MainTabs/
│   │   ├── MainTabView.swift
│   │   ├── HomeTab/
│   │   │   ├── HomeTabView.swift
│   │   │   └── HomeTabViewModel.swift
│   │   ├── QuranTab/
│   │   │   ├── QuranTabView.swift
│   │   │   ├── QuranTabViewModel.swift
│   │   │   ├── SelectSurahView.swift
│   │   │   ├── SelectSurahViewModel.swift
│   │   │   ├── AyahRangeSelectionView.swift
│   │   │   ├── AyahRangeSelectionViewModel.swift
│   │   │   ├── FocusSectionView.swift
│   │   │   ├── FocusSectionViewModel.swift
│   │   │   ├── ActiveSessionView.swift
│   │   │   ├── ActiveSessionViewModel.swift
│   │   │   └── SessionFinishView.swift
│   │   ├── BlockingTab/
│   │   │   ├── BlockingTabView.swift
│   │   │   ├── BlockingTabViewModel.swift
│   │   │   ├── AppLimitView.swift
│   │   │   ├── AppLimitViewModel.swift
│   │   │   ├── TimeLimitView.swift
│   │   │   └── TimeLimitViewModel.swift
│   │   └── SettingsTab/
│   │       ├── SettingsTabView.swift
│   │       ├── SettingsTabViewModel.swift
│   │       ├── PreferencesView.swift
│   │       ├── PreferencesViewModel.swift
│   │       ├── SubscriptionView.swift
│   │       ├── SubscriptionViewModel.swift
│   │       ├── SubscriptionPlansView.swift
│   │       ├── SupportView.swift
│   │       ├── SupportViewModel.swift
│   │       ├── ReciterSelectionSheet.swift
│   │       ├── TranslationSelectionSheet.swift
│   │       └── EmergencyUnblock/
│   │           ├── EmergencyUnblockView.swift
│   │           └── EmergencyUnblockViewModel.swift
│   ├── ReciteToUnblock/
│   │   ├── ReciteToUnblockView.swift
│   │   ├── ReciteToUnblockViewModel.swift
│   │   ├── ReciteAlertView.swift
│   │   └── UnblockDurationSheet.swift
│   ├── QuranReading/
│   │   ├── QuranReadingView.swift
│   │   └── QuranReadingViewModel.swift
│   ├── FocusSession/
│   │   ├── StartView.swift
│   │   ├── SelectSurahFocusView.swift
│   │   ├── SetupView.swift
│   │   └── EndView.swift
│   └── Components/
│       ├── AlertHandler.swift
│       ├── AppLogo.swift
│       ├── AyahCard.swift
│       ├── AyahRangeSheetView.swift
│       ├── BackgroundView.swift
│       ├── BismillahView.swift
│       ├── GradientBackground.swift
│       ├── LoadingOverlay.swift
│       ├── PrimaryButton.swift
│       ├── SearchBar.swift
│       ├── SelectableCard.swift
│       ├── StreakBadge.swift
│       ├── SurahCard.swift
│       ├── SurahHeader.swift
│       ├── TappableText.swift
│       ├── BlockingTabComps/
│       │   ├── BlockRow.swift
│       │   ├── BlockRuleCard.swift
│       │   ├── CreateBlockSheet.swift
│       │   └── EmptyBlocksView.swift
│       ├── HomeTabComps/
│       │   ├── DailySurahCard.swift
│       │   └── EmptyActiveBlocksView.swift
│       ├── FocusSessionComps/
│       │   └── SurahToListen.swift
│       └── SettingsTabComps/
│           └── SettingsRow.swift
├── Shared/
│   ├── AppGroupConstants.swift
│   ├── DayHelper.swift
│   └── ScreenTimeEvents.swift
├── Utils/
│   ├── AppConstants.swift
│   ├── Color+Extension.swift
│   ├── Date+Extension.swift
│   ├── DeviceActivityScheduleHelper.swift
│   ├── KeychainHelper.swift
│   ├── TimeLimitHelper.swift
│   └── UserPersistenceHelper.swift
├── RootView.swift
└── DeenFirstApp.swift
```

---

## 4. API INTEGRATION

### 4.1 Quran APIs (Dual Source)

**Primary**: QuranAPI.pages.dev
- Base URL: `https://quranapi.pages.dev/api`
- Endpoints: surah list, surah detail with translation, audio URL per reciter
- No auth required, no rate limits

**Secondary**: AlQuranAPI
- Used as fallback or complementary data source
- Same core endpoints, different response shape (handled by separate DataSource + DTOs)

### 4.2 Audio Reciters

Available reciters (from QuranAPI.pages.dev):
- Mishary Rashid Alafasy (ID 7, default)
- Abdul Basit Abdul Samad (ID 2)
- Saad Al-Ghamdi (ID 5)
- Abu Bakr Al-Shatri (ID 3)

Reciter preference saved per user in SwiftData via `QuranPreferencesService`.

### 4.3 OpenAI Whisper API

Used exclusively for **Recite to Unblock** feature.
- Model: `gpt-4o-mini-transcribe`
- Input: audio recording of user reciting an ayah
- Output: transcribed text
- Processed locally for similarity scoring (no data stored externally)

### 4.4 Caching Strategy

**Cached indefinitely (SwiftData)**:
- Surah list metadata (~50KB, static)
- Fetched once on first app launch

**Cached for 30 days (SwiftData)**:
- Surah content (text + translation)
- Fetched on-demand when user opens surah

**Not cached**:
- Audio files (streaming only — too large, 5–30MB per surah)
- Full offline audio download deferred to V2

### 4.5 Error Handling

- Timeout: 30 seconds (Alamofire built-in)
- Retry logic: 3 attempts with exponential backoff
- Fallback to cached text if network unavailable
- User-friendly error messages for all failure states

---

## 5. SUBSCRIPTION MANAGEMENT

### 5.1 Products
- **Monthly**: `com.aydev.deenfirst.monthly` — $4.99/month, 3-day free trial
- **Yearly**: `com.aydev.deenfirst.yearly` — $29.99/year, 7-day free trial
- **Entitlement ID**: `premium`

### 5.2 Subscription Lifecycle

**Trial → Paid**: User subscribes → trial period → first charge → auto-renews.

**Expiration**: On next app open, RevenueCat is queried. If expired:
1. Local user record updated (`isPremium = false`)
2. All Screen Time shields removed
3. Paywall shown with "Your subscription has expired" message

**Restore Purchases**: User taps Restore → RevenueCat checks Apple ID → if active subscription found, restore access; else show "No active subscription found."

**Mid-Session Expiry**: If subscription expires while a listening session is active, session completes normally. Expiry is handled on session end — all shields removed, paywall shown.

### 5.3 Subscription UI
- `PaywallView` — initial subscription gate
- `SubscriptionView` — current plan, status, renewal date within Settings
- `SubscriptionPlansView` — plan comparison UI

---

## 6. FEATURE SPECIFICATIONS

### 6.1 Authentication

**Sign in with Apple (only)**
- Displays "Sign in with Apple" button (iOS guidelines compliant)
- Successful auth creates user record in local SwiftData
- Stores user ID, email, name from Apple
- Links user ID to RevenueCat

**Navigation after sign-in**:
- New user → Onboarding Survey
- Returning user (subscribed, setup complete) → MainTabView
- Returning user (no subscription) → Paywall
- Returning user (subscription active, setup incomplete) → resumes at last incomplete step

---

### 6.2 Onboarding Flow

Full onboarding sequence for first-time users:

**Step 1 — Survey (4 screens)**

Screen 1: What brings you here?
- Multi-select options (consistency, distraction, routine, focus, reconnect with faith, other)

Screen 2: When does your phone distract you most?
- Multi-select options (late at night, overwhelmed, throughout day, stressed, "a minute turns into hours")

Screen 3: What do you want more of?
- Multi-select options (Quran consistency, presence/focus, better phone habits)

Screen 4: Time Calculation & Comparison
- Shows estimated social media time (~2.5 hrs/day Gen Z average)
- Compares to equivalent Quran reading time
- "Let's create space for what matters"

**Step 2 — Calculate Survey**
- Processing screen that transitions between survey and summary

**Step 3 — Summary/Education Screens**
- Summary1View, Summary2View, Summary3View: personalized insights from survey
- HowAppWork1View, HowAppWork2View, HowAppWork3View: explains app blocking, Quran sessions, streaks
- FinalSummaryView: closing motivation before paywall

**Step 4 — Paywall**
- Yearly plan shown first (Recommended badge)
- Monthly plan as alternative
- Free trial CTAs
- Restore purchases link

**Step 5 — Screen Time Permission**
- Explains FamilyControls requirement
- "Grant Permission" button triggers iOS system dialog
- If denied: alert with "Open Settings" deep link

**Step 6 — App Selection (3-Step Setup)**
- Step 1: Select apps to block (FamilyActivityPicker, multi-select)
- Step 2: Set daily limits per app (15 min, 30 min, 45 min, 1h, 2h, 3h, 4h)
- Step 3: Set schedule per rule (all day or custom time range with day selection)
- Setup Summary: confirmation before entering app

**Post-onboarding**: Navigate to MainTabView (Home tab selected)

---

### 6.3 Main Navigation (4-Tab Bottom Bar)

Tabs: **Home**, **Quran**, **Blocking**, **Settings**

---

### 6.4 Tab 1: Home

**Greeting**: "As-salamu alaykum, [Name]"

**Streak Badge** (if streak > 0):
- Current streak count + fire icon
- Longest streak
- "Keep it going!" message

**Daily Surah Card**:
- One surah recommended per day (deterministic seed based on date)
- Surah name (Arabic + English), number of ayahs
- Tap → opens QuranReadingView

**Active Blocks Section**:
- Lists currently active App Limit and Time Limit rules
- Each card shows: app/category name, time remaining, unblock options
- Real-time countdown timers
- "Unblock" button triggers Recite to Unblock or navigates to Emergency Unblock

**Quick Actions**:
- "Start Focus Session" button → navigates to Focus Session setup

---

### 6.5 Tab 2: Quran

**Surah List** (searchable):
- Search by surah name (Arabic or English) or number
- Each card: surah number, Arabic name, English transliteration, revelation type, ayah count
- Tap → navigate to QuranReadingView

**Focus Session Launcher**:
- Entry point to select surahs for a focus session
- Leads to: SelectSurahView → AyahRangeSelectionView → FocusSectionView → ActiveSessionView

#### 6.5.1 Quran Reading View

- Header: surah name, back button
- Bismillah (if not Surah 9)
- Scrollable verses: verse number, Arabic text (large), English translation (smaller below)
- Session tracking: starts on view appear, saves session on dismiss
- Streak updated after reading engagement

#### 6.5.2 Focus Session Flow

1. **Select Surahs**: multi-select from list, checkboxes, "X surahs selected" display
2. **Select Ayah Range** (optional): pick start and end ayah within each surah
3. **Focus Section Setup**: review surahs, confirm blocked apps, confirm reciter
4. **Active Session**:
   - Current surah name (large) + reciter name
   - Session timer (elapsed time)
   - Progress indicator ("2 / 3 surahs")
   - Playback controls: play/pause, skip to next surah
   - "End Session" button
   - Background audio continues when app backgrounded
   - Auto-plays next surah when current finishes
5. **Session Finish**:
   - Duration summary
   - Surah count completed
   - Streak updated
   - "Well done" message

**Blocking during session**: selected apps blocked for duration of session; shields removed when session ends.

---

### 6.6 Tab 3: Blocking

**Title**: "App Limits"

**App Limit Rules** (usage-based blocking):
- Block apps until a daily usage quota is reached
- Per rule: app/category name, daily limit (minutes), schedule (all day or time window), day selection
- Edit / Delete per rule
- Real-time countdown timer per rule

**Time Limit Rules** (schedule-based blocking):
- Block apps during specified time windows
- Per rule: app/category, start time, end time, day selection (weekdays / weekends / specific days)
- Edit / Delete per rule

**Add Rule** button → opens sheet to create new App Limit or Time Limit

**Rule Card Actions**:
- Edit → opens respective limit editor view
- Unblock → triggers Recite to Unblock (or emergency unblock if quota remains)

---

### 6.7 Tab 4: Settings

**Profile Section**:
- Avatar circle (first letter of name)
- Name, email
- Premium badge: "Premium Member ✓"

**Subscription Section**:
- Current plan (Monthly / Yearly)
- Status: Active (green) / Expired (red)
- Renewal date
- "Manage Subscription" → opens SubscriptionPlansView or App Store

**Preferences Section**:
- Default Reciter — tap to open ReciterSelectionSheet
- Translation Language — tap to open TranslationSelectionSheet
- Both saved per user in SwiftData

**Emergency Unblock Section**:
- Toggle to instantly remove all blocks until midnight
- Remaining quota display (2 uses per week)
- Countdown timer when active

**Support Section**:
- Help & FAQ
- Contact Support (mailto)
- Rate the App (App Store deep link)

**Account Section**:
- Sign Out → confirmation dialog
- Delete Account → warning dialog

---

### 6.8 Recite to Unblock

**Trigger**: tapping "Unblock" on a blocked rule card (from Home or Blocking tab).

**Flow**:
1. App shows a random short Ayah (under 20 words) with Arabic text and transliteration
2. User can tap to hear the ayah played by the selected reciter
3. User taps record → microphone captures recitation
4. Recording sent to OpenAI Whisper API for transcription
5. Transcription compared to expected text:
   - Arabic normalization applied (hamza variants, ta marbuta → ha, alef variants)
   - Transliteration normalization applied (diacritics stripped, lowercase)
   - Word-based set intersection score calculated
   - Base score adjustment for very short ayahs
6. If score ≥ 70% → success → user selects unblock duration (e.g., 5, 15, 30 minutes)
7. If score < 70% → failure → option to retry or close

**Unblock effect**: targeted app(s) temporarily unblocked until duration expires. Reblocked on timer expiry or app foreground (whichever comes first).

---

### 6.9 Emergency Unblock

**Location**: Settings tab.

**Behavior**:
- Instantly removes ALL active blocking (app limits + time limits)
- Blocks reset at midnight automatically
- Weekly quota: 2 uses per week (resets Monday)
- Shows remaining uses and time until weekly reset
- When active: displays countdown to midnight

**Use case**: genuine emergency access need without needing to recite.

---

### 6.10 Streak Tracking

**What counts as engagement**:
- Opening and reading any surah (immediately on view)
- Starting a focus listening session
- No minimum time requirement

**What breaks the streak**:
- Missing a complete day with no reading or listening

**Streak logic**:
- First engagement: streak = 1
- Engagement on same day as last: no change
- Engagement next consecutive day: streak + 1 (update longest if exceeded)
- Gap of 1+ days: reset to 1

**Display**: Home tab (streak badge with current + longest).

---

### 6.11 RootView — App State & Navigation Logic

**State checks on launch** (in order):
1. Not logged in → AuthView
2. Logged in, onboarding not complete → SurveyView (or resume at incomplete step)
3. Logged in, not premium → PaywallView
4. Premium, Screen Time not authorized → PermissionView
5. Premium, Screen Time authorized, setup not complete → AppToBlock
6. All complete → MainTabView

**Foreground lifecycle**:
- Re-block apps if temporary unblock timer expired
- Re-block emergency unblock if midnight passed
- Orphaned sessions cleaned up

**Subscription monitoring**:
- `SubscriptionMonitor` class listens to RevenueCat customer info stream
- Posts notification on subscription expiry → triggers shield removal → paywall shown

---

## 7. DATA MODELS

### 7.1 SwiftData Entities

**User**
- id (Apple User ID, unique)
- authProvider ("apple")
- email, name, createdAt
- hasCompletedOnboarding
- isPremium, subscriptionExpiryDate
- currentStreak, longestStreak, lastEngagementDate
- Relationships: sessions, blockedApps (via ScreenTimeRule), appTimeLimits

**Session**
- id (UUID)
- userId
- sessionType ("read" | "listen")
- surahNumber
- durationSeconds
- reciterId (optional)
- isCompleted
- createdAt

**ScreenTimeRule** (replaces BlockedApp + AppTimeLimit from v3)
- id (UUID)
- userId
- ruleType ("appLimit" | "timeLimit")
- appBundleIds / category tokens
- limitMinutes (for appLimit)
- startTime / endTime (for timeLimit)
- scheduleType ("allDay" | "timeRange")
- selectedDays (weekdays / weekends / specific)
- isEnabled
- isTemporarilyUnblocked, temporaryUnblockExpiry

**AppLimitConfig** — configuration struct for app-based limits
**TimeLimitConfig** — configuration struct for time-window limits
**SurahWithRange** — surah + selected ayah start/end for focus sessions
**OnboardingSurvey** — stores user survey answers
**TranslationLanguage** — available translation options
**Reciter** — available reciters with IDs and names
**PrayerTime** — entity exists, feature deferred to V2

### 7.2 API Response Models

**Surah**: number, name (Arabic), englishName, englishNameTranslation, revelationType, numberOfAyahs, ayahs (optional)

**Ayah**: number, text (Arabic), numberInSurah, translation (optional)

**Reciter**: id, name (static list of available reciters)

**AyahAudio** / **ReciterAudio**: audio URL response from API

---

## 8. NAVIGATION ROUTING

### 8.1 Router Routes

All navigable destinations:
- `auth`
- `paywall(isFromSettings: Bool, currentPlan: String?)`
- `permissionSetup`
- `setupAppToBlock`
- `setupSummary`
- `mainTabs`
- `quranReading(surahId: Int)`
- `blocks`
- `appLimit` / `editAppLimit(id: UUID)`
- `timeLimit` / `editTimeLimit(id: UUID)`
- `focusSection`
- `selectSurah(surahs: [SurahWithRange])`
- `ayahRange(surah: Surah)`
- `activeSession(surahs: [SurahWithRange], ayahs: [Ayah])`
- `sessionFinish(duration: TimeInterval, surahCount: Int)`
- `survey(step: Int, answers: SurveyAnswers)`
- `calculateSurvey(answers: SurveyAnswers)`
- `summary(step: Int, answers: SurveyAnswers)`
- `howAppWork(step: Int)`
- `finalSummary`
- `subscription`
- `preferences`
- `support`
- `reciteToUnlock`
- `emergencyUnblock`

### 8.2 Navigation Flows

**First-Time User**:
Auth → Survey (4 steps) → CalculateSurvey → Summary (3 screens) → HowAppWork (3 screens) → FinalSummary → Paywall → PermissionSetup → AppToBlock (3 steps) → SetupSummary → MainTabs (Home tab)

**Returning User (Subscribed)**:
Auth → (state check passes all gates) → MainTabs

**Returning User (No Subscription)**:
Auth → Paywall

**Subscription Expired**:
Any screen → subscription check fails → remove shields → Paywall

---

## 9. DEPENDENCIES

### 9.1 Swift Package Manager
- RevenueCat SDK (`purchases-ios`, v5.57.0+)
- Alamofire (`Alamofire`, v5.10.0+)

### 9.2 Native Frameworks
- SwiftUI (iOS 17+)
- SwiftData (iOS 17+)
- FamilyControls (iOS 16+)
- ManagedSettings (iOS 16+)
- DeviceActivity (iOS 16+)
- AuthenticationServices (Sign in with Apple)
- AVFoundation (Audio playback)
- MediaPlayer (Now Playing info)
- Speech / AVAudioRecorder (for Recite to Unblock)
- UserNotifications (push notifications)

### 9.3 Info.plist Keys Required
- `NSFamilyControlsUsageDescription`
- `UIBackgroundModes: audio`
- `NSSpeechRecognitionUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSUserTrackingUsageDescription` (optional analytics)

### 9.4 External Services
- **RevenueCat**: subscription management
  - Entitlement: `premium`
  - Products: `com.aydev.deenfirst.monthly`, `com.aydev.deenfirst.yearly`
- **OpenAI Whisper API**: recitation transcription (Recite to Unblock only)
- **QuranAPI.pages.dev**: Quran text, translation, audio URLs
- **AlQuranAPI**: secondary Quran data source

---

## 10. RISKS & MITIGATION

### Technical Risks

**Screen Time API Complexity**
- Risk: Shield configuration fails or produces unexpected behavior
- Mitigation: Extensive device testing; emergency unblock as safety valve

**Background Audio**
- Risk: Audio stops when app goes to background
- Mitigation: Standard AVFoundation `.playback` category with background mode enabled

**Subscription Edge Cases**
- Risk: Expiry mid-session, restore on different device, trial abuse
- Mitigation: RevenueCat handles state; check subscription on every foreground event

**Recite to Unblock Accuracy**
- Risk: Transcription failures or low-quality audio
- Mitigation: 70% threshold allows for minor mispronunciation; retry allowed on failure

**App Store Rejection**
- Risk: Rejected for Screen Time usage, subscription implementation, or microphone use
- Mitigation: Proper usage descriptions, Privacy Policy ready, follow all App Store guidelines

---

## 11. APP STORE SUBMISSION

### 11.1 App Information
- **Name**: Deen First
- **Subtitle**: Block Apps, Build Quran Habits
- **Category**: Productivity
- **Age Rating**: 4+
- **Keywords**: quran, muslim, islam, screen time, focus, productivity, ramadan, block apps, habit, streak

### 11.2 Description
Deen First helps you overcome phone addiction by combining Quran reading with screen time management.

**Block Distracting Apps** — Set daily time limits for social media and addictive apps. When you hit your limit, apps are blocked until midnight.

**Read the Quran** — Browse all 114 surahs with Arabic text and English translations. Build a daily reading habit.

**Listening Sessions** — Listen to beautiful Quran recitations with apps blocked during your focus sessions. Choose your surah range, pick a reciter, and stay focused. Background audio keeps playing when your phone is locked.

**Recite to Unblock** — Need temporary access? Recite an ayah to earn a short unblock window. The app uses AI to verify your recitation.

**Emergency Unblock** — For genuine emergencies, instantly remove all blocks until midnight (2 uses/week).

**Build Your Streak** — Track consecutive days of Quran engagement. Don't break the chain.

**Smart Scheduling** — Set custom time ranges and day selections for blocking. Stay focused when it matters.

### 11.3 Screenshots (6.7" iPhone 15 Pro Max)
1. Home tab with streak and daily surah
2. Surah reading view (Arabic + English)
3. Active focus session (audio controls + timer)
4. Blocking tab (rule cards with timers)
5. Recite to Unblock screen
6. Paywall screen

### 11.4 Privacy Nutrition Label
- Contact Info: Email, Name (account creation)
- Purchases: Purchase history (subscription tracking)
- Usage Data: App interactions (streaks, sessions)
- Data Linked to User: Yes
- Data Used to Track: No
- Third-Party SDKs: RevenueCat (subscription), OpenAI Whisper (recitation, temporary only)

---

## 12. POST-LAUNCH ROADMAP

### V1.1 (Near-term)
- Google Sign In
- More reciters
- Additional translations (Urdu, Turkish, etc.)
- Push notifications for streak reminders
- Widget support (Home Screen, Lock Screen)

### V2 (2–3 months)
- Cloud sync with Supabase (cross-device)
- Full offline mode (download audio for offline playback)
- Verse-by-verse audio while reading
- Memorization tracking
- Prayer time blocking integration
- Social features (leaderboards, challenges)
- Advanced reading analytics

---

## APPENDIX

### A.1 Glossary
- **Surah**: Chapter of the Quran (114 total)
- **Ayah**: Verse within a surah
- **Reciter**: Person who recites the Quran aloud
- **Shield**: iOS Screen Time feature that blocks app access
- **Streak**: Consecutive days of Quran engagement
- **Session**: A period of reading or listening to Quran
- **App Limit**: Usage-based block (blocks after daily quota used)
- **Time Limit**: Schedule-based block (blocks during a time window)
- **Recite to Unblock**: Feature allowing temporary access by reciting an ayah
- **Emergency Unblock**: Weekly quota-based instant unblock until midnight

### A.2 External Documentation
- QuranAPI.pages.dev: https://quranapi.pages.dev/introduction
- RevenueCat: https://docs.revenuecat.com
- Apple FamilyControls: https://developer.apple.com/documentation/familycontrols
- OpenAI Whisper: https://platform.openai.com/docs/guides/speech-to-text

### A.3 Design References
- Opal: Premium paywall, blocking UX
- Duolingo: Streak tracking, gamification
- Headspace: Onboarding survey, meditation sessions
- Noor Focus: Quran + blocking (competitor)

---

**END OF PRD v4.0**
