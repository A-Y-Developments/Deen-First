# PHASE 5: MAIN TABS + QURAN READING
**Timeline:** Days 8-9 (Feb 10-11)
**Duration:** 2 full days
**Goal:** 3-tab navigation working, Quran browsing functional, reading experience polished

---

## PREREQUISITES

- [ ] Phase 4 completed (Quran API working)
- [ ] Can fetch all 114 surahs
- [ ] Caching functional
- [ ] 93+ tests passing

---

## PHASE OVERVIEW

This phase builds the main app experience:
1. MainTabView with 3 tabs (Quran, Blocking, Settings)
2. QuranTabView with surah list and search
3. SurahDetailView with ayah display
4. User greeting section ("As-salamu alaykum, [Name]")
5. Streak badge component
6. Reusable UI components
7. Empty states for tabs

**Streak Tracking Update**: No minimum time requirement - user engagement counts immediately when opening/reading a surah or starting a listening session.

**By end of Phase 5, you will have:**
- 3-tab navigation functional
- Can browse all 114 surahs
- Search filters correctly
- Can read any surah with translation
- User greeting displays on Quran tab
- Streak displays on Quran tab
- 110+ unit tests passing

---

## COMPONENTS TO CREATE

### 1. Main Tab Structure
**File**: `Sources/Presentation/MainTabs/MainTabView.swift`

**Purpose**: Root tab navigation container

**Tab Configuration**:
- Tab 0: QuranTabView (default, first visible)
- Tab 1: BlockingTabView (placeholder for Phase 7)
- Tab 2: SettingsTabView (placeholder for Phase 7)

**Requirements**:
- Use SwiftUI TabView with @State selectedTab binding
- Tab icons: book.fill, shield.fill, gearshape.fill
- Tab labels: "Quran", "Blocking", "Settings"
- Accent color: #4facfe (brand blue gradient)
- Each tab wrapped in NavigationStack
- Tab bar visible at bottom

**Dependencies**: None

### 2. Quran Tab Components

#### 2.1 QuranTabViewModel
**File**: `Sources/Presentation/MainTabs/QuranTab/QuranTabViewModel.swift`

**Purpose**: Business logic for Quran tab - manages surah list, search, user data, streak

**Published Properties**:
- `surahs: [Surah]` - all 114 surahs loaded from API
- `filteredSurahs: [Surah]` - search-filtered surahs for display
- `searchQuery: String` - current search text
- `isLoading: Bool` - loading state indicator
- `errorMessage: String?` - error message text
- `showError: Bool` - triggers error alert
- `currentStreak: Int` - user's current streak count
- `user: User?` - current user object (for greeting name)

**Methods**:
- `loadSurahs() async` - fetch all surahs from QuranService, load user data and streak
- `searchSurahs()` - filter surahs based on searchQuery using QuranService.searchSurahs()
- `clearSearch()` - reset searchQuery and restore filteredSurahs to all surahs

**Dependencies** (injected via DIContainer):
- `quranService: QuranService` - for fetching surahs and searching
- `authService: AuthService` - for getting current user

**Initialization**:
- Optional injection of quranService and authService for testing
- Defaults to DIContainer.shared if not provided

#### 2.2 QuranTabView
**File**: `Sources/Presentation/MainTabs/QuranTab/QuranTabView.swift`

**Purpose**: Main Quran browsing screen - displays surah list with search and streak

**Layout Structure** (top to bottom):
1. User greeting section: "As-salamu alaykum," + user name (if user exists)
2. StreakBadge (only shown if currentStreak > 0)
3. SearchBar component
4. ScrollView with LazyVStack containing SurahCard for each surah
5. Pull-to-refresh support

**Navigation**:
- NavigationStack wrapper
- Navigation title: "Quran"
- Toolbar trailing button: speaker icon (speaker.wave.2.fill) → navigates to .listenSession
- SurahCard tap → navigates to .surahDetail(surahId: surah.number)

**State Management**:
- @StateObject for QuranTabViewModel
- @EnvironmentObject for Router
- .task {} modifier to call viewModel.loadSurahs() when view appears (only if surahs empty)
- .onChange(of: searchQuery) to trigger viewModel.searchSurahs()
- .alert() modifier for error display
- .refreshable {} modifier for pull-to-refresh

**Loading States**:
- Show ProgressView when isLoading && surahs.isEmpty
- Show content when surahs loaded

#### 2.3 SurahCard Component
**File**: `Sources/Presentation/Components/SurahCard.swift`

**Purpose**: Reusable card displaying single surah in list

**Visual Elements** (HStack, left to right):
1. **Left**: Circle badge with surah number
   - Circle stroke border (color: #4facfe, lineWidth: 2)
   - Frame: 50x50
   - Centered number text (semibold, size 16)
2. **Middle**: Surah information (VStack, leading aligned)
   - English name (semibold, size 18)
   - HStack with: englishNameTranslation + bullet + numberOfAyahs + "ayahs" (size 14, secondary)
3. **Right**: Arabic name
   - surah.surahNameArabicLong (medium, size 20)

**Styling**:
- HStack with 16pt spacing
- Padding: 16pt
- Corner radius: 12pt
- Background: systemBackground
- Shadow: black opacity 0.05, radius 8, offset (0, 2)
- ButtonStyle: plain (for tap handling)

**Input**: let surah: Surah

#### 2.4 StreakBadge Component
**File**: `Sources/Presentation/Components/StreakBadge.swift`

**Purpose**: Display user's current streak with motivational text

**Visual Elements** (HStack):
1. Fire emoji (🔥) - size 24
2. VStack (leading aligned, 8pt spacing):
   - "[X] day streak" text (bold, size 16)
   - "Keep it going!" subtitle (size 12, secondary)
3. Spacer (to push content to left)

**Styling**:
- Padding: 16pt
- Corner radius: 12pt
- Background: LinearGradient
  - Colors: #FFE5B4 (opacity 0.3) to #FFD700 (opacity 0.2)
  - StartPoint: leading, EndPoint: trailing

**Input**: let streak: Int

**Conditional Display**: Only show when streak > 0

#### 2.5 SearchBar Component
**File**: `Sources/Presentation/Components/SearchBar.swift`

**Purpose**: Search input field for filtering surahs

**Visual Elements** (HStack):
1. Magnifying glass icon (magnifyingglass) - secondary color
2. TextField with placeholder text
3. X circle button (xmark.circle.fill) - only shown when text not empty

**Styling**:
- HStack spacing
- Padding: 12pt
- Background: systemGray6
- Corner radius: 10pt
- TextField: plain style

**Inputs**:
- @Binding var text: String
- let placeholder: String

**Behavior**:
- X button clears text binding
- Placeholder provided by parent (e.g., "Search surahs...")

### 3. Surah Detail Components

#### 3.1 SurahDetailViewModel
**File**: `Sources/Presentation/MainTabs/QuranTab/SurahDetailViewModel.swift`

**Purpose**: Manages surah detail data - surah metadata, ayahs, translation toggle

**Stored Property**:
- `surahNumber: Int` - the surah to load (set at init)

**Published Properties**:
- `surah: Surah?` - surah metadata
- `ayahs: [Ayah]` - list of verses
- `showTranslation: Bool` - translation visibility toggle (default: true)
- `isLoading: Bool` - loading state
- `errorMessage: String?` - error text
- `showError: Bool` - error alert flag

**Methods**:
- `loadSurahDetail() async` - fetch surah + ayahs from QuranService.loadSurahDetail()
- `toggleTranslation() async` - flip showTranslation flag, reload data

**Dependencies** (via DIContainer):
- `quranService: QuranService` - for fetching surah details

**Initialization**:
- Required: surahNumber: Int
- Optional: quranService injection for testing

#### 3.2 SurahDetailView
**File**: `Sources/Presentation/MainTabs/QuranTab/SurahDetailView.swift`

**Purpose**: Display individual surah with all ayahs, reading experience

**Layout Structure** (top to bottom):
1. SurahHeader component
2. BismillahView component (conditional: if surah.number != 1 && surah.number != 9)
3. ScrollView with LazyVStack of AyahCard for each ayah
4. Bottom padding (80pt for future floating button)

**Navigation**:
- Navigation title: surah.englishName (or "Loading..." if nil)
- NavigationBarTitleDisplayMode: inline
- Toolbar trailing button: translation toggle icon
  - Icon: text.bubble.fill (when showing) or text.bubble (when hidden)
  - Color: #4facfe
  - Action: call viewModel.toggleTranslation()
- Back button: automatic from NavigationStack

**State Management**:
- @StateObject for SurahDetailViewModel (initialized with surahNumber)
- .task {} modifier to call viewModel.loadSurahDetail() when ayahs empty
- .alert() modifier for error display

**Loading States**:
- Show ProgressView when isLoading && ayahs.isEmpty
- Show content when ayahs loaded

#### 3.3 AyahCard Component
**File**: `Sources/Presentation/Components/AyahCard.swift`

**Purpose**: Display single ayah with Arabic text and optional translation

**Visual Elements** (VStack, trailing aligned, 12pt spacing):
1. **Top**: Ayah number badge (HStack)
   - Circle (fill: #4facfe opacity 0.1, frame: 32x32)
   - Overlay: numberInSurah text (semibold, size 12, color: #4facfe)
   - Spacer
2. **Middle**: Arabic text
   - ayah.text (medium, size 24)
   - MultilineTextAlignment: trailing
   - Frame maxWidth: .infinity, alignment: trailing
3. **Bottom**: English translation (conditional)
   - Only shown if showTranslation == true AND ayah.english != nil
   - Divider (vertical padding 4pt)
   - ayah.english text (size 16, secondary)
   - MultilineTextAlignment: leading
   - Frame maxWidth: .infinity, alignment: leading

**Styling**:
- VStack alignment: trailing
- Padding: 16pt
- Corner radius: 12pt
- Background: systemBackground
- Shadow: black opacity 0.05, radius 4, offset (0, 2)

**Inputs**:
- let ayah: Ayah
- let showTranslation: Bool

#### 3.4 SurahHeader Component
**File**: `Sources/Presentation/Components/SurahHeader.swift`

**Purpose**: Display surah metadata at top of detail view

**Visual Elements** (VStack, center aligned, 12pt spacing):
1. **Top**: Arabic name
   - surah.surahNameArabicLong (bold, size 32)
2. **Middle**: English translation
   - surah.englishNameTranslation (size 18, secondary)
3. **Bottom**: Info row (HStack, 16pt spacing)
   - Label: "[numberOfAyahs] Ayahs" with icon text.alignleft (size 14, secondary)
   - Text: bullet (secondary)
   - Text: surah.revelationPlace (size 14, secondary)

**Styling**:
- Frame maxWidth: .infinity (center alignment)
- Padding: 20pt
- Corner radius: 16pt
- Background: LinearGradient
  - Colors: #4facfe (opacity 0.1) to #00f2fe (opacity 0.1)
  - StartPoint: topLeading, EndPoint: bottomTrailing

**Input**: let surah: Surah

#### 3.5 BismillahView Component
**File**: `Sources/Presentation/Components/BismillahView.swift`

**Purpose**: Display Bismillah text before surah content

**Visual Elements**:
- Arabic text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
- Center aligned
- Font: medium, size 24

**Styling**:
- Padding: 20pt
- Frame maxWidth: .infinity
- Background: #4facfe (opacity 0.05)
- Corner radius: 12pt

**Conditional Display Rules**:
- DON'T show for Surah 1 (Al-Fatihah) - Bismillah is first ayah
- DON'T show for Surah 9 (At-Tawbah) - no Bismillah
- SHOW for all other surahs

### 4. Placeholder Tab Views

#### 4.1 BlockingTabView
**File**: `Sources/Presentation/MainTabs/BlockingTab/BlockingTabView.swift`

**Purpose**: Placeholder for Phase 7 blocking functionality

**Content** (VStack, 24pt spacing):
- Icon: shield.fill (size 60, color: #4facfe)
- Title: "Blocking" (bold, size 24)
- Subtitle: "Phase 7: Manage blocked apps and time limits" (size 16, secondary)

**Navigation**:
- NavigationStack wrapper
- Navigation title: "Blocking"
- Center-aligned content with padding

#### 4.2 SettingsTabView
**File**: `Sources/Presentation/MainTabs/SettingsTab/SettingsTabView.swift`

**Purpose**: Placeholder for Phase 7 settings functionality

**Content** (VStack, 24pt spacing):
- Icon: gearshape.fill (size 60, color: #4facfe)
- Title: "Settings" (bold, size 24)
- Subtitle: "Phase 7: Profile, subscription, and app settings" (size 16, secondary)

**Navigation**:
- NavigationStack wrapper
- Navigation title: "Settings"
- Center-aligned content with padding

---

## ROUTING UPDATES

### Router Changes
**File**: `Sources/Core/SceneNavigation/Router.swift`

**Verify Existing Routes**:
- `.mainTabs` - should route to MainTabView
- `.surahDetail(surahId: Int)` - should route to SurahDetailView
- `.listenSession` - already shows placeholder (no changes needed)

**RootView Updates**:
**File**: `Sources/RootView.swift`

**Update Required**: Change `.mainTabs` case body from placeholder text to:
```swift
MainTabView()
```

**Verify `.surahDetail(surahId:)` case** routes to:
```swift
SurahDetailView(surahNumber: surahId)
```

---

## TESTING REQUIREMENTS

### Unit Tests (Target: +8 tests, 101+ total)

#### QuranTabViewModelTests
**File**: `Tests/Presentation/MainTabs/QuranTabViewModelTests.swift`

**Test Cases**:
1. `testInitialState` - Verify all @Published properties initialized correctly
2. `testLoadSurahsSuccess` - Verify surahs populate after loadSurahs()
3. `testLoadSurahsLoadsUserStreak` - Verify currentStreak loads from user
4. `testSearchSurahsFiltersResults` - Verify searchSurahs() filters correctly
5. `testClearSearchRestoresAllSurahs` - Verify clearSearch() resets state

**Mock Requirements**:
- MockQuranService with properties: surahsToReturn, searchResults
- MockAuthService with property: userToReturn
- Implement QuranService protocol methods
- Implement AuthService.getCurrentUser()

#### SurahDetailViewModelTests
**File**: `Tests/Presentation/MainTabs/SurahDetailViewModelTests.swift`

**Test Cases**:
1. `testInitialState` - Verify @Published properties initialized correctly
2. `testLoadSurahDetailSuccess` - Verify surah and ayahs populate after load
3. `testToggleTranslationChangesState` - Verify toggleTranslation() flips flag

**Mock Requirements**:
- MockQuranService with properties: surahToReturn, ayahsToReturn
- Implement QuranService.loadSurahDetail() method

---

## VERIFICATION CHECKLIST

### Build Verification
```bash
make build
```

**Expected Results**:
- No compile errors
- All 3 tabs render correctly
- Tab switching works smoothly
- Tab bar icons display correctly

### Manual Testing (Simulator)

**Quran Tab Flow**:
1. App launches → Quran tab is default/first
2. See greeting "As-salamu alaykum, [User Name]"
3. See streak badge if streak > 0
4. See all 114 surahs in scrollable list
5. Type "opening" in search → Only Al-Fatihah shows
6. Clear search → All surahs return
7. Tap any surah → Navigate to detail view
8. See surah header with Arabic name
9. See Bismillah (if not surah 1 or 9)
10. See all ayahs with Arabic text
11. Tap translation toggle → Translations hide
12. Tap again → Translations show
13. Navigate back → Return to surah list
14. Pull down to refresh → Surahs reload

**Tab Navigation**:
1. Tap Blocking tab → See placeholder with "Phase 7" message
2. Tap Settings tab → See placeholder with "Phase 7" message
3. Tap Quran tab → Return to Quran tab

**Performance**:
1. Scroll rapidly through 114 surahs → Should be smooth (60 FPS)
2. Open Al-Baqarah (286 ayahs) → Scroll through ayahs smoothly
3. Search responsiveness → Results update immediately on typing

**Error Handling**:
1. Open app with no internet → Show cached data if available
2. Open app with no internet and no cache → Show error alert
3. Search returns no results → Show empty state or message

---

## FILE STRUCTURE

```
Sources/Presentation/
├── MainTabs/
│   ├── MainTabView.swift (NEW)
│   ├── QuranTab/
│   │   ├── QuranTabView.swift (NEW)
│   │   └── QuranTabViewModel.swift (NEW)
│   ├── BlockingTab/
│   │   └── BlockingTabView.swift (NEW)
│   └── SettingsTab/
│       └── SettingsTabView.swift (NEW)
├── Components/
│   ├── SurahCard.swift (NEW)
│   ├── AyahCard.swift (NEW)
│   ├── StreakBadge.swift (NEW)
│   ├── SearchBar.swift (NEW)
│   ├── SurahHeader.swift (NEW)
│   └── BismillahView.swift (NEW)
└── ListenSession/
    └── (Existing placeholder for Phase 6)

Tests/Presentation/MainTabs/
├── QuranTabViewModelTests.swift (NEW)
└── SurahDetailViewModelTests.swift (NEW)

Modified Files:
├── Sources/RootView.swift (UPDATE: .mainTabs case)
└── Sources/Core/SceneNavigation/Router.swift (VERIFY routes)
```

---

## PRD NOTES & UPDATES

### Changes from Original PRD:
1. **Streak Tracking**: Removed 2-minute minimum. User engagement counts immediately when opening a surah or starting to listen.
2. **User Greeting**: Added "As-salamu alaykum, [Name]" to Quran tab (per user request).
3. **Session Tracking**: Deferred to later phase - Phase 5 focuses on UI only.

### PRD References:
- Section 6.5: Main Navigation (3-Tab Bottom Bar)
- Section 6.6: Tab 1 - Quran (Reading & Listening)
- Section 6.6.1: Surah Reading View

---

## DEPENDENCIES (Already Exist)

### Services to Reuse:
- `QuranService.loadAllSurahs()` - Returns [Surah] with 114 surahs
- `QuranService.loadSurahDetail(number:withTranslation:)` - Returns (Surah, [Ayah])
- `QuranService.searchSurahs(query:in:)` - Filters [Surah] by query
- `AuthService.getCurrentUser()` - Returns User with name, streak

### Entities to Reuse:
- `Surah` - number, name, surahNameArabicLong, englishName, englishNameTranslation, numberOfAyahs, revelationPlace
- `Ayah` - number, text, numberInSurah, english (translation text)
- `User` - name, currentStreak, lastEngagementDate

### Navigation:
- `Router.navigate(to:)` - For navigation
- Router.Route.mainTabs - Main tab view
- Router.Route.surahDetail(surahId:) - Surah detail
- Router.Route.listenSession - Listening (Phase 6)

---

## IMPLEMENTATION QUESTIONS - ANSWERED

### Q1: Translation Format
**Use**: `ayah.english` property contains the English translation text.

### Q2: Arabic Name Display
**Use**: `surah.surahNameArabicLong` for main display (more complete Arabic name).

### Q3: Revelation Property
**Use**: `surah.revelationPlace` - shows "Makkah" or "Madina" (display as-is).

### Q4: Search Scope
**QuranService.searchSurahs()** already searches:
- Arabic name (surah.name)
- English translation (surah.englishNameTranslation)
- Surah number

No additional search implementation needed.

### Q5: Bismillah Text
**Hardcode** in BismillahView:
```
"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
```

**Display Rules**:
- Surah 1 (Al-Fatihah): DON'T show (it's the first ayah)
- Surah 9 (At-Tawbah): DON'T show (no Bismillah)
- All others: SHOW

### Q6: ListenSession Route
**No changes** - Router already shows "Listen Session - Phase 6" placeholder.

### Q7: Error Handling
**QuranService throws**:
- `invalidSurahNumber` → Show "Surah not found"
- `networkError` → Show "Unable to load. Check your connection."
- Other errors → Show localized error message

**UI Implementation**: Use `.alert(isPresented: $showError)` modifier.

---

## TIME ALLOCATION (13 hours)

### Day 1 (7 hours):
- Task 5.1: MainTabView + placeholder tabs (2 hours)
- Task 5.2: QuranTabViewModel + tests (2 hours)
- Task 5.3: QuranTabView + components (3 hours)

### Day 2 (6 hours):
- Task 5.4: SurahDetailViewModel + tests (2 hours)
- Task 5.5: SurahDetailView + components (4 hours)

---

## NEXT PHASE PREVIEW

**Phase 6 will cover:**
- AudioPlayerService with AVFoundation
- Background audio playback
- Lock screen controls
- SessionRepository implementation
- ListenSessionView with audio controls
- Multi-surah queue playback

**Prerequisites for Phase 6:**
- Phase 5 fully complete
- Navigation to .listenSession works
- 101+ tests passing
- Quran UI polished

---

## PHASE 5 COMPLETION CHECKLIST

### Main Tab Structure
- [ ] MainTabView created with 3 tabs
- [ ] Tab bar icons and labels correct
- [ ] Tab switching works smoothly
- [ ] Placeholder views for Blocking and Settings
- [ ] RootView updated to use MainTabView

### Quran Tab
- [ ] QuranTabViewModel implemented
- [ ] QuranTabView created with user greeting
- [ ] Can load all 114 surahs
- [ ] User greeting displays with name
- [ ] Streak badge displays when applicable
- [ ] Search bar functional
- [ ] Search filters correctly
- [ ] Pull-to-refresh works
- [ ] 5 Quran tab tests passing

### Surah Detail
- [ ] SurahDetailViewModel implemented
- [ ] SurahDetailView created
- [ ] Surah header displays correctly
- [ ] Bismillah shows correctly (not 1, 9)
- [ ] All ayahs render
- [ ] Translation toggle works
- [ ] Arabic text aligned right
- [ ] Translation aligned left
- [ ] 3 surah detail tests passing

### Components
- [ ] SurahCard component
- [ ] AyahCard component
- [ ] StreakBadge component
- [ ] SearchBar component
- [ ] BismillahView component
- [ ] SurahHeader component

### Integration
- [ ] Router verified with routes
- [ ] Navigation works end-to-end
- [ ] 101+ total tests passing
- [ ] Smooth scroll performance
- [ ] Error handling works

### Verification
```bash
# All tests pass
make test

# Build succeeds
make build

# Manual testing complete
```

---

**🎯 PHASE 5 COMPLETE! Ready for Phase 6: Listening Sessions + Audio Player**

**Commit message**:
```
feat: Phase 5 complete - Main Tabs + Quran Reading

- 3-tab navigation (Quran, Blocking, Settings)
- Quran browsing with 114 surahs
- Surah detail view with ayah display
- Search functionality
- User greeting "As-salamu alaykum"
- Streak badge display
- Translation toggle
- 8 new unit tests (101+ total passing)
```
