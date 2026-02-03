# Pitfalls Research: Surah Focus

**Researched:** 2026-02-03
**Project:** Surah Focus - iOS Quran + Screen Time Management
**Timeline:** 16-day sprint to App Store (Feb 18, 2026)
**Confidence:** MEDIUM

## Summary

This research identifies critical pitfalls for Quran apps and app-blocking projects, with special focus on App Store rejection risks. Key findings: Screen Time API requires special entitlement approval, RevenueCat sandbox issues cause rejections, Quran content accuracy is critical, and subscription apps face specific guidelines.

## Critical App Store Rejection Risks

### 1. FamilyControls Entitlement Not Requested
- **Risk Level:** CRITICAL
- **What Happens:** App Store auto-rejects apps using FamilyControls without pre-approved entitlement
- **Warning Signs:** Build compiles but TestFlight/App Store submission fails with entitlement error
- **Prevention:**
  - Request `com.apple.developer.family-controls` entitlement via [Apple Developer Portal](https://developer.apple.com/contact/request/) BEFORE submission
  - Timeline: Can take 1-2 weeks for approval
  - Test in sandbox environment while waiting
  - **Immediate action required:** Submit entitlement request Day 1
- **Phase to Address:** Phase 1 (Infrastructure)
- **App Store Guideline:** Using private/restricted APIs without approval

### 2. RevenueCat Sandbox Rejection
- **Risk Level:** HIGH
- **What Happens:** App Store reviewers encounter "There was a problem with the App Store sandbox" error and cannot complete purchases
- **Warning Signs:**
  - Testing in sandbox shows intermittent failures
  - RevenueCat returns `STORE_PROBLEM` errors
- **Prevention:**
  - Test thoroughly in sandbox with multiple tester accounts
  - Ensure products are configured correctly in RevenueCat dashboard
  - Provide test account credentials in review notes
  - Add fallback: "Restore Purchases" prominently displayed
  - Test on fresh device (not development environment)
- **Phase to Address:** Phase 2 (Auth + Onboarding)
- **App Store Guideline:** [Guideline 2.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements) - App Completeness
- **Sources:**
  - [RevenueCat App Store Rejections Documentation](https://www.revenuecat.com/docs/test-and-launch/app-store-rejections) (HIGH confidence)
  - [RevenueCat Community - Multiple rejections Nov 2025](https://community.revenuecat.com/general-questions-7/multiple-ios-app-store-rejection-due-to-revenue-cat-purchase-failure-there-was-a-problem-with-the-apple-store-7175) (MEDIUM confidence)

### 3. No Free Tier + Subscription-Only Model
- **Risk Level:** HIGH
- **What Happens:** App Store may reject apps that offer no free functionality and require payment immediately
- **Warning Signs:** Similar apps mention rejections for "paywall on launch"
- **Prevention:**
  - Offer free trial (3-day monthly, 7-day yearly) as specified
  - Ensure free trial is clearly communicated
  - Don't require subscription BEFORE user sees value
  - Consider: Allow Quran reading without subscription (future pivot if rejected)
  - **Current spec:** Paywall AFTER onboarding survey, NOT before auth
- **Phase to Address:** Phase 2 (Auth + Onboarding)
- **App Store Guideline:** [Guideline 3.1.1](https://developer.apple.com/app-store/review/guidelines/#payments) - In-App Purchase

### 4. Religious Content Accuracy Issues
- **Risk Level:** HIGH
- **What Happens:** Users report textual errors in Quranic verses → 1-star reviews → App Store attention
- **Warning Signs:**
  - User reviews mentioning "errors in ayat"
  - Missing letters in Arabic text
  - Islamic bodies issue warnings about app
- **Prevention:**
  - Use reputable Quran API (QuranAPI.pages.dev is established)
  - Consider adding verification mechanism (cross-reference with another API)
  - Add disclaimer: "Please report any content errors"
  - Have native Arabic speaker verify critical surahs
  - Monitor reviews closely post-launch
- **Phase to Address:** Phase 4 (Quran Reading)
- **App Store Guideline:** [Guideline 2.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements) - Accurate functionality
- **Sources:**
  - [Reddit discussion on Quran app errors](https://www.reddit.com/r/iOSProgramming/comments/1jtojjk/) (LOW confidence, needs verification)
  - [Quran API accuracy research](https://www.researchgate.net/publication/) (MEDIUM confidence)

### 5. Background Audio Not Working
- **Risk Level:** MEDIUM
- **What Happens:** Users expect Quran audio to continue when phone locks; if it stops, negative reviews
- **Warning Signs:** Audio stops when app backgrounds
- **Prevention:**
  - Add `UIBackgroundModes` → `audio` to Info.plist (REQUIRED)
  - Configure `AVAudioSession` category to `.playback`
  - Test extensively on physical device
  - Handle interruptions (calls, other apps) properly
  - Implement `MPNowPlayingInfoCenter` for lock screen controls
- **Phase to Address:** Phase 5 (Listening Sessions)
- **App Store Guideline:** [Guideline 2.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements) - Background functionality
- **Sources:**
  - [iOS background audio issues StackOverflow](https://stackoverflow.com/questions/79765569) (MEDIUM confidence)
  - [AVFoundation background audio guide](https://uiswift.com/enable-background-audio-playback/) (HIGH confidence)

### 6. iOS Deployment Target Too High (iOS 26.0)
- **Risk Level:** HIGH
- **What Happens:** Current project uses iOS 26.0 (future version), will fail submission
- **Warning Signs:** `IPHONEOS_DEPLOYMENT_TARGET = 26.0` in project.pbxproj (Line 181, 239)
- **Prevention:**
  - Change to `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
  - Must match PRD specification (iOS 17+)
  - Update both Debug and Release configurations
- **Phase to Address:** Phase 1 (Infrastructure) - **IMMEDIATE FIX REQUIRED**
- **App Store Guideline:** Technical requirements

### 7. Hardcoded Team ID in Project File
- **Risk Level:** MEDIUM
- **What Happens:** Project file contains `DEVELOPMENT_TEAM = 32T8HNVYGX` (Lines 163, 227, 256, 288) - causes issues for other developers
- **Warning Signs:** Build fails for anyone except original developer
- **Prevention:**
  - Use environment variable or leave blank for Xcode to auto-fill
  - Don't commit hardcoded team IDs
  - Add to .gitignore (currently missing)
- **Phase to Address:** Phase 1 (Infrastructure)
- **App Store Guideline:** N/A (development hygiene)

### 8. Missing .gitignore
- **Risk Level:** MEDIUM
- **What Happens:** Sensitive files (Team ID, RevenueCat API key) could be committed
- **Warning Signs:** No .gitignore in root directory
- **Prevention:**
  - Create standard iOS .gitignore
  - Exclude: .env, DerivedData, *.xcuserdata, RevenueCat configs
  - Add `.env` with RevenueCat API key to gitignore
- **Phase to Address:** Phase 1 (Infrastructure)
- **App Store Guideline:** N/A (security)

## FamilyControls / Screen Time API Pitfalls

### Permission Revocation Vulnerability
- **Issue:** Users can easily revoke Screen Time permissions in Settings, bypassing all blocking
- **Why It Happens:** iOS allows revoking Screen Time permissions even when locked with passcode
- **Detection:** Blocking stops working unexpectedly
- **Prevention:**
  - Check `AuthorizationCenter.shared.authorizationStatus` on app launch
  - Show alert if permission revoked: "Screen Time permission required. Please re-enable in Settings."
  - Deep link to Settings app
  - Don't assume permission persists
- **Phase to Address:** Phase 3 (Screen Time Setup)
- **Sources:**
  - [Screen Time API limitations discussion](https://www.folio3.com/mobile/blog/screentime-api-ios/) (MEDIUM confidence)

### FamilyActivityPicker Doesn't Show Individual Child Apps
- **Issue:** Picker shows all children's apps grouped together, making specific app blocking difficult
- **Why It Happens:** FamilyControls design for parental control, not self-control
- **Detection:** Cannot select specific apps, only categories
- **Prevention:**
  - Use `ApplicationToken` directly for individual apps
  - Don't rely on child-specific features (this is individual use, not parent-child)
  - Test picker on physical device (simulator behavior differs)
- **Phase to Address:** Phase 3 (Screen Time Setup)
- **Sources:**
  - [Family Controls developer guide](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7) (HIGH confidence)

### Shield Configuration Doesn't Apply
- **Issue:** Shield not showing when apps blocked
- **Why It Happens:** App Group identifier mismatch between app and extension
- **Detection:** Apps remain accessible despite "blocking"
- **Prevention:**
  - Verify App Group ID matches: `group.com.aydev.surahfocus` in BOTH entitlements
  - Check extension has `com.apple.developer.family-controls` entitlement
  - Test on physical device (simulator doesn't support Screen Time API)
  - Call `store.shield.applications = applications` with correct token format
- **Phase to Address:** Phase 3 (Screen Time Setup)
- **Sources:**
  - [Apple Developer Forums - Family Controls](https://developer.apple.com/forums/tags/family-controls/) (HIGH confidence)

### DeviceActivity Extension Crashes
- **Issue:** Extension crashes silently, blocking stops working
- **Why It Happens:** Shared UserDefaults access fails, incorrect suite name
- **Detection:** Blocking works initially then stops
- **Prevention:**
  - Use correct suite name: `UserDefaults(suiteName: "group.com.aydev.surahfocus")`
  - Test extension independently with breakpoints
  - Add crash logging to extension
  - Don't force unwrap shared defaults
- **Phase to Address:** Phase 3 (Screen Time Setup)
- **Sources:**
  - [WWDC25: Deliver age-appropriate experiences](https://developer.apple.com/videos/play/wwdc2025/299/) (HIGH confidence)

### Shields Persist After Removal
- **Issue:** Apps stay blocked even after calling removal code
- **Why It Happens:** Known iOS bug, shields cache in system
- **Detection:** User unsubscribes but apps remain blocked
- **Prevention:**
  - Call `store.clearAllSettings()` explicitly (not just `store.shield.applications = nil`)
  - Restart device if shields persist (document this in support)
  - Test removal flow extensively
  - Add "Force Clear Shields" debug option in Settings
- **Phase to Address:** Phase 6 (Blocking + Settings) - **CRITICAL FOR SUBSCRIPTION EXPIRATION**
- **Sources:**
  - [Family Controls configuration guide](https://developer.apple.com/documentation/xcode/configuring-family-controls) (HIGH confidence)

### MonitoringError.intervalTooShort
- **Issue:** DeviceActivity monitoring fails with interval error
- **Why It Happens:** Monitoring interval set too short (must be at least 1-15 minutes depending on iOS version)
- **Detection:** Crashes or errors when starting daily limit monitoring
- **Prevention:**
  - Use minimum 1-hour intervals for daily limits
  - Don't set granular per-minute monitoring
  - Test with longer intervals first
- **Phase to Address:** Phase 6 (Blocking + Settings)
- **Sources:**
  - [Screen Time API common errors](https://medium.com/@jc_builds/building-a-powerful-ios-app-blocker-with-screen-time-apis-the-complete-guide-f6272bd00fc4) (MEDIUM confidence)

## Quran API Integration Pitfalls

### API Downtime = No Quran Access
- **Issue:** QuranAPI.pages.dev goes down, users can't read Quran
- **Why It Happens:** Single source API, no backup (per PRD V1 scope)
- **Detection:** 500 errors, timeouts when fetching surahs
- **Prevention:**
  - Cache surah list indefinitely (static data)
  - Cache surah content for 30 days
  - Show cached data with "Last updated" timestamp
  - Add error message: "Unable to load. Check your connection."
  - **V2 consideration:** Add backup API source
- **Phase to Address:** Phase 4 (Quran Reading)
- **Sources:**
  - [Quran API documentation](https://quranapi.pages.dev/introduction) (HIGH confidence)

### Textual Accuracy Not Verified
- **Issue:** API returns incorrect Quranic text
- **Why It Happens:** No verification mechanism, trusting API blindly
- **Detection:** User complaints about errors
- **Prevention:**
  - Cross-reference with another Quran API for first few surahs
  - Have native Arabic speaker verify Surah Al-Fatihah (most critical)
  - Add "Report Error" button
  - Monitor API changelog for updates
- **Phase to Address:** Phase 4 (Quran Reading)
- **Sources:**
  - [Quran transcription API research](https://github.com/sayedmahmoud266/quran-ai-transcriping) (LOW confidence)

### Audio URL 404s
- **Issue:** Audio URLs from API return 404
- **Why It Happens:** Reciter ID changed, CDN moved, or URL format changed
- **Detection:** Audio fails to play
- **Prevention:**
  - Handle audio fetch errors gracefully
  - Show error: "Audio unavailable. Try another reciter."
  - Don't crash if audio URL is invalid
  - Test all 5 reciters before submission
- **Phase to Address:** Phase 5 (Listening Sessions)
- **Sources:**
  - [Quran API audio endpoints](https://quranapi.pages.dev/api) (HIGH confidence)

### Cache Expiry Not Implemented
- **Issue:** Surah content cached forever, showing stale data
- **Why It Happens:** No expiry timestamp on cached surahs
- **Detection:** App shows old data even after API updates
- **Prevention:**
  - Add `cachedAt` timestamp to surah cache
  - Implement 30-day expiry check
  - Show "Cached from [date]" indicator
- **Phase to Address:** Phase 4 (Quran Reading)
- **Sources:**
  - PRD Section 4.2 - Caching Strategy (HIGH confidence)

## Background Audio Pitfalls

### Audio Stops When App Backgrounds
- **Issue:** Quran audio cuts off when user locks phone or switches apps
- **Why It Happens:** `UIBackgroundModes` not configured or `AVAudioSession` wrong category
- **Detection:** Audio plays in app only, stops when backgrounded
- **Prevention:**
  - Add to Info.plist: `UIBackgroundModes` → `audio`
  - Configure session: `try audioSession.setCategory(.playback, mode: .default)`
  - Activate session: `try audioSession.setActive(true)`
  - Test on physical device (simulator behavior differs)
- **Phase to Address:** Phase 5 (Listening Sessions)
- **Sources:**
  - [AVFoundation background audio setup](https://uiswift.com/enable-background-audio-playback/) (HIGH confidence)

### Lock Screen Controls Don't Show
- **Issue:** Users can't control audio from lock screen
- **Why It Happens:** `MPNowPlayingInfoCenter` not configured
- **Detection:** Lock screen shows default audio controls, not Quran info
- **Prevention:**
  - Import `MediaPlayer` framework
  - Set `nowPlayingInfo` with title, artist, duration
  - Update info when surah changes
  - Handle remote control events
- **Phase to Address:** Phase 5 (Listening Sessions)
- **Sources:**
  - [Background audio best practices](https://developer.apple.com/documentation/avfoundation/audio_session_management) (HIGH confidence)

### Audio Interruptions Not Handled
- **Issue:** Phone call or other audio app stops Quran audio permanently
- **Why It Happens:** Not observing `AVAudioSession.interruptionNotification`
- **Detection:** Audio doesn't resume after interruption
- **Prevention:**
  - Observe interruption notification
  - Pause audio on interruption begin
  - Resume on interruption end (if user was listening)
  - Show "Tap to resume" UI if can't auto-resume
- **Phase to Address:** Phase 5 (Listening Sessions)
- **Sources:**
  - [AVAudioSession interruption handling](https://developer.apple.com/documentation/avfoundation/avaudiosession) (HIGH confidence)

### Audio Playback Ends Abruptly
- **Issue:** No smooth transition between surahs
- **Why It Happens:** Not observing `.AVPlayerItemDidPlayToEndTime`
- **Detection:** Audio stops, doesn't continue to next surah
- **Prevention:**
  - Observe `AVPlayerItemDidPlayToEndTime` notification
  - Load next surah in queue before current finishes
  - Implement gapless playback (preload next surah)
  - Update UI to show "Playing next surah..."
- **Phase to Address:** Phase 5 (Listening Sessions)
- **Sources:**
  - PRD Section 6.7.3 - Active Session Screen (HIGH confidence)

## RevenueCat / Subscription Pitfalls

### Subscription Check Fails Silently
- **Issue:** Network timeout, RevenueCat down, or user offline → app unusable
- **Why It Happens:** No offline handling, assumes network always available
- **Detection:** App shows paywall even though user has active subscription
- **Prevention:**
  - Cache subscription status locally in SwiftData
  - Allow offline access if last check was < 24 hours ago
  - Show "Checking subscription..." loading state
  - Don't block Quran reading during subscription check
- **Phase to Address:** Phase 2 (Auth + Onboarding)
- **Sources:**
  - [RevenueCat subscription best practices](https://www.revenuecat.com/docs/entitlements) (HIGH confidence)

### Subscription Expiration Not Handled Mid-Session
- **Issue:** User's subscription expires while listening to Quran
- **Why It Happens:** No real-time expiration check during active session
- **Detection:** Session ends but shields not removed
- **Prevention:**
  - Check subscription status when session ends (not mid-session)
  - Remove all shields if expired
  - Show paywall with "Your subscription has expired"
  - Don't interrupt active Quran session (respect user engagement)
- **Phase to Address:** Phase 6 (Blocking + Settings)
- **Sources:**
  - PRD Section 6.7.4 - End Session (HIGH confidence)

### Restore Purchases Shows Wrong Status
- **Issue:** User reinstalls app, restores purchases, shows "no subscription found"
- **Why It Happens:** RevenueCat receipt not linked to Apple ID correctly
- **Detection:** Fresh install shows paywall despite active subscription
- **Prevention:**
  - Test restore flow with sandbox account
  - Link RevenueCat `appUserID` to Apple User ID
  - Show detailed error message on restore failure
  - Provide "Contact Support" with restore logs
- **Phase to Address:** Phase 2 (Auth + Onboarding)
- **Sources:**
  - [RevenueCat restore purchases](https://www.revenuecat.com/docs/customer-info) (HIGH confidence)

### Free Trial Not Communicated Clearly
- **Issue:** Users think they're charged immediately
- **Why It Happens:** Paywall doesn't emphasize "FREE TRIAL"
- **Detection:** Reviews complaining about "scam" or "charged immediately"
- **Prevention:**
  - Button text: "Start 7-DAY FREE TRIAL" (not "Subscribe")
  - Subtitle: "Cancel anytime, no charge until [date]"
  - Show trial end date prominently
  - Send reminder 1 day before trial ends (V2 feature)
- **Phase to Address:** Phase 2 (Auth + Onboarding)
- **Sources:**
  - [App Store subscription best practices](https://developer.apple.com/app-store/review/guidelines/#payments) (HIGH confidence)

## SwiftData Pitfalls

### Migration Crashes on Schema Changes
- **Issue:** Adding new property to SwiftData model crashes app for existing users
- **Why It Happens:** SwiftData schema changed without migration plan
- **Detection:** Crash on app launch after update
- **Prevention:**
  - Use `VersionedSchema` from day one (don't use default schema)
  - Create migration plan for every schema change
  - Test migration: install old version, add data, upgrade to new version
  - Don't make changes between TestFlight and submission
- **Phase to Address:** Phase 1 (Infrastructure)
- **Sources:**
  - [SwiftData migration crashes](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/) (HIGH confidence)
  - [Never use SwiftData without VersionedSchema](https://mertbulan.com/programming/never-use-swiftdata-without-versionedschema) (HIGH confidence)
  - [SwiftData iOS 26 migration issues](https://dev.to/arshtechpro/wwdc-2025-swiftdata-ios-26-class-inheritance-migration-issues-30bh) (MEDIUM confidence)

### @Relationship Cascade Deletes Too Much
- **Issue:** Deleting user deletes all their sessions, blocks, limits (desired, but can be unintended)
- **Why It Happens:** `@Relationship(deleteRule: .cascade)` is aggressive
- **Detection:** Data disappears unexpectedly
- **Prevention:**
  - Consider `.nullify` for some relationships
  - Test delete flows thoroughly
  - Archive data instead of hard delete if needed (V2)
- **Phase to Address:** Phase 1 (Infrastructure)
- **Sources:**
  - PRD Section 7.1 - SwiftData Entities (HIGH confidence)

### SwiftData Previews Crashes
- **Issue:** Xcode Previews crash when using SwiftData
- **Why It Happens:** SwiftData container not configured for preview environment
- **Detection:** Can't see SwiftUI previews
- **Prevention:**
  - Use in-memory container for previews
  - Create preview-specific ModelContainer
  - Don't use `@Model` in preview-specific code
- **Phase to Address:** Phase 1 (Infrastructure)
- **Sources:**
  - [SwiftData + Xcode Previews issues](https://www.linkedin.com/pulse/swiftdata-xcode-previews-why-every-migration-feels-anton-pavlov-fqwle) (MEDIUM confidence)

## Common Quran App Mistakes

### Complex Navigation = User Abandonment
- **Issue:** Users can't find reading feature, quit app
- **Why Users Hate It:** "Where's the Quran?" "Too complicated"
- **How to Avoid:**
  - Quran tab should be default (selected) tab on launch
  - Reading should be 1 tap from home screen
  - Don't bury reading behind multiple screens
  - Search bar prominently displayed
- **Phase to Address:** Phase 4 (Quran Reading)
- **Sources:**
  - [Quran app UX issues](https://www.reddit.com/r/iOSProgramming/) (LOW confidence)

### No Streak = No Retention
- **Issue:** Users have no reason to come back daily
- **Why Users Hate It:** "I forget to use it" "No motivation"
- **How to Avoid:**
  - Implement streak tracking (already in PRD)
  - Show streak prominently on Quran tab
  - Celebrate milestones (7 days, 30 days)
  - Don't break streak for missing 1 day (grace period?)
- **Phase to Address:** Phase 7 (Streak + Integration)
- **Sources:**
  - PRD Section 6.10 - Streak Tracking (HIGH confidence)

### Translations Hard to Read
- **Issue:** English translation too small, wrong font, poor contrast
- **Why Users Hate It:** "Can't read translation" "Text overlaps"
- **How to Avoid:**
  - Use readable font size (17pt minimum)
  - Proper line spacing (1.5x)
  - High contrast (dark gray on white, not light gray)
  - Test on iPhone SE (small screen)
- **Phase to Address:** Phase 8 (Polish)
- **Sources:**
  - iOS accessibility guidelines (HIGH confidence)

### No Offline Reading Capability
- **Issue:** App requires internet for Quran reading (not audio, just text)
- **Why Users Hate It:** "Can't read Quran on airplane" "What if no WiFi?"
- **How to Avoid:**
  - Implement text caching (already in PRD)
  - Cache surah list indefinitely
  - Cache individual surahs for 30 days
  - Show "Offline mode: Last updated [date]" indicator
- **Phase to Address:** Phase 4 (Quran Reading)
- **Sources:**
  - PRD Section 4.2 - Caching Strategy (HIGH confidence)

## Timeline Pitfalls (16-Day Sprint)

### Underestimating Screen Time API Complexity
- **Risk:** Screen Time features take 3x longer than expected
- **Mitigation:**
  - Allocate full 2 days for Screen Time (Phase 3)
  - Test on physical device early (Day 4)
  - Have backup plan: Use simple blocking (no daily limits) if complex blocking fails
  - Known issue: Simulator doesn't support Screen Time API
- **Phase to Address:** Phase 3 (Screen Time Setup)
- **Sources:**
  - [Screen Time API tutorial](https://medium.com/@jc_builds/building-a-powerful-ios-app-blocker-with-screen-time-apis-the-complete-guide-f6272bd00fc4) (MEDIUM confidence)

### FamilyControls Entitlement Approval Delay
- **Risk:** Entitlement takes 2+ weeks, blocking submission
- **Mitigation:**
  - Submit entitlement request IMMEDIATELY (Day 1)
  - Continue development while waiting
  - Can test in sandbox without approval
  - If not approved by Day 14, appeal to Apple Developer Relations
- **Phase to Address:** Phase 1 (Infrastructure)
- **Sources:**
  - [Reddit entitlement request timeline](https://www.reddit.com/r/iOSProgramming/comments/1jvuyy8/how_long_does_it_take_to_get_entitlement/) (MEDIUM confidence)

### No Buffer Days Before Submission
- **Risk:** Unexpected bug on Day 16, no time to fix
- **Mitigation:**
  - Built-in buffer: Days 14-15 for final polish
  - Actually submit on Day 16, not earlier
  - If delayed, have Day 17-18 as emergency buffer
  - Target submission: Feb 16 (earlier than Feb 18 deadline)
- **Phase to Address:** All phases (timeline discipline)
- **Sources:**
  - PRD Section 10.1 - Timeline (HIGH confidence)

### TestFlight Testing Too Late
- **Risk:** Major bug found by testers on Day 15, no time to fix
- **Mitigation:**
  - Upload to TestFlight Day 13 (not Day 15)
  - Have 5-10 internal testers ready
  - Test critical paths: auth, purchase, blocking, audio
  - Fix blockers Days 13-14, buffer Days 15-16
- **Phase to Address:** Phase 9 (TestFlight)
- **Sources:**
  - PRD Section 10.1 - Timeline (HIGH confidence)

### Scope Creep Under Time Pressure
- **Risk:** "Let's just add this one feature" → timeline blown
- **Mitigation:**
  - Ruthless scope adherence (PRD V1 scope only)
  - Any new feature → V1.1 (post-launch)
  - Daily standup: "Are we on track for Feb 18?"
  - Cut features if behind (e.g., no custom time ranges, just "all day")
- **Phase to Address:** All phases (discipline)
- **Sources:**
  - PRD Section 2.2 - Out of Scope (HIGH confidence)

## Red Flags to Watch For

**During Development:**
- [ ] **Build time > 5 minutes** → Clean build folder, check dependencies
- [ ] **Simulator crashes frequently** → Test on physical device ASAP
- [ ] **Screen Time features don't work on simulator** → EXPECTED (test on device)
- [ ] **RevenueCat errors in console** → Check API key, product IDs
- [ ] **SwiftData preview crashes** → Use in-memory container for previews
- [ ] **Git repo not initialized** → Initialize immediately, protect work
- [ ] **Team ID hardcoded** → Remove from project file, add to .gitignore
- [ ] **iOS 26.0 deployment target** → CHANGE TO 17.0 IMMEDIATELY
- [ ] **FamilyControls entitlement not requested** → SUBMIT REQUEST DAY 1

**Before App Store Submit:**
- [ ] **TestFlight not tested by external users** → Upload 2-3 days early, get feedback
- [ ] **Privacy Policy URL missing** → Create and host (can be simple page)
- [ ] **Terms of Service missing** → Create and host (can be simple page)
- [ ] **App Store screenshots not ready** → Prepare 6 screenshots (6.7" iPhone)
- [ ] **App Store description not written** → Write and review (see PRD Section 11.1)
- [ ] **Sandbox testing not done** → Test purchase flow with sandbox account
- [ ] **Background audio not tested on physical device** → CRITICAL TEST
- [ ] **Screen Time shield not tested on physical device** → CRITICAL TEST
- [ ] **Subscription expiration not tested** → Test with trial, advance date, verify shields removed
- [ ] **Quran content not verified** → Have Arabic speaker check Surah Al-Fatihah
- [ ] **RevenueCat API key in source code** → Move to .env file
- [ ] **No crash reporting configured** → Consider adding Firebase Crashlytics (optional)

**Common Rejection Reasons (from similar apps):**
- [ ] **Guideline 2.1** - App incomplete or crashes
- [ ] **Guideline 2.3** - Performance issues (slow, unresponsive)
- [ ] **Guideline 3.1** - Payments not working (sandbox issues)
- [ ] **Guideline 3.2** - Services not delivered (subscription gives nothing)
- [ ] **Guideline 5.1.1** - Data collection without Privacy Policy
- [ ] **Entitlement rejection** - Using FamilyControls without approval

## Sources

### Primary (HIGH confidence)
- [RevenueCat Official Documentation - App Store Rejections](https://www.revenuecat.com/docs/test-and-launch/app-store-rejections)
- [Apple Developer Documentation - FamilyControls](https://developer.apple.com/documentation/familycontrols)
- [Apple Developer Documentation - Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [WWDC25: Deliver age-appropriate experiences in your app](https://developer.apple.com/videos/play/wwdc2025/299/)
- [QuranAPI.pages.dev Documentation](https://quranapi.pages.dev/introduction)
- [AVFoundation Background Audio Guide](https://uiswift.com/enable-background-audio-playback/)
- [SwiftData Migration Guide](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/)
- [Never use SwiftData without VersionedSchema](https://mertbulan.com/programming/never-use-swiftdata-without-versionedschema)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- PRD v3.0 (Internal - HIGH confidence)
- System Design v3.0 (Internal - HIGH confidence)

### Secondary (MEDIUM confidence)
- [A Developer's Guide to Apple's Screen Time APIs](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7)
- [Building a Powerful iOS App Blocker with Screen Time APIs](https://medium.com/@jc_builds/building-a-powerful-ios-app-blocker-with-screen-time-apis-the-complete-guide-f6272bd00fc4)
- [RevenueCat Community - App Store Rejections Nov 2025](https://community.revenuecat.com/general-questions-7/multiple-ios-app-store-rejection-due-to-revenue-cat-purchase-failure-there-was-a-problem-with-the-apple-store-7175)
- [SwiftData iOS 26 - Class Inheritance & Migration Issues](https://dev.to/arshtechpro/wwdc-2025-swiftdata-ios-26-class-inheritance-migration-issues-30bh)
- [WorkOS: Apple App Store Authentication Requirements (August 2025)](https://workos.com/blog/apple-app-store-authentication-sign-in-with-apple-2025)
- [Screen Time API iOS Tutorial](https://www.folio3.com/mobile/blog/screentime-api-ios/)
- [Apple Developer Forums - Family Controls](https://developer.apple.com/forums/tags/family-controls/)
- [Reddit: FamilyControls App Blocking Fails for External Testers](https://www.reddit.com/r/iOSProgramming/comments/1kr0u1h/familycontrols_app_blocking_fails_for_external/)

### Tertiary (LOW confidence - needs verification)
- [Reddit discussion on Quran app errors](https://www.reddit.com/r/iOSProgramming/comments/1jtojjk/)
- [Stack Overflow - iOS app not playing audio from background](https://stackoverflow.com/questions/79765569)
- [Quran AI Transcription API](https://github.com/sayedmahmoud266/quran-ai-transcriping)
- [Intelligent Quran Recitation Recognition Research](https://www.researchgate.net/publication/)
- [Reddit: How long does entitlement request take?](https://www.reddit.com/r/iOSProgramming/comments/1jvuyy8/)

## Metadata

**Confidence breakdown:**
- Critical App Store Rejection Risks: HIGH - Based on official Apple docs, RevenueCat docs
- FamilyControls / Screen Time API Pitfalls: HIGH/MEDIUM - Apple docs + developer community
- Quran API Integration Pitfalls: MEDIUM - API docs + common issues
- Background Audio Pitfalls: HIGH - Official AVFoundation docs
- RevenueCat / Subscription Pitfalls: HIGH - RevenueCat official docs
- SwiftData Pitfalls: HIGH - Recent WWDC content + developer blogs
- Common Quran App Mistakes: LOW/MEDIUM - Community discussions, user reviews
- Timeline Pitfalls: HIGH - Internal project plan + known risks

**Research date:** 2026-02-03
**Valid until:** 2026-03-03 (30 days - Screen Time API and App Store guidelines can change)

## Key Takeaways for Development

1. **IMMEDIATE ACTIONS (Day 1):**
   - Submit FamilyControls entitlement request
   - Change iOS deployment target from 26.0 to 17.0
   - Create .gitignore
   - Remove hardcoded Team ID
   - Initialize git repo

2. **CRITICAL TESTS (Before Submission):**
   - RevenueCat sandbox purchase flow (multiple tester accounts)
   - Background audio on physical device (locked screen)
   - Screen Time shield on physical device (not simulator)
   - Subscription expiration → shield removal
   - Quran content accuracy (native speaker verification)

3. **MOST COMMON REJECTION CAUSES:**
   - Missing FamilyControls entitlement approval
   - RevenueCat sandbox errors during review
   - App crashes or incomplete functionality
   - Missing Privacy Policy/Terms
   - Guideline violations (religious content accuracy)

4. **HIGHEST RISK FEATURES:**
   - Screen Time API (entitlement, simulator doesn't work)
   - Subscription/RevenueCat (sandbox issues, expiration handling)
   - Background audio (Info.plist configuration, session handling)
   - Quran content (accuracy, API reliability)

---

**END OF PITFALLS RESEARCH**
