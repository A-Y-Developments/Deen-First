# Project: Surah Focus

**Created:** 2026-02-03
**Status:** Active
**Milestone:** v1.0 MVP

## Core Value

Premium iOS app combining Quran reading with screen time management to help Gen Z Muslims build consistent habits through app blocking and streak tracking.

## One-Liner

Quran reading app that blocks distracting apps until you read.

## Problem

Gen Z Muslims (ages 16-28) struggle with phone addiction and doom scrolling, neglecting Quran reading despite wanting to reconnect.

## Solution

Block distracting apps with daily time limits; unlock consistent Quran engagement through streak-based gamification using Apple's native Screen Time API.

## Target Users

- **Primary:** Gen Z Muslims, ages 16-28, tech-savvy, aware of phone addiction
- **Secondary:** Muslim parents managing children's screen time

## Success Criteria

**V1 Goal:** Submit to App Store by February 18, 2026

** measurable criteria:**
- Sign in with Apple works
- RevenueCat subscription flows complete
- Quran reading/browsing functional
- Listening sessions with audio playback
- App blocking via FamilyControls
- Streak tracking operational

## Technical Stack

| Component | Technology |
|-----------|------------|
| Platform | iOS 17+ |
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Architecture | Clean Architecture + MVVM |
| Database | SwiftData (local only) |
| Auth | Sign in with Apple |
| Monetization | RevenueCat SDK |
| Screen Time | FamilyControls framework |
| Quran API | QuranAPI.pages.dev |
| Audio | AVFoundation (background) |
| Build System | Tuist |

## Key Constraints

- **Timeline:** 16 days (Feb 3-18, 2026)
- **Budget:** Solo developer
- **Scope:** V1 MVP - no cloud sync, no Google auth, no offline mode
- **Platform:** iOS only
- **Business:** Subscription-only ($4.99/mo or $29.99/yr)

## Key Decisions

| Decision | Rationale | Date |
|----------|-----------|------|
| Local-only data | No backend complexity for V1; SwiftData sufficient | 2026-02-03 |
| Apple auth only | Faster integration; Google deferred to V2 | 2026-02-03 |
| Single Quran API | No backup needed; QuranAPI.pages.dev reliable | 2026-02-03 |
| No offline audio | Reduce scope; audio streaming sufficient for V1 | 2026-02-03 |
| Tuist build system | Reproducible builds; easy dependency management | 2026-02-03 |

## Known Issues

- Current Xcode project uses iOS 26.0 (future version) - must fix to iOS 17.0
- No .gitignore - needs to be created
- No git commits yet - repository not initialized
- Team ID hardcoded in project file - should use environment variable

## Out of Scope (V1)

- Google Sign In
- Cloud sync / Supabase backend
- Full offline mode (audio downloads)
- Verse-by-verse audio during reading
- Speech recognition / pronunciation feedback
- Social features / sharing
- Prayer time integration
- Tafsir (commentary)
- Advanced analytics / heatmaps
- Reward system (earn unblock time)
- Bookmarking specific ayahs

## Future Considerations (V2+)

- Cloud sync with Supabase
- Full offline audio downloads
- Google Sign In option
- Memorization tracking
- Community challenges
- Social streak leaderboards
- Widgets (Today view, Lock Screen)
- Prayer time blocking
- Advanced reading analytics
- Verse-by-verse audio while reading
