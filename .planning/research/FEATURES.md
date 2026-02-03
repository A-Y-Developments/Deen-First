# Features Research: Surah Focus

**Researched:** 2026-02-03
**Domain:** iOS Quran + Screen Time Management App
**Research Type:** Project Research - Feature Landscape
**Confidence:** HIGH

---

## Summary

Surah Focus combines two established app categories: Quran reading/study apps and screen time/app-blocking apps. Research shows both categories have mature feature sets with clear table stakes requirements. The unique differentiator is the **integration**: blocking apps until Quran is read, rather than treating these as separate concerns.

**Primary competitors:**
- **Quran apps:** Muslim Pro, Quran.com, Quranly
- **Blocking apps:** Opal, Freedom, Jomo, built-in iOS Screen Time
- **Hybrid (closest):** Noor Focus (Quran + blocking combination exists)

**Key insight:** Quran apps have strong habit-formation features (streaks, goals) but no blocking. Blocking apps have strong enforcement but no spiritual/growth component. Surah Focus uniquely connects these: read Quran → earn focus time.

---

## Table Stakes Features (Must Have)

These are features users expect in each category. Without them, users will leave.

### Quran Reading Features

#### 1. Complete Quran Text (114 Surahs)
- **Feature:** Full Quran text in Arabic with translations
- **Description:** Browse all 114 surahs, read Arabic + English translation
- **Complexity:** Medium (API integration, UI)
- **Dependencies:** Quran API, caching strategy
- **App Store Impact:** None expected
- **Examples:** Muslim Pro, Quran.com, every Quran app
- **Notes:** Table stakes. Users expect complete Quran, not partial.

#### 2. Audio Recitation
- **Feature:** Listen to Quran with multiple reciters
- **Description:** Stream audio recitations, background playback
- **Complexity:** High (AVFoundation, background audio)
- **Dependencies:** Audio API, background modes
- **App Store Impact:** Must declare background audio in Info.plist
- **Examples:** Muslim Pro, Quran.com, all Quran apps
- **Notes:** Expected feature. Users need to listen to Quran.

#### 3. Search Functionality
- **Feature:** Search surahs by name/number
- **Description:** Find surahs quickly via search bar
- **Complexity:** Low
- **Dependencies:** None
- **App Store Impact:** None
- **Examples:** Muslim Pro, Quran.com, Quranly
- **Notes:** Basic UX requirement.

#### 4. Progress Tracking
- **Feature:** Track reading/listening history
- **Description:** See what you've read, session history
- **Complexity:** Medium (local persistence)
- **Dependencies:** SwiftData, session tracking
- **App Store Impact:** None
- **Examples:** Quranly (streaks), Muslim Pro (reading progress)
- **Notes:** Users want to see their engagement. Habit formation requires tracking.

#### 5. Streak System
- **Feature:** Consecutive days tracking
- **Description:** Show daily streak, celebrate consistency
- **Complexity:** Medium (date logic, persistence)
- **Dependencies:** Session data, date calculations
- **App Store Impact:** None
- **Examples:** Quranly, Duolingo, Headspace
- **Notes:** Proven gamification pattern. Critical for habit formation.

### App Blocking Features

#### 6. App Selection
- **Feature:** Choose apps to block
- **Description:** User picks which apps to limit (FamilyActivityPicker)
- **Complexity:** Medium (FamilyControls framework)
- **Dependencies:** FamilyControls authorization
- **App Store Impact:** Requires Screen Time permission description
- **Examples:** Opal, Freedom, iOS Screen Time
- **Notes:** Essential. Users want choice, not pre-selected apps.

#### 7. Daily Time Limits
- **Feature:** Set daily app time limits
- **Description:** Configure X minutes/day for selected apps
- **Complexity:** High (DeviceActivity monitoring, shield application)
- **Dependencies:** DeviceActivity framework, ManagedSettings
- **App Store Impact:** Requires proper entitlements
- **Examples:** Opal, iOS Screen Time
- **Notes:** Core blocking mechanism. Expected in any blocking app.

#### 8. Blocking Enforcement (Shield)
- **Feature:** Apps actually get blocked
- **Description:** Show custom blocked screen when limit reached
- **Complexity:** High (ManagedSettings, ShieldConfiguration extension)
- **Dependencies:** ManagedSettings framework, custom shield UI
- **App Store Impact:** Must comply with FamilyControls usage policies
- **Examples:** Opal, Freedom
- **Notes:** The whole point of blocking. Must work reliably.

#### 9. Schedule Configuration
- **Feature:** Set time ranges for blocking
- **Description:** "All day" vs custom time range (e.g., 9 AM - 11 PM)
- **Complexity:** Medium (DeviceActivitySchedule)
- **Dependencies:** DeviceActivity framework
- **App Store Impact:** None
- **Examples:** Opal, Freedom
- **Notes:** Basic scheduling. Users don't want blocking 24/7 forever.

### Monetization & Access

#### 10. Subscription Paywall
- **Feature:** Hard paywall with free trial
- **Description:** Must subscribe after trial to access features
- **Complexity:** Medium (RevenueCat integration, paywall UI)
- **Dependencies:** RevenueCat SDK, App Store Connect products
- **App Store Impact:** Must comply with subscription guidelines
- **Examples:** Most productivity apps (Headspace, Calm, Opal)
- **Notes:** Business model. RevenueCat data shows hard paywalls convert better than freemium.

#### 11. Free Trial (3-7 days)
- **Feature:** Trial period before charge
- **Description:** 3-day (monthly) or 7-day (yearly) free trial
- **Complexity:** Low (configured in App Store Connect)
- **Dependencies:** App Store Connect product setup
- **App Store Impact:** Must honor trial period, clear disclosure
- **Examples:** Industry standard (Opal: 7-day, Freedom: trial available)
- **Notes:** RevenueCat data: longer trials (17-32 days) convert better, but 3-7 day is acceptable.

#### 12. Restore Purchases
- **Feature:** Restore previous subscription
- **Description:** "Restore Purchases" button for re-installs
- **Complexity:** Low (RevenueCat handles this)
- **Dependencies:** RevenueCat SDK
- **App Store Impact:** Required by Apple guidelines
- **Examples:** Every subscription app
- **Notes:** Apple requirement. Must include button.

### Onboarding

#### 13. Sign in with Apple
- **Feature:** Quick authentication
- **Description:** Sign in with Apple (no Google for V1)
- **Complexity:** Low (AuthenticationServices framework)
- **Dependencies:** AuthenticationServices, user record
- **App Store Impact:** Must follow Sign in with Apple guidelines
- **Examples:** Most iOS apps
- **Notes:** Table stakes for iOS. V1: Apple only (simpler).

#### 14. Onboarding Survey
- **Feature:** Welcome + motivation survey
- **Description:** 4-screen survey asking about goals, distractions
- **Complexity:** Medium (UX design, data storage)
- **Dependencies:** None
- **App Store Impact:** None
- **Examples:** Headspace, Noom, Opal
- **Notes:** Best practice. Increases trial conversion (RevenueCat: onboarding critical for Day 0 trials).

#### 15. Permission Request Flow
- **Feature:** Screen Time permission request
- **Description:** Clear explanation + native permission dialog
- **Complexity:** Medium (FamilyControls authorization)
- **Dependencies:** FamilyControls framework
- **App Store Impact:** Requires proper usage description
- **Examples:** Opal, Freedom
- **Notes:** Required for blocking to work. Must be clear and user-friendly.

---

## Differentiating Features

### Unique Value Proposition

#### Feature: Conditional App Blocking (Core Differentiator)
- **What:** Block apps UNTIL user reads Quran, not just time limits
- **Why Unique:** No existing app combines Quran + blocking this way
- **Competitor Gap:**
  - Muslim Pro/Quran.com: Great Quran features, no blocking
  - Opal/Freedom: Great blocking, no Quran/growth component
  - Noor Focus: Exists (Quran + blocking), but unclear if "read to unblock" mechanic exists
- **Psychology:** Taps into accountability, guilt reduction ("I'm reading Quran instead of scrolling")
- **Complexity:** High (requires linking Quran activity to shield removal)
- **App Store Impact:** None (uses standard Screen Time API)

### Streak Gamification

#### Feature: Quran Engagement Streaks
- **What:** Track consecutive days of Quran reading/listening
- **Why It Works:**
  - Loss aversion: "Don't break the chain"
  - Social proof: See streak badge on profile
  - Progress principle: Visual feedback on consistency
- **Complexity:** Medium (date logic, session tracking)
- **Examples:** Quranly (does this well), Duolingo, language learning apps
- **Evidence:** Quranly positions itself as "habit-building Quran app" - this is their main differentiator

### Premium Positioning

#### Feature: Hard Paywall (No Free Tier)
- **What:** Must subscribe after trial (no free tier)
- **Why It Works:**
  - RevenueCat 2025 data: Hard paywalls have 12.11% median conversion vs 2.18% freemium
  - Filters for committed users
  - Clearer value communication
- **Complexity:** Low (business model decision)
- **Evidence:** RevenueCat report shows hard paywalls outperform freemium in conversion

### Listening Sessions with Blocking

#### Feature: "Focus Mode" Sessions
- **What:** Block apps ONLY while listening to Quran
- **Why It Works:**
  - Immediate reward: Listen → apps blocked (prevents distraction during spiritual time)
  - Session-based: Clear start/end, unlike permanent time limits
- **Complexity:** High (audio playback + shield management + state coordination)
- **Examples:** Opal has "focus sessions" but without Quran component
- **Note:** This is V1's core differentiator

### Simple, Focused UX

#### Feature: Minimalist Design (vs. cluttered competitors)
- **What:** Clean, distraction-free interface (vs. Muslim Pro's many features)
- **Why It Works:**
  - Gen Z preferences: Minimalist, mobile-first design
  - Focus on core value: Read + block, not prayer times, Qibla, etc.
- **Complexity:** Medium (requires disciplined product decisions)
- **Examples:** Quran.com (clean), Quranly (simple)
- **Contrast:** Muslim Pro is feature-heavy (prayer times, Qibla, Duas, etc.)

---

## Feature Dependencies

```
[Sign in with Apple]
    ↓
[Onboarding Survey]
    ↓
[Paywall + Subscribe]
    ↓
[Screen Time Permission]
    ↓
[App Selection + Time Limits]
    ↓
[Main Features Unlocked]
    ├─ [Quran Reading]
    ├─ [Listening Sessions]
    ├─ [Streak Tracking]
    └─ [App Blocking]
```

**Critical dependencies:**
1. **Subscription → All features:** Hard paywall means nothing works without subscription
2. **Screen Time permission → Blocking:** Can't block without authorization
3. **Quran API → Reading/Listening:** Can't display Quran without data source
4. **Session tracking → Streaks:** Can't track streaks without recording sessions
5. **Audio → Background playback:** Listening sessions require background audio capability

**Technical dependency chain:**
```
RevenueCat SDK → Subscription check
FamilyControls → App blocking
QuranAPI → Quran content
SwiftData → Local persistence (streaks, history)
AVFoundation → Audio playback
```

---

## Anti-Features (What NOT to Build)

### Explicitly Out of Scope (V1)

| Feature | Why Excluded | Complexity | When to Consider |
|---------|--------------|------------|------------------|
| **Google Sign In** | Reduce auth complexity, Apple is sufficient for V1 | Low | V2 when user base expands beyond iOS |
| **Cloud sync / Supabase** | Local-only SwiftData meets V1 needs, reduces backend complexity | High | V2 when cross-device sync requested |
| **Offline audio downloads** | Downloads are 5-30MB/surah, streaming sufficient for V1 | High | V2 when offline usage is pain point |
| **Verse-by-verse audio** | Reading view + audio sync is complex, surah-level audio is table stakes | Very High | V2 when advanced study features requested |
| **Speech recognition** | Nice-to-have, not essential for V1 value prop | Very High | V2 for memorization/practice features |
| **Social features** | Privacy-first approach, social adds complexity | Medium | V2 for community/growth |
| **Prayer time integration** | Muslim Pro does this well, we're focused on Quran + blocking | Medium | V2 if requested (compete less directly) |
| **Tafsir (commentary)** | Quran.com does this excellently, not core to V1 | Medium | V2 for study features |
| **Advanced analytics** | Basic session tracking sufficient for V1 | Medium | V2 for power users |
| **Bookmarking ayahs** | Session history provides context, bookmarks add complexity | Low | V2 for study features |
| **Reward system** | Explicitly excluded: "Earn unblock time by reading" creates wrong incentives | High | NEVER (undermines discipline aspect) |

### Things Competitors Do That We Should Avoid

| Anti-Feature | Competitor | Why Avoid |
|--------------|-----------|-----------|
| **Cluttered UI** | Muslim Pro | Gen Z prefers minimalism, too many features dilute focus |
| **Ads in free tier** | Muslim Pro | We're subscription-only (premium positioning) |
| **Prayer time notifications** | Muslim Pro | Not core value prop, notification fatigue |
| **Too many reciters** | Some apps | 4-5 reciters sufficient for V1, choice paralysis |
| **Social sharing** | Some apps | Privacy-first, Quran engagement is personal |
| **Gamification gone wrong** | Some apps | Streak badge is enough, don't overdo points/badges |
| **Long, complex onboarding** | Some apps | 4 screens is max (RevenueCat: Day 0 trials critical) |
| **Hard paywall AFTER free features** | Freemium models | Hard paywall from start is clearer (RevenueCat data) |
| **Weekly subscriptions** | Some apps | Weekly has terrible retention (3-6% after 6 months per RevenueCat) |
| **Low-priced tiers** | Some apps | Premium pricing converts better long-term |

---

## Competitor Feature Matrix

| Feature | Muslim Pro | Quran.com | Quranly | Opal | Freedom | Surah Focus V1 |
|---------|-----------|-----------|---------|------|---------|----------------|
| **Quran Text** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Translations** | ✅ (40+) | ✅ | ✅ | ❌ | ❌ | ✅ (English only V1) |
| **Audio Recitation** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Reciter Options** | ✅ (many) | ✅ | ✅ | ❌ | ❌ | ✅ (4-5) |
| **Search** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Streak Tracking** | ✅ (Reading Progress) | ✅ (New) | ✅ (Core) | ❌ | ❌ | ✅ |
| **Session History** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **App Blocking** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Time Limits** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Schedule Blocking** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ (V1: all day, V2: custom) |
| **Listening Sessions** | ✅ | ✅ | ✅ | ✅ (focus mode) | ❌ | ✅ (with blocking) |
| **Prayer Times** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Qibla Compass** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Tafsir** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Memorization** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ (V2) |
| **Social Features** | ❌ | ✅ (community) | ✅ (friends) | ❌ | ❌ | ❌ |
| **Offline Mode** | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ (text only, audio streaming) |
| **Subscription Model** | Freemium | Free | Freemium | Subscription | Freemium | Hard paywall |
| **iOS Only** | ❌ (Android) | ❌ (Web/Android) | ❌ (Web/Android) | ✅ | ✅ | ✅ (iOS-only V1) |
| **Sign in with Apple** | ✅ | ❌ | ❌ | N/A | N/A | ✅ |
| **Gen Z Targeting** | ❌ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ |

**Legend:** ✅ = Has feature, ❌ = Doesn't have, ⚠️ = Partial/unclear

**Key insights:**
1. **No one combines Quran + blocking well** (Noor Focus exists but unclear execution)
2. **Quran.com has best UX/Quran features** but no blocking
3. **Quranly has best streak/habit system** but no blocking
4. **Opal has best blocking UX** but no Quran component
5. **Surah Focus's niche:** Premium Quran app + premium blocking features

---

## Complexity Rankings

### Quick Wins (1-2 days)

- **Search bar:** Filter surah list by text/number
- **Streak display:** Show current streak on Quran tab
- **Sign in with Apple:** Use AuthenticationServices framework
- **Restore purchases button:** RevenueCat handles this
- **Basic surah list:** Display 114 surahs from API
- **Settings tab:** Profile info, subscription status
- **Onboarding survey:** 4 static screens with state

### Medium Effort (3-5 days)

- **Quran reading view:** Display Arabic + translation verse by verse
- **Audio playback:** Stream audio with AVFoundation
- **App selection UI:** FamilyActivityPicker integration
- **Time limit configuration:** UI for setting minutes per app
- **Session tracking:** Save read/listen sessions to SwiftData
- **Streak logic:** Calculate consecutive days from sessions
- **Paywall UI:** Design and implement subscription screen
- **Listening session setup:** Surah + reciter selection
- **Subscription expiration handling:** Remove shields when expired

### Major Effort (1+ week)

- **Background audio:** Control Center integration, lock screen controls (complex threading)
- **Screen Time API integration:** FamilyControls + DeviceActivity + ManagedSettings (requires device testing)
- **Shield configuration extensions:** Separate app extension for custom blocked screen
- **Daily time limit enforcement:** DeviceActivity monitoring with thresholds
- **Listening session + blocking coordination:** Complex state management (audio + shield + timer)
- **RevenueCat integration:** Product setup, entitlements, webhooks, edge cases
- **App Store submission:** Screenshots, description, privacy labels, review process

---

## App Store Review Implications

### Critical Considerations

1. **FamilyControls Usage**
   - Must provide clear usage description in Info.plist
   - Must follow parental control guidelines
   - Apps using Screen Time API face scrutiny (must be legitimate use case)
   - **Mitigation:** Clear value prop: "Block apps during Quran focus sessions"

2. **Subscription Model**
   - Must offer free trial (we do: 3-7 days)
   - Must have "Restore Purchases" button (we do)
   - Must clearly state subscription terms (we do)
   - Hard paywall is allowed if value is clear upfront (RevenueCat data supports this)

3. **Privacy & Data**
   - RevenueCat SDK requires disclosure (subscription management)
   - Screen Time data stays on-device (privacy-friendly)
   - Sign in with Apple data minimization (email/name only)
   - **Privacy Nutrition Label:** Contact info + Purchases + Usage Data only

4. **Religious Content**
   - Quran content is educational/cultural (not controversial)
   - Many Quran apps approved (Muslim Pro, Quran.com, etc.)
   - **No concerns expected**

5. **Background Audio**
   - Must declare `UIBackgroundModes: audio` in Info.plist
   - Must justify background use (we do: Quran listening)
   - **No concerns expected**

6. **Rejection Risks**
   - **Risk:** App appears to restrict device functionality unfairly
   - **Mitigation:** Users opt-in to blocking, can disable anytime, clear explanation
   - **Risk:** Unclear subscription value
   - **Mitigation:** Clear paywall messaging, free trial lets users test

7. **Guideline Compliance**
   - **Guideline 2.1:** App completeness (all features functional)
   - **Guideline 3.1.1:** In-app purchases (subscription model)
   - **Guideline 5.1.1:** Data collection (minimal data)
   - **Guideline 4.0:** Design (minimum functionality is there)

---

## Gen Z Muslim User Insights

### What Gen Z Muslims Want (from research)

**From "The Digital Muslim" and related studies:**

1. **Accessibility and convenience are major factors**
   - Quran apps must be mobile-first, easy to use anywhere
   - Cross-platform availability is expected (iOS/Android)
   - **Surah Focus:** iOS-only V1 is acceptable, but Android expected in V2

2. **Interactive and engaging content appeals to Gen Z**
   - Gamification (streaks, progress) is effective
   - Modern UI/UX design resonates
   - **Surah Focus:** Streak system + minimalist design aligns

3. **Tahfiz (memorization) tools are popular**
   - Memorization tracking is highly requested
   - Audio repetition features
   - **Surah Focus:** Deferred to V2, but this is a known desire

4. **Social sharing capabilities for da'wah content**
   - Sharing verses, reflections
   - Community challenges
   - **Surah Focus:** Privacy-first V1, social for V2

5. **Modern UI/UX design that resonates with younger users**
   - Clean, minimalist over cluttered
   - Dark mode support
   - Mobile-optimized (not desktop design)
   - **Surah Focus:** Minimalist design is differentiator

### From RevenueCat 2025 Report (Subscription App Data)

**Key stats for Health & Fitness category (similar engagement pattern):**
- **Trial conversion:** Median 39.9%, top 10% reach 68.3%
- **12-month retention:** Yearly plans retain 44-60%
- **ARPU (60-day):** $0.63 median (highest of all categories)
- **Realized LTV (Year 1):** $16.44 median, $31.12 upper quartile

**Implications for Surah Focus:**
- We're in "Health & Fitness" adjacent category (spiritual wellness)
- Should see similar conversion/retention if we execute well
- Yearly plans are key to long-term revenue
- Premium positioning (higher prices) leads to higher LTV

**Monetization best practices from RevenueCat:**
1. **Hard paywalls convert better** than freemium (12.11% vs 2.18%)
2. **80-90% of trials happen on Day 0** → onboarding is critical
3. **Longer trials (17-32 days) convert better** but 3-7 day is acceptable
4. **Yearly plans dominate** Health & Fitness (67% of subscriptions)
5. **Higher prices → higher LTV** (don't underprice)

---

## V1 vs V2+ Feature Roadmap

### V1 MVP Features (February 2026)

**Core Quran:**
- ✅ Read all 114 surahs (Arabic + English translation)
- ✅ Listen to audio (4-5 reciters)
- ✅ Search surahs by name/number
- ✅ Session history (what you read/listened to)

**Core Blocking:**
- ✅ App selection (FamilyActivityPicker)
- ✅ Daily time limits (15 min - 4 hours options)
- ✅ Schedule: "All day" blocking (time range V2)
- ✅ Shield enforcement (custom blocked screen)

**Core Gamification:**
- ✅ Streak tracking (consecutive days of Quran engagement)
- ✅ Streak display on Quran tab

**Core Monetization:**
- ✅ Hard paywall (no free tier)
- ✅ 3-day trial (monthly) / 7-day trial (yearly)
- ✅ Sign in with Apple only
- ✅ Restore purchases

**Core UX:**
- ✅ 4-screen onboarding survey
- ✅ 3-tab navigation (Quran, Blocking, Settings)
- ✅ Listening sessions (block apps during Quran listening)

### V2 Features (Future)

**Quran Enhancements:**
- ⏳ Verse-by-verse audio during reading
- ⏳ Bookmark specific ayahs
- ⏳ Tafsir (commentary)
- ⏳ More translations (Urdu, Turkish, etc.)
- ⏳ Memorization tracking

**Blocking Enhancements:**
- ⏳ Custom time range scheduling (9 AM - 11 PM)
- ⏳ Prayer time blocking
- ⏳ Category blocking (block all "Social" apps)

**Social:**
- ⏳ Community challenges
- ⏳ Social leaderboards
- ⏳ Share verses/reflections

**Platform:**
- ⏳ Google Sign In
- ⏳ Android app
- ⏳ Cloud sync (cross-device data)

**Offline:**
- ⏳ Full offline mode (download audio)
- ⏳ Download manager

**Engagement:**
- ⏳ Push notifications (streak reminders)
- ⏳ Widgets (Today view, Lock Screen)
- ⏳ Advanced analytics (heatmaps, stats)

### Never Build (Anti-Features)

- ❌ Reward system (earn unblock time by reading) - undermines discipline
- ❌ Gamification overkill (points, badges beyond streak) - distracts from Quran
- ❌ Prayer time notifications - not core value prop
- ❌ Qibla compass - not core value prop

---

## Complexity vs. Value Matrix

```
High Value
  │
  │  [Streak Tracking]           [Listening Sessions + Blocking]
  │  Quick Win, High Impact      Major Effort, Core Differentiator
  │
  │  [Quran Reading]             [Daily App Limits]
  │  Medium Effort, Table Stakes Major Effort, Table Stakes
  │
  │  [Search]                    [Background Audio]
  │  Quick Win, Table Stakes     Major Effort, Table Stakes
  │
  │  [Onboarding Survey]         [Schedule Configuration]
  │  Quick Win, Conversion Boost  Medium Effort, Nice-to-Have
  │
  └──────────────────────────────────────────────────────────────►
    Low Complexity          Medium Complexity          High Complexity
```

**Priority quadrants:**

1. **Quick Wins (Low complexity, High value):** Do first
   - Streak tracking
   - Search
   - Onboarding survey

2. **Core Differentiators (High complexity, High value):** Must get right
   - Listening sessions + blocking
   - Daily app limits
   - Background audio

3. **Table Stakes (Medium complexity, Essential):** Need to compete
   - Quran reading
   - Schedule configuration

4. **Nice-to-Have (Low complexity, Medium value):** Do if time permits
   - Advanced settings
   - Session history details

---

## Sources

### Primary (HIGH Confidence)

**Quran App Research:**
- [Muslim Pro Official Features Page](https://muslimpro.com/features) - Verified via webReader (2026-02-03)
- [Quran.com Official Site](https://quran.com/en) - Verified via webReader (2026-02-03)
- [Quranly Official Site](https://quranly.app) - Verified via webReader (2026-02-03)

**Blocking App Research:**
- [Opal App Official Site](https://www.opal.so/) - Verified via webReader (attempted, blocked)
- [WebSearch Results for Opal Features 2025](https://www.opal.so/screentime) - HIGH confidence (multiple sources)
- [Freedom App App Store Listing](https://apps.apple.com/us/app/freedom-block-distractions/id606385677) - MEDIUM confidence (search results)

**Subscription App Data:**
- [RevenueCat State of Subscription Apps 2025](https://www.revenuecat.com/state-of-subscription-apps-2025/) - HIGH confidence (verified via webReader, 263-page report, 75,000 apps, $10B+ tracked revenue)

**Gen Z Muslim Research:**
- ["The Digital Muslim": How Gen Z Uses Technology](https://islamonline.net/en/digital-muslim-gen-z-technology-growth/) - MEDIUM confidence
- [Young Muslim Generation's Digital Platform Preferences](https://systems.enpress-publisher.com/index.php/jipd/article/view/3249) - MEDIUM confidence

### Secondary (MEDIUM Confidence)

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - HIGH confidence (official source)
- [FamilyControls Documentation](https://developer.apple.com/documentation/familycontrols) - HIGH confidence (official source)
- [Apple App Store Rejection Reasons 2025](https://twinr.dev/blogs/apple-app-store-rejection-reasons-2025/) - MEDIUM confidence (third-party analysis)

### Tertiary (LOW Confidence)

- Individual Reddit discussions about Quran apps (unverified)
- WebSearch results for "Freedom app features" (limited verification)
- WebSearch results for "Muslim Pro vs Quran.com" (summary from search, not verified via official sources)

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Quran app table stakes | HIGH | Verified via Muslim Pro, Quran.com, Quranly official sites |
| Blocking app table stakes | HIGH | Verified via Opal site + multiple search results |
| Subscription best practices | HIGH | Verified via RevenueCat 2025 report (75,000 apps data) |
| Gen Z Muslim preferences | MEDIUM | Research articles support, but limited to 2-3 sources |
| App Store implications | HIGH | Official guidelines + RevenueCat data |
| Competitor analysis | HIGH | Direct verification of major competitors |
| Feature complexity | MEDIUM | Estimates based on system design review (not built yet) |

---

## Metadata

**Research date:** February 3, 2026
**Valid until:** March 3, 2026 (30 days for fast-moving app landscape)
**Researcher:** Claude (GSD Research Mode)
**Downstream consumer:** /gsd:define-requirements (for requirements definition phase)

**Next steps based on this research:**
1. Use FEATURES.md to inform requirement prioritization
2. Map V1 features to user stories in /gsd:define-requirements
3. Use complexity rankings to estimate development effort
4. Reference competitor features for UI/UX inspiration
5. Ensure V1 scope aligns with table stakes + core differentiators only
