# PHASE 10: TESTFLIGHT DEPLOYMENT
**Timeline:** Day 15 (Feb 17)  
**Duration:** 1 full day  
**Goal:** Build, upload to TestFlight, internal testing, critical bug fixes

---

## PREREQUISITES

- [ ] Phase 9 complete (App polished and tested)
- [ ] Apple Developer account active
- [ ] App Store Connect access
- [ ] Physical device for final testing
- [ ] 165+ tests passing

---

## PHASE OVERVIEW

This phase gets the app into TestFlight:
1. **Build Preparation**: Version bump, certificates
2. **Archive Creation**: Xcode build for distribution
3. **TestFlight Upload**: Submit to App Store Connect
4. **App Store Connect Setup**: Screenshots, description, metadata
5. **Internal Testing**: Test on multiple devices
6. **Bug Fixes**: Address critical issues

**By end of Phase 10, you will have:**
- ✅ TestFlight build uploaded
- ✅ 6 screenshots added
- ✅ App description written
- ✅ Internal testing completed
- ✅ Critical bugs fixed
- ✅ Ready for App Store submission

---

## TASK 10.1: BUILD PREPARATION (Day 15 Morning - 1 hour)

### Step 1: Version Bump

**Update `Project.swift`:**

```swift
// Change version to 1.0.0
infoPlist: .extendingDefault(with: [
    "CFBundleShortVersionString": "1.0.0",
    "CFBundleVersion": "1",
    // ...
])
```

**Regenerate project:**

```bash
cd ~/Projects/DeenFirst
make clean
make generate
```

### Step 2: Verify Certificates

```bash
# In Xcode:
# 1. Select DeenFirst target
# 2. Signing & Capabilities tab
# 3. Verify Team selected
# 4. Verify "Automatically manage signing" checked
# 5. Check provisioning profile is valid
```

### Step 3: Final Clean Build

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean build
make clean

# Full rebuild
make build

# Run tests one last time
make test
```

---

## TASK 10.2: CREATE ARCHIVE (Day 15 Morning - 1 hour)

### Step 1: Archive in Xcode

```bash
# In Xcode:
# 1. Select "Any iOS Device" (not simulator)
# 2. Product > Archive (Cmd+Shift+B)
# 3. Wait for build to complete (~5-10 minutes)
# 4. Organizer window will open automatically
```

### Step 2: Verify Archive

```
In Organizer:
- App name: DeenFirst
- Version: 1.0.0
- Build: 1
- Date: Today
- Should show green checkmark
```

### Step 3: Validate Archive

```
In Organizer:
1. Select the archive
2. Click "Validate App"
3. Choose your team
4. Accept defaults
5. Wait for validation (~2-3 minutes)
6. Should show "DeenFirst.app passed validation"
```

**Common validation errors:**

- **Missing entitlements:** Check Phase 1 entitlements setup
- **Invalid bundle ID:** Verify matches App Store Connect
- **Missing icons:** Check Assets.xcassets has all icon sizes
- **Invalid provisioning profile:** Regenerate in Xcode

---

## TASK 10.3: UPLOAD TO TESTFLIGHT (Day 15 Morning - 30 min)

### Step 1: Distribute App

```
In Organizer:
1. Click "Distribute App"
2. Select "App Store Connect"
3. Click "Upload"
4. Accept defaults for:
   - Include bitcode: No (deprecated)
   - Upload symbols: Yes
   - Manage version: Automatically
5. Click "Upload"
6. Wait for upload (~5-10 minutes)
7. Should show "Upload Successful"
```

### Step 2: Wait for Processing

```
1. Open https://appstoreconnect.apple.com
2. Go to "My Apps"
3. Select DeenFirst
4. Click "TestFlight" tab
5. Wait for build to process (~10-20 minutes)
6. Status will change from "Processing" to "Ready to Submit"
```

---

## TASK 10.4: APP STORE CONNECT SETUP (Day 15 Afternoon - 2 hours)

### Step 1: Create App Listing (if not exists)

```
1. Go to https://appstoreconnect.apple.com
2. My Apps > "+" > New App
3. Fill in:
   - Platform: iOS
   - Name: Deen First - Muslim Lock
   - Primary Language: English
   - Bundle ID: com.aydev.deenfirst
   - SKU: deenfirst001
4. Click "Create"
```

### Step 2: Add Screenshots

**Required: 6.7" iPhone (iPhone 15 Pro Max)**

**Take screenshots on device:**

1. **Onboarding Screen:**
   - Launch app, go to onboarding
   - Cmd+S to save screenshot
   - Save as `1-onboarding.png`

2. **Quran List:**
   - Navigate to Quran tab
   - Show streak badge visible
   - Save as `2-quran-list.png`

3. **Surah Reading:**
   - Open Al-Fatihah
   - Show Arabic + translation
   - Save as `3-surah-reading.png`

4. **Listen Session:**
   - Navigate to Listen tab
   - Show active session with timer
   - Save as `4-listen-session.png`

5. **Blocking Tab:**
   - Show list of blocked apps
   - Save as `5-blocking.png`

6. **Settings:**
   - Show profile with streak
   - Save as `6-settings.png`

**Upload to App Store Connect:**

```
1. App Store Connect > App Store tab
2. Scroll to "App Preview and Screenshots"
3. 6.7" Display
4. Drag & drop all 6 screenshots
5. Arrange in order 1-6
```

### Step 3: Write App Description

**File: `APP_STORE_DESCRIPTION.md`** (for reference)

```markdown
# App Name
Deen First - Muslim Lock

# Subtitle (30 chars max)
Block Apps, Build Quran Habits

# Description (4000 chars max)
Deen First helps you build a daily Quran habit by temporarily blocking distracting apps during your reading and listening sessions.

**FEATURES:**
• Read all 114 surahs with English translations
• Listen to beautiful Quran recitations
• Block apps during your Quran time
• Track your daily streak
• Customizable daily time limits

**BUILD BETTER HABITS:**
Replace mindless scrolling with meaningful Quran engagement. Set daily limits for social media and use that time to strengthen your connection with the Quran.

**SCREEN TIME INTEGRATION:**
Deen First uses Apple's Screen Time API to temporarily block apps you choose during your Quran sessions. You're always in control - shields are only active during your listening or reading time.

**TRACK YOUR PROGRESS:**
Build consistency with our streak system. Complete a session each day to maintain your streak. Every engagement counts - start reading or listening and you're building your streak. Watch as your dedication grows day by day.

**BEAUTIFUL RECITATIONS:**
Listen to renowned Quran reciters including:
• Mishary Alafasy
• Abdul Rahman Al-Sudais
• Abdul Basit
• Sa'ad Al-Ghamidi

**PRIVACY FIRST:**
• Sign in with Apple for maximum privacy
• All data stored securely
• No tracking or selling of personal information
• You control which apps to block

**SUBSCRIPTION:**
Premium features require a subscription:
• Monthly: $4.99
• Annual: $29.99 (save 50%)
• 7-day free trial included

Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in your Apple ID settings.

Privacy Policy: https://aydev.com/privacy
Terms of Service: https://aydev.com/terms

Start your Quran journey today. Build the habit, block the distractions.
```

**Enter in App Store Connect:**

```
1. App Information section
2. Paste description
3. Add promotional text (optional, 170 chars):
   "Build a daily Quran habit. Block distracting apps, track your streak, and connect with the Quran. Start your 7-day free trial today."
4. Add keywords (100 chars max):
   "quran,muslim,islam,prayer,focus,productivity,habits,screen time,blocking,streak"
5. Support URL: https://aydev.com/support
6. Marketing URL: https://aydev.com
```

### Step 4: Add App Information

```
Category:
- Primary: Lifestyle
- Secondary: Reference

Age Rating:
- 4+ (No objectionable content)

Privacy Policy URL:
- https://aydev.com/privacy

Terms of Service URL (optional):
- https://aydev.com/terms
```

### Step 5: App Review Information

```
Contact Information:
- First Name: [Your name]
- Last Name: [Your name]
- Phone: [Your phone]
- Email: [Your email]

Notes for Reviewer:
"Deen First uses Screen Time API to help users block distracting apps during their Quran reading and listening sessions. The app requires authorization through FamilyControls framework. Shields are only applied when the user actively starts a session and are automatically removed when the session ends. Test credentials are not required as sign in uses Apple's authentication."

Demo Account:
- Not required (uses Sign in with Apple)
```

---

## TASK 10.5: INTERNAL TESTING (Day 15 Afternoon - 2 hours)

### Step 1: Add Testers

```
1. TestFlight tab in App Store Connect
2. "Internal Testing" section
3. Click "+" to add testers
4. Add your email and 1-2 team members
5. Click "Add"
```

### Step 2: Create Test Plan

**Document: `TESTFLIGHT_TEST_PLAN.md`**

```markdown
# TestFlight Testing Plan

## Devices to Test
- [ ] iPhone 15 Pro (iOS 17.x)
- [ ] iPhone 14 (iOS 17.x)
- [ ] iPhone SE (iOS 17.x)

## Critical Path Tests

### Authentication
- [ ] Sign in with Apple works
- [ ] User data persists after sign in
- [ ] Can sign out successfully

### Onboarding
- [ ] Survey flow completes
- [ ] Screen Time permission requested
- [ ] FamilyActivityPicker opens
- [ ] Can select apps
- [ ] Time limits can be set
- [ ] Proceeds to main app

### Paywall
- [ ] Subscription options display
- [ ] Can start free trial
- [ ] Purchase flow works
- [ ] Restore purchases works

### Quran Reading
- [ ] All 114 surahs load
- [ ] Search works
- [ ] Can read surah with translation
- [ ] Scroll performance smooth
- [ ] Streak badge displays

### Listening Sessions
- [ ] Can select surahs
- [ ] Can select reciter
- [ ] Audio plays in background
- [ ] Lock screen controls work
- [ ] Session duration tracked
- [ ] Streak updates after valid session
- [ ] Shields apply during session
- [ ] Shields remove after session

### Blocking Management
- [ ] Blocked apps list displays
- [ ] Can edit time limits
- [ ] Can remove apps
- [ ] Can add more apps

### Settings
- [ ] Profile displays correctly
- [ ] Subscription status shows
- [ ] Can view session history
- [ ] Sign out works

## Edge Cases
- [ ] Multiple sessions same day
- [ ] Invalid session (<2 min)
- [ ] Missed days reset streak
- [ ] Airplane mode handled gracefully
- [ ] Low battery doesn't stop audio

## Bugs Found
| Priority | Description | Steps to Reproduce | Status |
|----------|-------------|-------------------|--------|
|          |             |                   |        |
```

### Step 3: Execute Tests

```
1. Install TestFlight app on device
2. Accept invitation email
3. Install Deen First from TestFlight
4. Work through test plan
5. Document any bugs found
6. Rate severity: Critical / High / Medium / Low
```

---

## TASK 10.6: BUG FIXES (Day 15 Evening - 2 hours)

### Fix Critical Bugs Only

**Critical = App doesn't work at all**

Examples:
- App crashes on launch
- Can't sign in
- Audio doesn't play
- Shields don't apply

**For each critical bug:**

1. Reproduce locally
2. Fix the bug
3. Write test to prevent regression
4. Rebuild and retest
5. If all critical bugs fixed, create new build

**If new build needed:**

```bash
# Bump build number
# In Project.swift: "CFBundleVersion": "2"

make clean
make generate
make test

# Archive again (Product > Archive)
# Upload to TestFlight
# Wait for processing
# Retest
```

**Non-critical bugs:**
- Document for post-launch fixes
- Don't delay submission for minor issues

---

## PHASE 10 COMPLETION CHECKLIST

### Build & Upload
- [ ] Version set to 1.0.0
- [ ] Build number set to 1
- [ ] Archive created successfully
- [ ] Archive validated successfully
- [ ] Uploaded to TestFlight
- [ ] Build processed by Apple
- [ ] Build shows as "Ready to Test"

### App Store Connect
- [ ] App listing created
- [ ] 6 screenshots uploaded
- [ ] Description written and entered
- [ ] Keywords added
- [ ] Categories selected
- [ ] Age rating set
- [ ] Privacy Policy URL added
- [ ] Support URL added
- [ ] App Review information filled

### Testing
- [ ] Internal testers added
- [ ] Test plan created
- [ ] Tests executed on 2+ devices
- [ ] Critical bugs documented
- [ ] Critical bugs fixed (if any)
- [ ] Non-critical bugs documented for later

### Ready for Submission
- [ ] All critical tests passing
- [ ] No critical bugs remaining
- [ ] App performs well on test devices
- [ ] Screenshots look professional
- [ ] Description is compelling

---

## TROUBLESHOOTING

### Issue: Archive validation fails
**Solution:**
- Check all targets have same version/build
- Verify entitlements correct
- Check bundle ID matches App Store Connect
- Ensure all required icons present

### Issue: Upload stuck at "Processing"
**Solution:**
- Wait up to 30 minutes
- Check email for errors from Apple
- If timeout, try uploading again

### Issue: TestFlight build not appearing
**Solution:**
- Wait up to 60 minutes for processing
- Check App Store Connect for errors
- Verify build passed compliance checks

### Issue: Critical bug found in TestFlight
**Solution:**
- Fix bug
- Increment build number
- Create new archive
- Upload and retest

---

## NEXT PHASE PREVIEW

**Phase 11: App Store Submission**
- Final review of all materials
- Submit for App Store review
- Respond to reviewer questions
- Monitor review status
- Launch! 🚀

---

**🎯 PHASE 10 COMPLETE!**

```bash
git add .
git commit -m "✅ Phase 10: TestFlight build uploaded v1.0.0"
git push
```
