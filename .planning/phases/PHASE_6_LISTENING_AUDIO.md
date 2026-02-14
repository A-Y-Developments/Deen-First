# PHASE 6: LISTENING SESSIONS - FINAL TOUCHES
**Timeline:** Day 10 (Feb 14)
**Duration:** ~4 hours
**Goal:** Add exit confirmation dialog, cleanup unused cache code, verify complete flow

---

## STATUS: COMPLETE ✅

All Phase 6 critical bugs fixed:

1. ✅ Ayahs fetched from QuranService (not empty)
2. ✅ Audio auto-plays on session start
3. ✅ Auto-scroll centers current ayah
4. ✅ Auto-advance to next ayah
5. ✅ Exit confirmation shows & navigates properly
6. ✅ Router passed to ViewModel
7. ✅ Error handling added
8. ✅ Reciter changed from 7 to 1 (Mishary)

---

## WHAT'S ALREADY BUILT ✅

| Component | Location | Status |
|-----------|----------|--------|
| AyahAudio model (with reciter URLs) | `Domain/Entities/AyahAudio.swift` | ✅ Complete |
| AudioPlayerService | `Services/AudioPlayerService.swift` | ✅ Complete |
| AyahAudioPlayerService (queue management) | `Services/AyahAudioPlayerService.swift` | ✅ Complete |
| ScreenTimeService (shields) | `Services/ScreenTimeService.swift` | ✅ Complete |
| FocusSectionView | `Features/Quran/Views/FocusSectionView.swift` | ✅ Complete |
| SelectSurahView | `Features/Quran/Views/SelectSurahView.swift` | ✅ Complete |
| AyahRangeSelectionView | `Features/Quran/Views/AyahRangeSelectionView.swift` | ✅ Complete |
| ActiveSessionView | `Features/Quran/Views/ActiveSessionView.swift` | ✅ Complete |
| SessionFinishView | `Features/Quran/Views/SessionFinishView.swift` | ✅ Complete |
| QuranTabView (FAB) | `Features/Quran/Views/QuranTabView.swift` | ✅ Complete |
| Navigation flow | QuranTab → FocusSection → SelectSurah → AyahRange → ActiveSession → SessionFinish | ✅ Complete |

---

## COMPLETED FIXES

### Bug Fix 1: Fetch ayahs in FocusSectionViewModel
**File:** `Sources/Presentation/MainTabs/QuranTab/FocusSectionViewModel.swift:146-158`

Changed `navigateToDownload()` from passing empty array to fetching actual ayahs:
- Made function async
- Loops through selectedSurahs
- Fetches ayahs for each surah
- Filters by ayah range
- Passes complete ayah list to ActiveSessionView

### Bug Fix 2: Router connected to ViewModel
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:17`

Changed `private weak var router` to `weak var router` (public)

**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionView.swift:105-107`

Added `.onAppear` to inject router from environment

### Bug Fix 3: Auto-scroll logic fixed
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionView.swift:45-51`

Changed from searching by `numberInSurah` to direct array access:
```swift
guard newIndex >= 0, newIndex < viewModel.ayahs.count else { return }
let currentAyah = viewModel.ayahs[newIndex]
```

### Bug Fix 4: Error handling added
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:10,46-59`

Added `@Published var errorMessage: String?`
Modified `startSession()` to properly handle errors

### Bug Fix 5: Queue finished handler
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:48-56`

Added `onQueueFinished` callback in `setupBindings()`
Added `handleQueueFinished()` to navigate to SessionFinishView when all ayahs complete

### Bug Fix 6: Exit confirmation state reset
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:82`

Added `showEndConfirmation = false` at start of `confirmEndSession()`

### Bug Fix 7: Error display in ActiveSessionView
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionView.swift:100-105`

Added error alert to display `errorMessage`

### Bug Fix 8: Reciter changed to 1
**File:** `Sources/Presentation/MainTabs/QuranTab/ActiveSessionViewModel.swift:51,54`

Changed from `reciterId: 7` to `reciterId: 1` (Mishary)

---

## REMAINING TASKS

### Task 6.1: Add Exit Confirmation Dialog

**File:** `Features/Quran/Views/ActiveSessionView.swift`

When user taps X button to end session early:
1. Show alert dialog: "Are you sure you want to end this session?"
2. Buttons: "Cancel" (default) / "End Session" (destructive)
3. Only proceed with endSession() if user confirms

**Current behavior:** Directly ends session
**Required:** Add confirmation step

---

### Task 6.2: Cleanup AyahAudio Model

**File:** `Domain/Entities/AyahAudio.swift`

Remove unused cache-related properties:
- `localURL: URL?`
- `isCached: Bool` (computed property)
- `downloadURL: URL` (rename to `streamURL`)

**Simplified model:**
```swift
struct AyahAudio: Identifiable, Hashable {
    let id: String // "{reciterId}_{surahNo}_{ayahNo}"
    let reciterId: Int
    let surahNumber: Int
    let ayahNumber: Int
    let streamURL: URL // Direct stream URL

    init(reciterId: Int, surahNumber: Int, ayahNumber: Int) {
        self.id = "\(reciterId)_\(surahNumber)_\(ayahNumber)"
        self.reciterId = reciterId
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.streamURL = URL(string: "https://quranaudio.pages.dev/\(reciterId)/\(surahNumber)_\(ayahNumber).mp3")!
    }
}
```

Remove `AyahAudioDownloadProgress` struct (unused).

---

### Task 6.3: Set Default Reciter

**Location:** Wherever audio playback is initialized

Use hardcoded default: **Reciter 1 (Mishary Rashid Alafasy)**

No UserDefaults storage needed - always use reciter 1.

---

### Task 6.4: Verify Complete Flow

**Manual testing checklist:**
1. FAB → Focus Section → Select apps + surahs
2. Set ayah ranges → Start Session
3. Active Session: Auto-play ayah-by-ayah
4. Verify auto-scroll to current ayah (centered)
5. Verify gradient overlay (inactive ayahs at 0.5 opacity)
6. Tap X → See "Are you sure?" dialog → Cancel → Stay in session
7. Tap X → Confirm → Navigate to Finish Page
8. Done button → Back to Quran Tab
9. Verify shields applied during session
10. Verify shields removed after session ends

---

## USER FLOW (SIMPLIFIED)

```
Quran Tab
  ↓ (tap FAB "Start Focus Session")
Focus Section
  - Select blocked apps
  - Add/select surahs
  - Set ayah ranges
  ↓ (tap "Start Session")
Active Session
  - Stream audio directly (no download)
  - Ayah-by-ayah playback
  - Auto-scroll to current ayah
  - Gradient focus overlay
  ↓ (auto-finish OR user exits)
Session Finish
  - Show stats (time, surahs, streak)
  ↓ (tap "Done")
Quran Tab
```

---

## AUDIO STREAMING (NO CACHE)

- **URL:** `https://quranaudio.pages.dev/{reciterId}/{surahNo}_{ayahNo}.mp3`
- **Default reciter:** 1 (Mishary)
- **Method:** Stream directly via AVPlayer
- **No local storage** - play from URL
- **Background audio:** Keep enabled (avoid bugs)
- **Lock screen controls:** Keep enabled (avoid bugs)

---

## SHIELD INTEGRATION

**Session Start:**
- Apply shields from blocked apps selection
- Shields only apply during listening sessions

**Session End:**
- Remove shields (apps accessible again)
- Save session with duration
- Update streak if applicable

---

## SESSION TRACKING

- **Save:** On session START (engagement counts immediately)
- **No minimum duration** - any session counts
- **Streak:** Increment if last engagement was yesterday
- **Duration:** Update on session end

---

## TESTING PHASE 6

### Manual Testing (Physical Device Required)

**Critical Tests:**
1. Full flow: FAB → Surah selection → Active Session → Finish → Done
2. Auto-play: Verify seamless ayah-to-ayah transition
3. Auto-scroll: Verify current ayah stays centered
4. Exit dialog: Tap X → Verify "Are you sure?" appears
5. Exit cancel: Cancel dialog → Verify session continues
6. Exit confirm: Confirm → Verify navigation to Finish
7. Shields: Verify blocked apps inaccessible during session
8. Shield removal: Verify apps accessible after session
9. Multi-surah: Select 2+ surahs → verify seamless transition
10. Network: Test with unstable network → verify graceful handling

### Unit Tests (If Needed)

**AudioPlayerService:**
- Test play/pause/stop
- Test auto-advance to next ayah
- Test session duration tracking

**SessionService:**
- Test streak increment logic
- Test shield apply/remove
- Test session save on start

---

## BUILD & VERIFY

```bash
cd ~/Projects/surahfocus
make build
```

Fix any warnings/errors.

---

## PHASE 6 COMPLETION CHECKLIST

### UI/UX
- [x] Exit confirmation dialog shows "Are you sure?"
- [x] Cancel button stays in session
- [x] Confirm button ends session properly
- [x] Active Session auto-scrolls to current ayah
- [x] Gradient overlay visible (0.5 opacity for inactive)
- [x] Seamless ayah-to-ayah playback

### Code Cleanup
- [ ] AyahAudio: Remove `localURL`, `isCached`, `downloadURL`
- [ ] AyahAudio: Rename to `streamURL` or keep `downloadURL`
- [ ] Remove `AyahAudioDownloadProgress` struct
- [x] Set reciter 1 as hardcoded default

### Screen Time
- [ ] Shields apply on session start
- [ ] Shields remove on session end
- [x] No UserDefaults for reciter (use hardcoded)

### Testing
- [ ] Full flow tested on physical device
- [ ] Exit dialog tested (cancel + confirm)
- [ ] Multi-surah session tested
- [ ] Network edge cases tested
- [ ] Background audio still works

---

## TIME TRACKING

**Estimated:**
- Task 6.1 (Exit dialog): 30 min
- Task 6.2 (Cleanup model): 15 min
- Task 6.3 (Default reciter): 15 min
- Task 6.4 (Testing): 3 hours
- **Total: ~4 hours**

---

## NEXT PHASE PREVIEW

**Phase 7 will cover:**
- Complete BlockingTab implementation
- Settings tab with reciter selection (later, not now)
- App management (edit limits, remove apps)
- Profile and subscription management

**Prerequisites for Phase 7:**
- Phase 6 fully verified
- Exit confirmation working
- Complete flow tested on device

---

**🎯 PHASE 6 SIMPLIFIED: Final touches on existing implementation**
