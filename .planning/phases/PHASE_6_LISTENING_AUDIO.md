# PHASE 6: LISTENING SESSIONS + AUDIO PLAYER
**Timeline:** Days 10-11 (Feb 12-13)
**Duration:** 2 full days
**Goal:** Complete audio playback system with background support, ayah-by-ayah session tracking, and shield application during listening

---

## PREREQUISITES

- Phase 5 complete (Main tabs functional, Quran API working)
- Physical iOS 17+ device ready (Screen Time features require real device)
- Background audio capability enabled in Xcode

---

## PHASE OVERVIEW

This phase builds the complete listening experience with multiple screens:

**User Flow:**
1. Home (Quran Tab) → FAB "Start Focus Session"
2. Focus Section Page (blocked apps + surah list + Add button)
3. Select Surah Page (multi-select from 114 surahs with search)
4. Back to Focus Section (surahs displayed)
5. For each surah: Select start/end ayah range
6. Tap "Start Session" → Download all ayahs with progress
7. Active Session View (ayah-by-ayah playback with gradient overlay focus)
8. Finish Page (congrats + stats) → Done → Back to Home

**Key Features:**
- Ayah-by-ayah audio playback (not surah-level)
- Persistent audio caching with reuse
- Pre-download all ayahs before session starts
- Gradient overlay focus (0.5 opacity for inactive ayahs)
- Smooth auto-scroll with snap-back
- Session tracking (engagement counts immediately, no minimum)
- Shield application during listening only

**By end of Phase 6, you will have:**
- Audio plays ayah-by-ayah in background
- Lock screen controls working
- Sessions tracked with duration (no minimum time)
- Streak increments after any session
- Shields apply during listening sessions only
- Shields removed after session ends
- All surahs selectable with search
- Start/end ayah range selection
- Persistent audio cache
- Complete flow from FAB to finish page

---

## TASK 6.1: AUDIO PLAYER SERVICE

### AudioPlayerService Implementation

Create a singleton service that handles audio playback with the following capabilities:

**Core Responsibilities:**
- Play individual ayah audio files
- Publish current playback time via Combine
- Handle background audio continuation
- Setup lock screen controls (play/pause only)
- Auto-play next ayah when current finishes
- Stop and reset player state

**Audio Session Configuration:**
- Set category to `.playback` for background audio
- Activate audio session on init
- Configure for `UIBackgroundModes: ["audio"]`

**Lock Screen Integration:**
- Setup `MPRemoteCommandCenter` for play/pause commands
- Update `MPNowPlayingInfoCenter` with current surah/ayah metadata
- Enable play/pause buttons only (disable next/previous)

**Time Observing:**
- Use Combine publisher for current time updates (every 0.5 seconds)
- Allow views to subscribe to time changes for progress display

**Error Handling:**
- Handle invalid URLs gracefully
- Show error on audio playback failure
- Support pause + retry on corrupted audio

---

## TASK 6.2: AUDIO DOWNLOAD SERVICE

### AudioDownloadService Implementation

Create a service to download and cache ayah audio files:

**Core Responsibilities:**
- Download individual ayah audio files from quranaudio.pages.dev
- Check local cache before downloading
- Persist downloaded files to disk
- Track download progress for each ayah
- Support concurrent downloads with progress reporting

**URL Format:**
- Base URL: `https://quranaudio.pages.dev`
- Pattern: `/<reciterNo>/<surahNo>_<ayahNo>.mp3`
- Example: `/2/1_2.mp3` = Reciter 2, Surah 1, Ayah 2

**Cache Strategy:**
- Store files in app's Library/Caches directory
- Check local existence before network call
- Reuse cached files across sessions
- Keep successfully downloaded files even if batch fails
- Cache key: `reciterNo_surahNo_ayahNo.mp3`

**Download Progress:**
- Report progress for each ayah (0-100%)
- Report overall batch progress (total ayahs downloaded / total)
- Support cancellation during batch download

**Error Handling:**
- Show error and prevent session start if download fails
- Keep successfully downloaded files in cache
- Support retry on failed downloads

---

## TASK 6.3: SESSION REPOSITORY

### SessionRepository Implementation

Create repository for session CRUD operations:

**Core Methods:**
- Create session record with surah numbers, reciter ID, ayah ranges
- Update session with duration when ended
- Fetch recent sessions (sorted by date, limit N)
- Fetch today's sessions (for streak calculation)

**Session Model:**
- userId (UUID)
- type (listening/reading)
- surahNumbers (array of ints)
- reciterId (int)
- ayahRanges (dictionary mapping surah to start/end)
- duration (seconds)
- createdAt (date)
- updatedAt (date)

**Engagement Tracking:**
- Save session when STARTED (not when ended)
- Update duration on session end
- No minimum time requirement (engagement counts immediately)

---

## TASK 6.4: SESSION SERVICE

### SessionService Implementation

Create service for session business logic and streak management:

**Core Responsibilities:**
- Start session: Create session record, apply shields
- End session: Update duration, remove shields, update streak
- Update streak: Check consecutive days, increment/reset
- Save preferences: Persist surah selections and reciter

**Streak Logic (No Minimum Time):**
- Engagement counts immediately upon session start
- Check if user has any engagement today
- If no previous engagement: set streak to 1
- If last engagement was yesterday: increment streak
- If last engagement was today: no change
- If last engagement was 2+ days ago: reset to 1
- Update longestStreak if currentStreak exceeds it

**Preference Persistence:**
- Save selected surah numbers to UserDefaults
- Save selected reciter ID to UserDefaults
- Save on START (more reliable than end)
- Load defaults on next session setup

**Shield Integration:**
- Apply temporary session shields when session starts
- Remove session shields when session ends
- Reading sessions do NOT apply shields

---

## TASK 6.5: FOCUS SESSION FLOW VIEWS

### 6.5.1 Floating Action Button (Quran Tab)

**UI:**
- Position: Bottom-right corner
- Icon: Headphone emoji or icon
- Text: "Start Focus Session"
- Action: Navigate to FocusSectionView

### 6.5.2 Focus Section Page

**Layout:**
- Header: "Your Focus Session"
- Section 1: "Select Apps to Block" (inline, taps to FamilyActivityPicker)
  - Display: "Instagram, TikTok, +2 more" (from onboarding defaults)
  - Can edit by tapping
- Section 2: "Selected Surahs" (list of added surahs)
  - Each surah shows: name, start/end ayah range
  - Swipe to delete
  - Tap to edit ayah range
- Button: "Add Surah" (below surah list)
  - Navigates to SelectSurahView
- Button: "Start Session" (bottom, primary)
  - Enabled when at least 1 surah selected
  - Triggers download flow

**Data Loading:**
- Load blocked apps from UserDefaults (onboarding defaults)
- Load previously selected surahs from UserDefaults
- Display current selections

### 6.5.3 Select Surah Page

**UI:**
- Search bar: Filter by surah name/number
- List: All 114 surahs with checkboxes
  - Each row: Surah number, Arabic name, English name
  - Checkmark shows selection state
- Button: "Continue" (top-right or bottom)
  - Shows count: "Continue (3 selected)"
  - Enabled when at least 1 selected
  - Navigates back to Focus Section with surahs added

**Behavior:**
- Multi-select enabled
- Remember last selections
- Search filters list in real-time
- Sort by surah number always

### 6.5.4 Ayah Range Selection (For Each Surah)

**UI:**
- Display: Surah name and total ayah count
- Start Ayah: Picker/dropdown (1 to total)
- End Ayah: Picker/dropdown (start to total)
- Validation: Start ≤ End (show error if invalid)
- Save button: Confirms selection

**Behavior:**
- After adding surahs in Focus Section, show range selector
- Can edit range later by tapping surah in list
- Default: Full surah (1 to totalAyahs)

### 6.5.5 Download Flow (After "Start Session")

**UI:**
- Full-screen modal
- Progress: "Downloading ayah audio..."
- Detailed progress: "23 / 150 ayahs downloaded"
- Percentage: "15%"
- Progress bar: Visual indicator
- Cannot dismiss during download
- Error state: Show error + Retry button if download fails
- Success: Auto-dismiss and navigate to Active Session

**Behavior:**
- Calculate total ayahs: Sum of (end - start + 1) for each surah
- Download all ayahs for all selected surahs
- Check cache first, download missing only
- Show detailed progress for each ayah
- Prevent session start if download fails
- Keep successful downloads in cache

### 6.5.6 Active Session View

**Layout:**
- Top-right: X button (end session with confirmation)
- Middle: Ayah list (scrollable)
  - Current ayah: Full opacity, highlighted
  - Non-current ayahs: 0.5 opacity
  - Gradient overlay between active and inactive
  - Arabic text: Large, Uthmani font
  - Translation: Smaller, subtle below Arabic
  - Auto-scroll to keep current ayah centered
- Bottom: Stacked control bar
  - Current surah name
  - Play/Pause button (on right)
  - Session time (current)

**Focus Behavior:**
- Play ayah-by-ayah sequentially
- When ayah finishes: Auto-play next ayah
- Auto-scroll smoothly to current ayah
- If user manually scrolls: Snap back to current on next ayah
- Gradient overlay: Visual focus effect

**Audio Controls:**
- Play/Pause only (no seek, no speed)
- Update surah name when crossing surah boundaries
- Handle multi-surah sessions

**End Session:**
- Tap X button → Show confirmation dialog
- Confirm → Stop audio, remove shields, save session, navigate to Finish Page

**Error Handling:**
- Network drop during playback: Pause and show error
- Audio file corrupted: Pause, show error with retry
- Try re-downloading corrupted file

### 6.5.7 Finish Page

**UI:**
- Header: "Session Complete!" or congrats message
- Stats:
  - Total time listened
  - Surahs completed
  - Streak increment (if applicable)
- Button: "Done" (primary, bottom)
  - Navigates back to Quran Tab (Home)

**Behavior:**
- Update streak after session ends
- Show encouraging message
- Display session stats

---

## TASK 6.6: VIEWMODELS

### FocusSessionViewModel

**State:**
- selectedSurahs (array of SurahWithRange)
- blockedApps (from UserDefaults)
- isDownloading (bool)
- downloadProgress (0-1)
- downloadedAyahs / totalAyahs
- errorMessage (string?)

**Actions:**
- loadDefaults(): Load blocked apps and last selected surahs
- addSurahs(_ surahs): Add surahs to selection
- removeSurah(_ surah): Remove from selection
- updateAyahRange(for: surah, range: ClosedRange<Int>)
- startSession(): Trigger download flow
- downloadAudio(): Download all ayahs with progress
- navigateToActiveSession(): When download complete

### ActiveSessionViewModel

**State:**
- currentSurah (Surah)
- currentAyah (Ayah)
- isPlaying (bool)
- sessionDuration (TimeInterval)
- currentAyahIndex (Int)
- errorMessage (string?)

**Actions:**
- startSession(): Apply shields, start audio from first ayah
- playAyah(_ ayah): Play specific ayah audio
- togglePlayPause(): Play or pause
- nextAyah(): Move to next ayah, auto-scroll
- endSession(): Stop audio, remove shields, save session, navigate to finish

**Auto-Scroll Logic:**
- Scroll to current ayah when playback starts
- Smooth scroll animation
- Snap back if user manually scrolled
- Keep current ayah centered in viewport

---

## TASK 6.7: DATA MODELS

### SurahWithRange

**Properties:**
- surah (Surah model)
- startAyah (Int)
- endAyah (Int)
- totalAyahs (Int) - cached for validation

**Validation:**
- startAyah >= 1
- endAyah <= totalAyahs
- startAyah <= endAyah

### AyahAudioCache

**Properties:**
- reciterId (Int)
- surahNumber (Int)
- ayahNumber (Int)
- localURL (URL)
- isCached (Bool)

**Methods:**
- checkCache(): Return local URL if exists
- saveToCache(data: Data): Persist to disk
- clearCache(): Remove all cached files

---

## TASK 6.8: ERROR HANDLING

### Download Errors

**Before Session Start:**
- Show error message
- Prevent session from starting
- Show retry button
- Keep successful downloads in cache

**During Playback:**
- Pause audio
- Show error alert
- Offer retry option (re-download and play)
- If network unavailable: Show "Check your connection"

### Audio Playback Errors

**Corrupted Audio:**
- Pause playback
- Show error: "Audio file corrupted. Retrying..."
- Re-download from API
- Resume playback

**Network Drop:**
- If pre-downloaded: Continue playing from cache
- If not pre-downloaded: Pause and show error

**Invalid URL:**
- Skip to next ayah
- Show toast: "Skipping ayah due to error"
- Log error for debugging

---

## TASK 6.9: SCREEN TIME INTEGRATION

### Shield Application

**When Session Starts:**
- Get blocked apps from user selection
- Convert to ApplicationTokens
- Apply temporary shield via ManagedSettingsStore
- Shield only affects selected apps

**When Session Ends:**
- Remove temporary shield
- Apps become accessible again
- Permanent limits (from Blocking tab) remain

**Subscription Expiry:**
- Check subscription status before starting session
- If expired: Remove ALL shields, show paywall
- If expires mid-session: Complete session, then remove shields

---

## TASK 6.10: PERSISTENCE

### UserDefaults Keys

- "lastSelectedSurahs": [Int] (array of surah numbers)
- "lastReciterId": Int
- "blockedApps": Data (encoded ApplicationTokens)

### SwiftData Entities

- Session (with ayahRanges)
- User (with streak info)

### Cache Storage

- File system: Library/Caches/Audio/
- Filename pattern: "{reciterId}_{surahNo}_{ayahNo}.mp3"
- No size limit for V1
- Clear on app logout only

---

## TESTING PHASE 6

### Unit Tests

**AudioPlayerService:**
- Test initialization (not playing, time = 0)
- Test play starts audio
- Test pause stops audio
- Test resume restarts audio
- Test stop clears player state

**AudioDownloadService:**
- Test cache check returns file if exists
- Test download saves to cache
- Test progress reporting
- Test concurrent downloads
- Test error handling on network failure

**SessionService:**
- Test start session creates record
- Test end session updates duration
- Test streak increment on consecutive day
- Test streak reset on missed day
- Test no increment on same day
- Test engagement counts immediately (no minimum)

### Integration Tests

**Download Flow:**
- Test download all ayahs before session
- Test cache reuse on second session
- Test progress updates correctly
- Test error prevents session start

**Active Session:**
- Test ayah-by-ayah playback
- Test auto-scroll behavior
- Test snap-back on manual scroll
- Test multi-surah transitions
- Test shield application/removal

### Manual Testing (On Physical Device)

**Critical Tests:**
1. Build and install on physical iOS 17+ device
2. Complete flow: FAB → Select Surahs → Download → Active Session → Finish
3. Test background audio: Lock device, verify audio continues
4. Test lock screen controls: Play/pause from lock screen
5. Test shields: Verify blocked apps are shielded during session
6. Test shield removal: Verify apps unblocked after session ends
7. Test streak: Complete session, verify streak increments
8. Test cache: Re-select same surahs, verify instant start (cached)
9. Test error: Disconnect network during download, verify error shown
10. Test ayah range: Select partial surah, verify correct ayahs play

---

## BUILD & VERIFY

### Step 1: Run Unit Tests

```bash
cd ~/Projects/surahfocus
make test
```

Expected: All Phase 6 tests passing

### Step 2: Build for Device

In Xcode:
1. Select physical device
2. Cmd+B to build
3. Fix any warnings/errors

### Step 3: Manual Testing

Follow the manual testing checklist above on a physical device.

---

## PHASE 6 COMPLETION CHECKLIST

### Audio System
- [ ] AudioPlayerService singleton implemented
- [ ] Background audio works (test with device locked)
- [ ] Lock screen controls appear (play/pause)
- [ ] Ayah-by-ayah playback working
- [ ] Auto-plays next ayah when current finishes
- [ ] Combine publisher for time updates

### Download System
- [ ] AudioDownloadService implemented
- [ ] Downloads individual ayah files
- [ ] Checks cache before downloading
- [ ] Shows detailed progress
- [ ] Prevents session start on failure
- [ ] Reuses cached files

### Session Management
- [ ] SessionRepository CRUD operations
- [ ] Sessions save on START (not end)
- [ ] No minimum time requirement
- [ ] Streak updates correctly
- [ ] Preferences persist (surahs, reciter)

### UI Flow
- [ ] FAB on Quran Tab
- [ ] Focus Section Page displays correctly
- [ ] Select Surah Page multi-selects
- [ ] Ayah range selection works
- [ ] Download modal shows progress
- [ ] Active Session View with gradient overlay
- [ ] Auto-scroll to current ayah
- [ ] Snap-back on manual scroll
- [ ] Finish Page shows stats

### Screen Time Integration
- [ ] Shields apply during listening session
- [ ] Shields remove after session ends
- [ ] Reading sessions don't apply shields
- [ ] Subscription expiry handled

### Testing
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Manual testing on device complete
- [ ] Background audio verified
- [ ] Lock screen controls verified

---

## TROUBLESHOOTING

### Issue: Audio doesn't play in background
**Solution:**
- Verify Info.plist has `UIBackgroundModes: ["audio"]`
- Check AVAudioSession category is `.playback`
- Test on physical device (simulator limited)

### Issue: Download progress doesn't update
**Solution:**
- Verify Combine publishers are on @MainActor
- Check progress updates on main thread
- Add debug logging for download state

### Issue: Auto-scroll doesn't work
**Solution:**
- Verify ScrollViewReader is used
- Check proxy is updated on ayah change
- Test scroll animation duration

### Issue: Shields don't apply
**Solution:**
- Verify ApplicationTokens are valid
- Check ManagedSettingsStore configuration
- Test on physical device (required)
- Verify FamilyControls authorization

### Issue: Streak not updating
**Solution:**
- Check session is saved on START
- Verify streak logic handles all cases
- Check lastEngagementDate is updated
- Test consecutive day logic

---

## NEXT PHASE PREVIEW

**Phase 7 will cover:**
- Complete BlockingTab implementation
- Settings tab with reciter selection
- App management (edit limits, remove apps)
- Profile and subscription management

**Prerequisites for Phase 7:**
- Phase 6 fully complete
- Shield application working from Phase 6
- User can complete full listening flow
- Session tracking functional

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 6.1 (Audio Player): 3 hours
- Task 6.2 (Download Service): 2 hours
- Task 6.3 (Session Repository): 1.5 hours
- Task 6.4 (Session Service): 2 hours
- Task 6.5 (Focus Flow Views): 5 hours
- Task 6.6 (ViewModels): 2 hours
- Task 6.7 (Data Models): 1 hour
- Task 6.8 (Error Handling): 1.5 hours
- Task 6.9 (Screen Time): 1.5 hours
- Task 6.10 (Persistence): 1 hour
- Testing: 3 hours
- **Total: 23.5 hours over 2-3 days**

**Track your actual time:**
- Day 10 actual: _____ hours
- Day 11 actual: _____ hours

---

**🎯 PHASE 6 COMPLETE! Ready for Phase 7: Blocking + Settings Tabs**
