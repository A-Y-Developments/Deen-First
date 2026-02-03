# Requirements - Surah Focus v1.0

**Version:** 1.0
**Last Updated:** 2026-02-03
**Milestone:** MVP - Feb 18, 2026

## Requirements Legend

| ID | Category | Priority | Status |
|----|----------|----------|--------|
| AUTH | Authentication | P0 | Pending |
| SUBS | Subscription | P0 | Pending |
| ONBO | Onboarding | P0 | Pending |
| QURAN | Quran Reading | P0 | Pending |
| LISTEN | Listening Sessions | P0 | Pending |
| BLOCK | App Blocking | P0 | Pending |
| AUDIO | Audio Playback | P0 | Pending |
| STREAK | Streak Tracking | P0 | Pending |
| HIST | Session History | P0 | Pending |
| SETT | Settings | P1 | Pending |
| NAV | Navigation | P0 | Pending |
| DATA | Data Layer | P0 | Pending |
| UI | UI Components | P1 | Pending |

---

## Authentication (AUTH)

### AUTH-01: Sign in with Apple
**Description:** User can sign in using Apple ID authentication
**Priority:** P0 - Critical
**User Story:** As a new user, I want to sign in quickly using my Apple ID so I can start using the app
**Acceptance Criteria:**
- Display "Sign in with Apple" button (iOS guidelines compliant)
- Successful auth creates user record in local database (SwiftData)
- Store user ID, email, name from Apple
- Link user ID to RevenueCat for subscription tracking
- Handle authentication errors gracefully
**Dependencies:** None

### AUTH-02: User Record Persistence
**Description:** User data stored locally in SwiftData
**Priority:** P0 - Critical
**Acceptance Criteria:**
- User entity with fields: id, authProvider, email, name, createdAt, hasCompletedOnboarding, isPremium, subscriptionExpiryDate
- Streak tracking fields: currentStreak, longestStreak, lastEngagementDate
- Relationships to sessions, blockedApps, appTimeLimits
**Dependencies:** DATA-01

### AUTH-03: Post-Sign In Navigation
**Description:** Route user based on state after sign in
**Priority:** P0 - Critical
**Acceptance Criteria:**
- First-time user → Onboarding survey
- Returning user without subscription → Paywall
- Returning subscribed user → Main tabs
**Dependencies:** AUTH-01, ONBO-01

---

## Subscription (SUBS)

### SUBS-01: RevenueCat Integration
**Description:** Integrate RevenueCat SDK for subscription management
**Priority:** P0 - Critical
**Acceptance Criteria:**
- RevenueCat SDK configured with API keys
- Entitlement "premium" configured
- Two subscription tiers: Monthly ($4.99, 3-day trial), Yearly ($29.99, 7-day trial)
**Dependencies:** None

### SUBS-02: Paywall View
**Description:** Display subscription options to user
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Display monthly and yearly pricing
- Show free trial duration
- Subscribe and restore purchase buttons
- Handle successful purchase flow
**Dependencies:** SUBS-01

### SUBS-03: Subscription Status Check
**Description:** Check and cache subscription status from RevenueCat
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Check subscription on app launch
- Update User.isPremium status
- Cache subscriptionExpiryDate locally
**Dependencies:** SUBS-01, AUTH-02

### SUBS-04: Subscription Expiration Handling
**Description:** Remove shields when subscription expires
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Detect expired subscription on app launch
- Remove all Screen Time shields (ManagedSettingsStore.shield.applications = nil)
- Navigate to paywall
- Preserve blocked apps list for re-subscription
**Dependencies:** SUBS-03, BLOCK-02

### SUBS-05: Restore Purchases
**Description:** Restore previous subscription from Apple
**Priority:** P0 - Critical
**Acceptance Criteria:**
- "Restore Purchases" button on paywall
- Check RevenueCat for active subscription
- Update user status if active subscription found
- Show error if no subscription found
**Dependencies:** SUBS-01

---

## Onboarding (ONBO)

### ONBO-01: Welcome Screen
**Description:** First screen of onboarding flow
**Priority:** P0 - Critical
**Acceptance Criteria:**
- App name and tagline display
- "Get Started" button
- Clean, modern design
**Dependencies:** None

### ONBO-02: Survey Screen 1 - Motivation
**Description:** User selects their motivations (multi-select)
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Multi-select options: consistency, distraction, routine, focus, faith, other
- Text input for "Other" option
- "Continue" button
**Dependencies:** ONBO-01

### ONBO-03: Survey Screen 2 - Timing
**Description:** User selects when they get distracted
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Time-of-day options: Morning, Afternoon, Evening, Night, All day
- Single selection
- "Continue" button
**Dependencies:** ONBO-02

### ONBO-04: Survey Screen 3 - Goals
**Description:** User selects what they want more of
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Multi-select options: Quran time, focus, less scrolling, better habits
- "Continue" button
**Dependencies:** ONBO-03

### ONBO-05: Survey Screen 4 - Time Calculation
**Description:** Show social media vs Quran time comparison
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Input for daily social media minutes
- Calculate equivalent Quran time
- Visual comparison display
- "Start Free Trial" button → Paywall
**Dependencies:** ONBO-04

---

## Quran Reading (QURAN)

### QURAN-01: Surah List
**Description:** Display all 114 surahs
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Fetch surah list from QuranAPI.pages.dev
- Display surah number, name, English name, verse count
- Search functionality
- Cache surah list indefinitely
**Dependencies:** DATA-02

### QURAN-02: Surah Detail View
**Description:** Display individual surah with verses
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Fetch surah content from API
- Display Arabic text
- Display English translation
- Scrollable verse list
- Cache surah content for 30 days
**Dependencies:** QURAN-01

### QURAN-03: Start Listening Session
**Description:** Button to start listening from surah view
**Priority:** P0 - Critical
**Acceptance Criteria:**
- "Start Session" button on surah detail
- Opens session configuration view
**Dependencies:** LISTEN-01

---

## Listening Sessions (LISTEN)

### LISTEN-01: Session Configuration View
**Description:** User selects surahs and reciter for session
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Multi-select surahs
- Reciter picker (Alafasy, Abdul Basit, Saad Al-Ghamdi, etc.)
- Set time limit (optional)
- "Start Focus" button
**Dependencies:** QURAN-01, AUDIO-01

### LISTEN-02: Active Session View
**Description:** Display current listening session
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Show current surah being played
- Playback controls (play/pause, next, previous)
- Progress indicator
- Session timer
- "End Session" button
**Dependencies:** LISTEN-01, AUDIO-02

### LISTEN-03: Session Completion
**Description:** Handle session end and save data
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Save session to database
- Update streak if applicable
- Show completion summary
- Navigate back to main tabs
**Dependencies:** LISTEN-02, STREAK-01

---

## App Blocking (BLOCK)

### BLOCK-01: FamilyControls Authorization
**Description:** Request Screen Time permission from user
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Display authorization request after paywall
- Handle granted/denied permissions
- Guide user to Settings if denied
**Dependencies:** SUBS-02

### BLOCK-02: App Selection
**Description:** User selects apps to block
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Display installed apps (via FamilyControls)
- Multi-select apps to block
- Save selection to database
**Dependencies:** BLOCK-01

### BLOCK-03: Time Limit Configuration
**Description:** User sets daily time limits for blocked apps
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Input for minutes per day per app
- Global time limit option
- Save to database
**Dependencies:** BLOCK-02

### BLOCK-04: Shield Activation
**Description:** Apply shields to selected apps
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Use ManagedSettingsStore to apply shields
- Shield respects configured time limits
- Apps become inaccessible after limit
**Dependencies:** BLOCK-03

### BLOCK-05: Time Range Scheduling
**Description:** User sets start/end times for blocking
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Time range picker (start time, end time)
- Apply blocking only during range
- Save to database
**Dependencies:** BLOCK-03

### BLOCK-06: Session-Based Blocking
**Description:** Block selected apps during listening session
**Priority:** P0 - Critical
**Acceptance Criteria:**
- When session starts, apply shields to selected apps
- When session ends, remove shields
- Override time range during session
**Dependencies:** LISTEN-02, BLOCK-04

---

## Audio Playback (AUDIO)

### AUDIO-01: Reciter Selection
**Description:** User selects reciter for audio
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Display available reciters from API
- Store user preference
- Default to Alafasy (ID 7)
**Dependencies:** None

### AUDIO-02: Audio Player
**Description:** Play surah audio using AVFoundation
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Stream audio from API URL
- Play/pause functionality
- Next/previous surah in queue
- Auto-play next surah
**Dependencies:** LISTEN-01

### AUDIO-03: Background Audio
**Description:** Audio continues when app is backgrounded
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Configure AVAudioSession for background playback
- Audio continues with app closed
- Control Center integration
- Lock screen controls
**Dependencies:** AUDIO-02

---

## Streak Tracking (STREAK)

### STREAK-01: Daily Engagement Check
**Description:** Track daily Quran engagement
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Record engagement date when user reads or listens
- Check for consecutive days
- Update currentStreak counter
- Update longestStreak if exceeded
**Dependencies:** AUTH-02

### STREAK-02: Streak Display
**Description:** Show streak count to user
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Display current streak in main tabs
- Display longest streak
- Visual streak badge/indicator
**Dependencies:** STREAK-01

### STREAK-03: Streak Reset Logic
**Description:** Handle missed days
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Reset currentStreak to 0 if day missed
- Preserve longestStreak
- Calculate missed days correctly
**Dependencies:** STREAK-01

---

## Session History (HIST)

### HIST-01: Session List
**Description:** Display past listening sessions
**Priority:** P0 - Critical
**Acceptance Criteria:**
- List sessions sorted by date (newest first)
- Show session date, duration, surahs
- Paginate if many sessions
**Dependencies:** LISTEN-03

### HIST-02: Session Detail
**Description:** Show details for individual session
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Full surah list for session
- Total duration
- Reciter used
**Dependencies:** HIST-01

---

## Settings (SETT)

### SETT-01: App Settings View
**Description:** Display app settings
**Priority:** P1 - High
**Acceptance Criteria:**
- User profile section (name, email)
- Subscription status display
- Manage subscription button
- Sign out button
**Dependencies:** AUTH-01

### SETT-02: Manage Subscription
**Description:** Link to Apple subscription management
**Priority:** P1 - High
**Acceptance Criteria:**
- Open iOS subscription management
- Handle return from settings
**Dependencies:** SUBS-03

---

## Navigation (NAV)

### NAV-01: Bottom Tab Bar
**Description:** Main navigation with 3 tabs
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Three tabs: Quran, Blocking, Settings
- Icons and labels for each tab
- Active tab highlighting
**Dependencies:** None

### NAV-02: Router Implementation
**Description:** Navigation stack management
**Priority:** P0 - Critical
**Acceptance Criteria:**
- NavigationStack with Router
- Route enum for all screens
- navigate(to:) and navigateBack() methods
- Environment object injection
**Dependencies:** None

### NAV-03: Root View
**Description:** App root with navigation setup
**Priority:** P0 - Critical
**Acceptance Criteria:**
- NavigationStack at root
- Route destination handling
- Environment object setup (router, ViewModels)
**Dependencies:** NAV-02

---

## Data Layer (DATA)

### DATA-01: SwiftData Setup
**Description:** Configure SwiftData container
**Priority:** P0 - Critical
**Acceptance Criteria:**
- ModelContainer configured with all entities
- DIContainer injects container
- LocalDataSource wraps SwiftData operations
**Dependencies:** None

### DATA-02: HTTP Client
**Description:** Network client for API calls
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Generic HTTP client
- GET request support
- Error handling with retry (3 attempts, exponential backoff)
- Timeout: 30 seconds
**Dependencies:** None

### DATA-03: Quran API Integration
**Description:** QuranAPIDataSource for API calls
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Fetch surah list (GET /surah)
- Fetch surah detail (GET /surah/{number})
- Fetch with translation (GET /surah/{number}?lang=en)
- Fetch audio URL (GET /surah/{number}/audio/{reciter_id})
**Dependencies:** DATA-02

### DATA-04: Repository Pattern
**Description:** Implement repositories for all entities
**Priority:** P0 - Critical
**Acceptance Criteria:**
- QuranRepository (surah CRUD)
- ScreenTimeRepository (blocked apps, limits)
- UserRepository (user CRUD)
- SessionRepository (session CRUD)
- Protocol + implementation pattern
**Dependencies:** DATA-01

---

## UI Components (UI)

### UI-01: Custom Button
**Description:** Reusable button component
**Priority:** P1 - High
**Acceptance Criteria:**
- Title and action closure
- Loading state
- Disabled state
- Dense and regular variants
**Dependencies:** None

### UI-02: Surah Card
**Description:** Display surah in list
**Priority:** P1 - High
**Acceptance Criteria:**
- Surah number, name, English name
- Verse count
- Tap handler
**Dependencies:** None

### UI-03: Streak Badge
**Description:** Display streak count
**Priority:** P1 - High
**Acceptance Criteria:**
- Circular badge with number
- Fire/flame icon
- Animated on change
**Dependencies:** STREAK-02

### UI-04: Audio Player Controls
**Description:** Playback control buttons
**Priority:** P0 - Critical
**Acceptance Criteria:**
- Play/pause button
- Next/previous buttons
- Progress bar
- Time display
**Dependencies:** AUDIO-02

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 2 | Pending |
| AUTH-02 | Phase 2 | Pending |
| AUTH-03 | Phase 2 | Pending |
| SUBS-01 | Phase 2 | Pending |
| SUBS-02 | Phase 2 | Pending |
| SUBS-03 | Phase 2 | Pending |
| SUBS-04 | Phase 2 | Pending |
| SUBS-05 | Phase 2 | Pending |
| ONBO-01 | Phase 3 | Pending |
| ONBO-02 | Phase 3 | Pending |
| ONBO-03 | Phase 3 | Pending |
| ONBO-04 | Phase 3 | Pending |
| ONBO-05 | Phase 3 | Pending |
| BLOCK-01 | Phase 3 | Pending |
| BLOCK-02 | Phase 3 | Pending |
| BLOCK-03 | Phase 6 | Pending |
| BLOCK-04 | Phase 6 | Pending |
| BLOCK-05 | Phase 6 | Pending |
| BLOCK-06 | Phase 5 | Pending |
| QURAN-01 | Phase 4 | Pending |
| QURAN-02 | Phase 4 | Pending |
| QURAN-03 | Phase 4 | Pending |
| DATA-03 | Phase 4 | Pending |
| AUDIO-01 | Phase 4 | Pending |
| LISTEN-01 | Phase 5 | Pending |
| LISTEN-02 | Phase 5 | Pending |
| LISTEN-03 | Phase 6 | Pending |
| AUDIO-02 | Phase 5 | Pending |
| AUDIO-03 | Phase 5 | Pending |
| SETT-01 | Phase 6 | Pending |
| SETT-02 | Phase 6 | Pending |
| STREAK-01 | Phase 7 | Pending |
| STREAK-02 | Phase 7 | Pending |
| STREAK-03 | Phase 7 | Pending |
| HIST-01 | Phase 7 | Pending |
| HIST-02 | Phase 7 | Pending |
| NAV-01 | Phase 4 | Pending |
| NAV-02 | Phase 1 | Pending |
| NAV-03 | Phase 1 | Pending |
| DATA-01 | Phase 1 | Pending |
| DATA-02 | Phase 1 | Pending |
| DATA-04 | Phase 1 | Pending |
| UI-01 | Phase 1 | Pending |
| UI-02 | Phase 3 | Pending |
| UI-03 | Phase 7 | Pending |
| UI-04 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 50 total
- Mapped to phases: 50
- Unmapped: 0 ✓

---

## Summary

**Total Requirements:** 50

**By Priority:**
- P0 (Critical): 44
- P1 (High): 6

**By Category:**
- Authentication: 3
- Subscription: 5
- Onboarding: 5
- Quran Reading: 3
- Listening Sessions: 3
- App Blocking: 6
- Audio Playback: 3
- Streak Tracking: 3
- Session History: 2
- Settings: 2
- Navigation: 3
- Data Layer: 4
- UI Components: 4
