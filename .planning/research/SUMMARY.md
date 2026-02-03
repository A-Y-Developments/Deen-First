# Research Summary: Surah Focus

**Project:** iOS Quran + Screen Time Management App
**Research Date:** 2026-02-03
**Overall Confidence:** HIGH

---

## Executive Summary

Surah Focus combines two mature app categories: Quran reading and screen time management. Research shows both categories have established patterns, clear table stakes, and proven monetization strategies. The unique differentiator—conditional app blocking triggered by Quran reading—has no direct competitor executing well.

**Key Findings:**
- **Stack is mature and stable:** iOS 17 + SwiftUI + SwiftData + FamilyControls + RevenueCat + QuranAPI
- **Architecture pattern established:** Clean Architecture + MVVM with separate Screen Time extensions
- **Critical path identified:** FamilyControls entitlement approval is gating factor (1-2 weeks)
- **Main risk:** Screen Time API complexity + App Store rejection via entitlement/sandbox issues

---

## Stack Research Summary

**Recommendation:** iOS 17.0 + SwiftUI + SwiftData + FamilyControls + QuranAPI + RevenueCat 5.x

| Component | Choice | Confidence |
|-----------|--------|------------|
| Platform | iOS 17.0+ | HIGH |
| UI | SwiftUI (iOS 17+) | HIGH |
| Database | SwiftData (local only) | HIGH |
| Quran Data | QuranAPI.pages.dev | HIGH |
| Screen Time | FamilyControls framework | HIGH |
| Audio | AVFoundation | HIGH |
| Auth | Sign in with Apple only | HIGH |
| Monetization | RevenueCat 5.x | HIGH |
| Build | Xcode (add Tuist Phase 2) | MEDIUM |

**Critical fixes needed:**
- iOS deployment target: 26.0 → 17.0 (IMMEDIATE)
- FamilyControls entitlement: Submit request Day 1 (1-2 week approval)
- Team ID hardcoded: Remove/use env var
- .gitignore: Create to exclude sensitive files

---

## Features Research Summary

**Table Stakes (Must Have):**
- Complete Quran text (114 surahs) + translations
- Audio recitation (4-5 reciters)
- Search functionality
- Streak tracking
- App selection + blocking
- Daily time limits
- Hard paywall + free trial

**Differentiators (Competitive Advantage):**
- **Conditional blocking:** Block apps UNTIL Quran read (no competitor does this well)
- **Streak gamification:** Proven habit-formation pattern
- **Premium positioning:** Hard paywall (12.11% vs 2.18% freemium conversion)
- **Minimalist UX:** vs Muslim Pro's cluttered interface

**V1 Scope:**
- Quran reading/listening
- App blocking (all-day schedule)
- Streaks
- Subscription-only (hard paywall)

**V2+ Deferred:**
- Cloud sync, offline audio, Google auth, social features, prayer times, tafsir

---

## Architecture Research Summary

**Pattern:** Clean Architecture + MVVM with SwiftUI

**Layers:**
```
Presentation (Views/ViewModels)
    ↓
Domain (Services/Entities)
    ↓
Data (Repositories/DataSources)
    ↓
Extensions (Screen Time via App Groups)
```

**Critical integration points:**
1. **Screen Time API** requires separate extension targets communicating via App Groups
2. **RevenueCat** must initialize in `SurahFocusApp.swift` before UI
3. **Background audio** needs `UIBackgroundModes: audio` in Info.plist
4. **SwiftData** should use `VersionedSchema` from day one

**Build order:** Foundation → Auth/RevenueCat → Screen Time → Quran/Audio → Tabs → Polish

---

## Pitfalls Research Summary

**CRITICAL App Store Rejection Risks:**

| Risk | Level | Prevention |
|------|-------|------------|
| No FamilyControls entitlement | CRITICAL | Submit request Day 1 |
| RevenueCat sandbox errors | HIGH | Test 5+ sandbox accounts |
| Quran content errors | HIGH | Verify with native speaker |
| iOS 26.0 deployment target | HIGH | Change to 17.0 IMMEDIATELY |
| Background audio not working | MEDIUM | Test on physical device |
| Shields persist after unsubscribe | HIGH | Test expiration flow |

**Most common mistakes:**
- Forgetting to request FamilyControls entitlement early
- Not testing RevenueCat sandbox thoroughly
- Hardcoded Team IDs in project files
- Missing .gitignore for sensitive files

---

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1 - Foundation (Days 1-2)
**Addresses:** Critical setup issues from PITFALLS.md
**Uses:** iOS 17.0 target from STACK.md
**Avoids:** Entitlement rejection (submit immediately)

**Tasks:**
- Fix iOS 26.0 → 17.0 deployment target
- Create .gitignore
- Remove hardcoded Team ID
- Submit FamilyControls entitlement request
- Set up SwiftData with VersionedSchema
- DIContainer + folder structure

### Phase 2 - Auth + Subscription (Days 3-4)
**Addresses:** Table stakes from FEATURES.md
**Uses:** RevenueCat 5.x integration from STACK.md
**Avoids:** Sandbox rejection (test thoroughly)

**Tasks:**
- Sign in with Apple
- RevenueCat integration
- Paywall UI
- Subscription status checking
- Shield removal on expiration

### Phase 3 - Screen Time Setup (Days 5-6)
**Addresses:** Core differentiator from FEATURES.md
**Uses:** FamilyControls architecture from ARCHITECTURE.md
**Avoids:** Shield configuration issues from PITFALLS.md

**Tasks:**
- App Groups setup
- Extension targets (Monitor + Shield)
- FamilyActivityPicker integration
- Permission request flow
- Shield configuration UI

### Phase 4 - Quran Reading (Days 7-8)
**Addresses:** Table stakes from FEATURES.md
**Uses:** QuranAPI from STACK.md
**Avoids:** Content accuracy issues from PITFALLS.md

**Tasks:**
- QuranAPIClient
- Caching strategy (30-day expiry)
- Surah list + detail views
- Arabic + translation display
- Content verification

### Phase 5 - Audio + Sessions (Days 9-10)
**Addresses:** Table stakes + differentiator from FEATURES.md
**Uses:** AVFoundation background audio from STACK.md
**Avoids:** Audio background issues from PITFALLS.md

**Tasks:**
- AVAudioSession configuration
- Background mode setup
- Now Playing info
- Listening session flow
- Auto-play next surah

### Phase 6 - Integration (Days 11-12)
**Addresses:** Full feature integration
**Uses:** Data flows from ARCHITECTURE.md
**Avoids:** Session expiration bugs from PITFALLS.md

**Tasks:**
- Main tabs wiring
- Streak calculation logic
- Session tracking
- Subscription expiration flow
- Shield removal testing

### Phase 7 - Polish (Days 13-14)
**Addresses:** UX polish from FEATURES.md
**Uses:** Minimalist design principle
**Avoids:** User experience issues

**Tasks:**
- Loading states
- Error handling
- Streak visualization
- Settings screen
- Onboarding completion

### Phase 8 - TestFlight + Submit (Days 15-16)
**Addresses:** App Store submission from PITFALLS.md
**Uses:** Testing checklist from PITFALLS.md
**Avoids:** Rejection risks

**Tasks:**
- TestFlight upload (Day 13)
- Sandbox testing (5+ accounts)
- Physical device testing (audio + shield)
- Privacy policy + terms
- App Store metadata
- Submission (Day 16)

---

## Phase Ordering Rationale

**Why this order based on dependencies discovered in ARCHITECTURE.md:**

1. **Foundation first:** All components depend on DIContainer + SwiftData setup
2. **Auth before Screen Time:** RevenueCat gating needed before blocking features
3. **Screen Time before Audio:** Blocking is core differentiator, more complex
4. **Audio after Quran:** Depends on Quran API for audio URLs
5. **Integration last:** Requires all features to be working

**Why this grouping based on PITFALLS.md prevention strategies:**

1. **Phase 1 tackles IMMEDIATE risks:** iOS target, entitlement request
2. **Phase 2-3 tackle HIGH-risk features:** RevenueCat sandbox, Screen Time API
3. **Phase 4-5 tackle MEDIUM-risk features:** API integration, background audio
4. **Phase 6-7 tackle refinement:** Integration, polish
5. **Phase 8 tackles submission risks:** Rejection prevention

---

## Research Flags for Phases

- **Phase 3:** Likely needs deeper research (Screen Time extension communication patterns). Test on physical device early.
- **Phase 5:** Standard patterns (AVFoundation), unlikely to need research.
- **Phase 6:** Shield removal on subscription expiration is untested pattern—research edge cases.

---

## Unresolved Questions

None from research phase. V1 scope is well-defined.

**Questions for requirements phase:**
- Should we offer Quran reading without subscription? (App Store may reject hard paywall)
- How many reciters minimum for V1? (4-5 recommended)
- Should streak have grace period for missed days?

---

## Sources Summary

**HIGH confidence sources:**
- Apple official docs (FamilyControls, AVFoundation, Sign in with Apple)
- RevenueCat official docs + 2025 subscription report
- QuranAPI.pages.dev official site
- Muslim Pro, Quran.com, Quranly official sites
- App Store Review Guidelines

**MEDIUM confidence sources:**
- Medium articles on Screen Time API implementation
- Community tutorials on Clean Architecture + MVVM
- Research articles on Gen Z Muslim preferences

**LOW confidence sources (needs verification):**
- Reddit discussions on Quran app errors
- Individual StackOverflow posts
- Unverified community posts

---

## Next Steps

1. **Immediate actions (today):**
   - Change iOS 26.0 → 17.0
   - Create .gitignore
   - Submit FamilyControls entitlement request

2. **Define requirements:** `/gsd:define-requirements`
   - Map V1 features to user stories
   - Add acceptance criteria
   - Prioritize by complexity (from FEATURES.md)

3. **Create roadmap:** `/gsd:create-roadmap`
   - Use phase structure from above
   - Allocate days per phase
   - Buffer days for risks

---

**Research complete.** Ready for requirements definition phase.
