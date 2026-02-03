# Roadmap: Surah Focus

## Overview

Build a premium iOS app combining Quran reading with screen time management for Gen Z Muslims. The journey begins with project infrastructure, moves through authentication and subscription setup, implements core Quran features, adds app blocking via FamilyControls, and concludes with streak tracking and polish for TestFlight submission.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Project scaffolding and core infrastructure
- [ ] **Phase 2: Auth + Subscription** - Sign in with Apple, RevenueCat, paywall
- [ ] **Phase 3: Onboarding + Screen Time** - Survey flow, FamilyControls authorization
- [ ] **Phase 4: Quran Reading** - API integration, surah browsing
- [ ] **Phase 5: Listening + Audio** - Audio playback, focus sessions
- [ ] **Phase 6: Blocking + Settings** - Time limits, shields, settings
- [ ] **Phase 7: Streak + History** - Progress tracking, session history
- [ ] **Phase 8: Polish + Testing** - Integration tests, TestFlight build

## Phase Details

### Phase 1: Foundation
**Goal**: Project scaffolding and core infrastructure
**Depends on**: Nothing (first phase)
**Requirements**: DATA-01, DATA-02, DATA-04, NAV-02, NAV-03, UI-01
**Success Criteria** (what must be TRUE):
  1. Project builds and runs on device/simulator
  2. DIContainer provides all dependencies
  3. Navigation stack works between screens
  4. SwiftData persists User entity
**Research**: Unlikely (established iOS patterns)
**Plans**: TBD

Plans:
- [ ] 01-01: Tuist setup and folder structure
- [ ] 01-02: DIContainer and navigation
- [ ] 01-03: Data layer and entities

### Phase 2: Auth + Subscription
**Goal**: User can sign in with Apple and subscribe
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, SUBS-01, SUBS-02, SUBS-03, SUBS-04, SUBS-05
**Success Criteria** (what must be TRUE):
  1. User signs in with Apple → User record created
  2. Paywall displays → User can subscribe
  3. Subscription status checked → isPremium updated
  4. Expired subscription → Shields removed
**Research**: Likely (RevenueCat SDK integration, subscription expiration patterns)
**Research topics**: RevenueCat SDK setup, entitlement configuration, webhook handling, shield removal on expiration
**Plans**: TBD

Plans:
- [ ] 02-01: Sign in with Apple integration
- [ ] 02-02: RevenueCat and paywall
- [ ] 02-03: Subscription status and expiration

### Phase 3: Onboarding + Screen Time
**Goal**: New users complete setup and authorize screen time
**Depends on**: Phase 2
**Requirements**: ONBO-01, ONBO-02, ONBO-03, ONBO-04, ONBO-05, BLOCK-01, BLOCK-02, UI-02
**Success Criteria** (what must be TRUE):
  1. User completes 4-screen survey
  2. FamilyControls authorization granted
  3. User selects apps to block
  4. Selections saved to database
**Research**: Likely (FamilyControls framework, Shield configuration)
**Research topics**: FamilyControls authorization flow, ManagedSettingsStore API, app selection UI patterns
**Plans**: TBD

Plans:
- [ ] 03-01: Onboarding survey screens
- [ ] 03-02: FamilyControls authorization
- [ ] 03-03: App selection UI

### Phase 4: Quran Reading
**Goal**: User can browse and read Quran
**Depends on**: Phase 1
**Requirements**: DATA-03, QURAN-01, QURAN-02, QURAN-03, AUDIO-01, NAV-01
**Success Criteria** (what must be TRUE):
  1. User sees all 114 surahs
  2. User searches surah by name
  3. User opens surah → sees Arabic + English
  4. User taps "Start Session" button
**Research**: Unlikely (standard API integration)
**Plans**: TBD

Plans:
- [ ] 04-01: Quran API integration
- [ ] 04-02: Surah list and detail views
- [ ] 04-03: Search and caching

### Phase 5: Listening + Audio
**Goal**: User can listen to Quran with focus mode
**Depends on**: Phase 4, Phase 3
**Requirements**: LISTEN-01, LISTEN-02, AUDIO-02, AUDIO-03, BLOCK-06, UI-04
**Success Criteria** (what must be TRUE):
  1. User selects surahs + reciter
  2. Audio plays with controls
  3. Audio continues when app backgrounded
  4. Blocked apps during session
**Research**: Likely (AVFoundation background audio, session-based blocking)
**Research topics**: AVAudioSession background configuration, Control Center integration, shield activation during sessions
**Plans**: TBD

Plans:
- [ ] 05-01: Session configuration view
- [ ] 05-02: Audio player and controls
- [ ] 05-03: Background audio and session blocking

### Phase 6: Blocking + Settings
**Goal**: Users configure app blocking limits
**Depends on**: Phase 3
**Requirements**: BLOCK-03, BLOCK-04, BLOCK-05, SETT-01, SETT-02, LISTEN-03
**Success Criteria** (what must be TRUE):
  1. User sets daily time limits per app
  2. User sets time range (start/end)
  3. Shields applied to blocked apps
  4. Settings view shows user info
**Research**: Unlikely (builds on Phase 3 patterns)
**Plans**: TBD

Plans:
- [ ] 06-01: Time limit and range configuration
- [ ] 06-02: Shield activation
- [ ] 06-03: Settings view and session completion

### Phase 7: Streak + History
**Goal**: Users see their progress and streaks
**Depends on**: Phase 6
**Requirements**: STREAK-01, STREAK-02, STREAK-03, HIST-01, HIST-02, UI-03
**Success Criteria** (what must be TRUE):
  1. Engagement recorded after session
  2. Streak counter updates
  3. Streak displays in main tabs
  4. Session history list shows past sessions
**Research**: Unlikely (internal logic)
**Plans**: TBD

Plans:
- [ ] 07-01: Streak tracking logic
- [ ] 07-02: Streak display and history views

### Phase 8: Polish + Testing
**Goal**: App is ready for TestFlight
**Depends on**: Phase 7
**Requirements**: (Validation phase - no new requirements)
**Success Criteria** (what must be TRUE):
  1. All integration tests pass
  2. No critical bugs
  3. TestFlight build uploads successfully
**Research**: Unlikely (testing and polish)
**Plans**: TBD

Plans:
- [ ] 08-01: Integration tests
- [ ] 08-02: Bug fixes and polish
- [ ] 08-03: TestFlight build

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/3 | Not started | - |
| 2. Auth + Subscription | 0/3 | Not started | - |
| 3. Onboarding + Screen Time | 0/3 | Not started | - |
| 4. Quran Reading | 0/3 | Not started | - |
| 5. Listening + Audio | 0/3 | Not started | - |
| 6. Blocking + Settings | 0/3 | Not started | - |
| 7. Streak + History | 0/2 | Not started | - |
| 8. Polish + Testing | 0/3 | Not started | - |
