# PRODUCT REQUIREMENTS DOCUMENT (PRD)
# Deen First - Quran Reading & Screen Time Management

**Version:** 3.0 (Final)  
**Date:** February 2, 2026  
**Project Timeline:** Feb 3 - Feb 18, 2026 (16 days)  
**Target Release:** February 18, 2026  
**App Name:** Deen First

---

## 1. EXECUTIVE SUMMARY

### 1.1 Product Overview
Deen First is a premium iOS productivity app that combines Quran reading with screen time management using Apple's Screen Time API. The app blocks distracting applications and builds daily Quran engagement habits through streak tracking, targeting Gen Z Muslims struggling with phone addiction and doom scrolling.

### 1.2 Core Value Proposition
- **Problem**: Gen Z Muslims struggle with phone addiction and neglect Quran reading
- **Solution**: Block distracting apps with daily limits; build consistent Quran habits through streak-based gamification
- **Unique Angle**: Premium Quran app with native Screen Time API integration
- **Business Model**: Subscription-only with free trials (no free tier)

### 1.3 Target Audience
- **Primary**: Gen Z Muslims (ages 16-28)
- **Secondary**: Muslim parents managing children's screen time
- **Characteristics**: Tech-savvy, aware of phone addiction, want to reconnect with Quran, willing to pay for premium experience

### 1.4 Monetization
- **Monthly**: $4.99/month with 3-day free trial
- **Yearly**: $29.99/year with 7-day free trial  
- **No free tier**: Must subscribe (after trial) to access app features
- **Payment**: Apple In-App Purchase
- **Subscription Management**: RevenueCat SDK
- **Auto-renewal**: Monthly (every 30 days), Yearly (every 365 days)

### 1.5 Success Metrics (Development Phase Only)

**Primary Goal**: Successfully build and submit to App Store by **February 18, 2026**

**Development Milestones**:
- Feb 3: Project setup complete ✓
- Feb 5: Auth + Paywall working ✓
- Feb 8: Quran reading functional ✓
- Feb 11: Listening sessions working ✓
- Feb 14: TestFlight build uploaded ✓
- Feb 18: App Store submission complete ✓

**Post-Launch Metrics** (tracked separately after release):
- Downloads, conversion rates, retention, revenue
- Not part of V1 development scope

---

## 2. PRODUCT SCOPE

### 2.1 In Scope (V1)

✅ **Authentication & Monetization**
- Sign in with Apple (ONLY - no Google for V1)
- RevenueCat subscription management
- Hard paywall (no free tier)
- Monthly subscription ($4.99/month, 3-day free trial)
- Yearly subscription ($29.99/year, 7-day free trial)
- Restore purchases functionality
- Subscription expiration handling (remove Screen Time shields when expired)

✅ **Onboarding**
- 4-screen survey:
  1. What brings you here? (motivation)
  2. When does your phone distract you most?
  3. What do you want more of?
  4. Social media time calculation → Quran time comparison
- Paywall presentation (after survey, before Screen Time permission)
- Screen Time API permission flow
- App selection and time limit setup

✅ **Core Features**
- **3-tab bottom navigation**: Quran, Blocking, Settings
- Quran reading (browse 114 surahs, search, read with translation)
- Listening sessions with focus mode (multiple surahs, reciter selection, app blocking during session)
- App blocking with daily time limits
- Time range scheduling (start/end times for blocking)
- **Streak tracking** (consecutive days of Quran engagement)
- Session history

✅ **Screen Time Integration**
- FamilyControls authorization
- App blocking via Shield
- Daily time limit enforcement
- Time range scheduling
- **Automatic shield removal on subscription expiration**

✅ **Audio Playback**
- Background audio support (continues when app backgrounded)
- Control Center integration
- Lock screen controls
- Auto-play next surah in queue

### 2.2 Out of Scope (V1)

❌ Google Sign In (Apple only for V1)  
❌ Cloud sync / Supabase backend (local-only SwiftData)  
❌ **Reward system** (no "earn unblock time by listening")  
❌ Continue Reading feature  
❌ Helper layer (add only if needed)  
❌ Verse-by-verse audio during reading  
❌ Advanced analytics/heatmaps  
❌ Social features/sharing  
❌ Prayer time integration  
❌ Tafsir (commentary)  
❌ Bookmarking specific ayahs  
❌ **Full offline mode** (text caching only, no audio downloads)  
❌ Speech recognition  
❌ Backup Quran APIs (single source only)

### 2.3 Future Considerations (V2+)
- Google Sign In option
- Cloud sync with Supabase (cross-device data sync)
- Full offline mode (download audio for offline listening)
- Verse-by-verse audio while reading
- Pronunciation feedback (speech recognition)
- Memorization tracking
- Community challenges
- Prayer time blocking
- Advanced reading analytics
- Social streak leaderboards
- Widgets (Today view, Lock Screen)

---

## 3. TECHNICAL ARCHITECTURE

### 3.1 Tech Stack
- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: Clean Architecture + MVVM
- **Database**: SwiftData (local persistence only, no cloud)
- **Authentication**: Sign in with Apple (native, no Google for V1)
- **Monetization**: RevenueCat SDK
- **Networking**: Alamofire (HTTP client)
- **Screen Time**: FamilyControls framework (iOS 16+)
- **Quran API**: QuranAPI.pages.dev (single source, no backups)
- **Audio**: AVFoundation (background playback)
- **Dependency Injection**: Custom DIContainer pattern

### 3.2 Architecture Layers

```
Presentation Layer (Views + ViewModels)
    ↓ calls
Domain Layer (Services + Entities)
    ↓ calls
Data Layer (Repositories + DataSources)
```

**Note**: Helper layer removed. Only add helper utilities if absolutely necessary during development.

### 3.3 Folder Structure
```
DeenFirst/Sources/
├── Core/
│   ├── DataDependency/DIContainer.swift
│   ├── Networking/HTTPClient.swift
│   └── SceneNavigation/Router.swift
├── Data/
│   ├── DataSource/
│   │   ├── LocalDataSource.swift
│   │   └── QuranAPIDataSource.swift
│   └── Repositories/
│       ├── QuranRepository.swift
│       ├── ScreenTimeRepository.swift
│       ├── UserRepository.swift
│       └── SessionRepository.swift
├── Domain/
│   ├── Entities/
│   │   ├── surah.swift
│   │   ├── ayah.swift
│   │   ├── reciter.swift
│   │   ├── user.swift
│   │   ├── session.swift
│   │   ├── blocked_app.swift
│   │   └── app_time_limit.swift
│   └── Services/
│       ├── QuranService.swift
│       ├── ScreenTimeService.swift
│       ├── SessionService.swift
│       ├── SubscriptionService.swift
│       └── AuthService.swift
├── Presentation/
│   ├── Components/
│   │   ├── CustomButton.swift
│   │   ├── SurahCard.swift
│   │   ├── AyahCard.swift
│   │   ├── ReciterPicker.swift
│   │   ├── StreakBadge.swift
│   │   └── AudioPlayerControls.swift
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── SurveyView.swift
│   │   └── OnboardingViewmodel.swift
│   ├── Paywall/
│   │   ├── PaywallView.swift
│   │   └── PaywallViewmodel.swift
│   ├── Auth/
│   │   ├── AuthView.swift
│   │   └── AuthViewmodel.swift
│   ├── MainTabs/
│   │   ├── MainTabView.swift
│   │   ├── QuranTab/
│   │   │   ├── QuranTabView.swift
│   │   │   ├── SurahListView.swift
│   │   │   ├── SurahDetailView.swift
│   │   │   └── QuranTabViewmodel.swift
│   │   ├── BlockingTab/
│   │   │   ├── BlockingTabView.swift
│   │   │   ├── AppBlockSettingsView.swift
│   │   │   └── BlockingTabViewmodel.swift
│   │   └── SettingsTab/
│   │       ├── SettingsTabView.swift
│   │       └── SettingsTabViewmodel.swift
│   └── ListenSession/
│       ├── ListenSessionView.swift
│       └── ListenSessionViewmodel.swift
├── Utils/
│   └── Extensions.swift
├── RootView.swift
└── DeenFirstApp.swift
```

---

## 4. API INTEGRATION

### 4.1 QuranAPI.pages.dev (Primary and Only)

**Base URL**: `https://quranapi.pages.dev/api`

**Documentation**: https://quranapi.pages.dev/introduction

**Key Endpoints:**

#### Text Content:
```
GET /surah - List all 114 surahs
GET /surah/{number} - Get specific surah details with verses
GET /surah/{number}?lang=en - Get surah with English translation
```

**Example Response** (`GET /surah/1`):
```json
{
  "number": 1,
  "name": "الفاتحة",
  "englishName": "Al-Fatihah",
  "englishNameTranslation": "The Opening",
  "revelationType": "Meccan",
  "numberOfAyahs": 7,
  "ayahs": [
    {
      "number": 1,
      "text": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
      "numberInSurah": 1
    }
  ]
}
```

#### Audio Recitation:
```
GET /surah/{number}/audio/{reciter_id} - Get audio URL for specific reciter
```

**Example** (`GET /surah/1/audio/7`):
```json
{
  "audioUrl": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3"
}
```

**Available Reciters** (from QuranAPI.pages.dev):
- ID 7: Mishary Rashid Alafasy (default)
- ID 2: Abdul Basit Abdul Samad  
- ID 5: Saad Al-Ghamdi
- ID 3: Abu Bakr Al-Shatri
- ID 1: Hani Ar-Rifai

**Advantages:**
- Simple, clean API design
- No authentication required
- No rate limits
- Fast response times
- Arabic text + multiple translations in single request
- Audio URLs provided per reciter
- Single source for both text and audio

### 4.2 Caching Strategy

**What Gets Cached (SwiftData)**:

**Surah List** (metadata):
- ✅ Cache indefinitely (static data)
- Fetch once on first app launch
- Store in SwiftData
- Size: ~50KB

**Surah Content** (text + translation):
- ✅ Cache for 30 days
- Fetch on-demand when user opens surah
- Store in SwiftData with expiry timestamp
- Size: ~10-50KB per surah

**What Does NOT Get Cached**:

**Audio Files**:
- ❌ NO caching (streaming only)
- Audio URLs fetched from API
- Stream directly using AVPlayer
- Reason: Too large (5-30MB per surah)
- For full offline mode, defer to V2

**Cache Behavior**:
```
User previously read Surah Al-Fatihah WITH internet
    ↓
Text cached locally
    ↓
User opens app WITHOUT internet
    ↓
Can read Al-Fatihah (from cache) ✅
Cannot read NEW surahs (needs API) ❌
Cannot listen to audio (needs internet for streaming) ❌
```

**For V2: Full Offline Mode**
- Allow downloading surahs + audio while online
- Play from local storage when offline

### 4.3 Error Handling

**Network Issues**:
- Timeout: 30 seconds (Alamofire built-in)
- Retry logic: 3 attempts with exponential backoff (Alamofire RetryPolicy)
- Fallback to cached data if available
- Show user-friendly error: "Unable to load. Check your connection."

**API Errors**:
- 404: Show "Surah not found"
- 500: Show "Server error. Try again later."
- No network: Show cached content if available

---

## 5. SUBSCRIPTION MANAGEMENT

### 5.1 Subscription Lifecycle

**Free Trial**:
```
User subscribes (Monthly)
    ↓
Day 1-3: FREE TRIAL (no charge)
    ↓
Day 4: First charge ($4.99)
    ↓
Every 30 days: Auto-renew ($4.99)
```

**Yearly**:
```
User subscribes (Yearly)
    ↓
Day 1-7: FREE TRIAL (no charge)
    ↓
Day 8: First charge ($29.99)
    ↓
Every 365 days: Auto-renew ($29.99)
```

### 5.2 What Happens After Subscription Expires

**Scenario: User doesn't renew after 30 days**

```
Day 30: Subscription expires (no payment)
    ↓
RevenueCat webhook fires
    ↓
Next time user opens app:
    ├─ 1. Check subscription status
    │   Purchases.shared.customerInfo()
    │   → isPremium = false
    │
    ├─ 2. Update local user record
    │   User.isPremium = false
    │   User.subscriptionExpiryDate = nil
    │
    ├─ 3. REMOVE ALL SCREEN TIME SHIELDS
    │   ManagedSettingsStore.shield.applications = nil
    │   → Instagram, TikTok, etc. become accessible
    │
    └─ 4. Show Paywall
        "Your subscription has expired"
        "Resubscribe to continue"
        [Renew Subscription Button]
        [Restore Purchases Button]
```

**Critical Implementation**:

```swift
// In RootView or App startup
func checkSubscriptionStatus() async {
    let customerInfo = try await Purchases.shared.customerInfo()
    let isPremium = customerInfo.entitlements["premium"]?.isActive == true
    
    // Update local user
    if var user = try userRepo.getCurrentUser() {
        user.isPremium = isPremium
        user.subscriptionExpiryDate = customerInfo.entitlements["premium"]?.expirationDate
        try await userRepo.updateUser(user)
        
        if !isPremium {
            // CRITICAL: Remove all Screen Time shields
            try await screenTimeService.removeAllShields()
        }
    }
    
    // Navigate based on status
    if !isPremium {
        router.navigate(to: .paywall)
    } else {
        router.navigate(to: .mainTabs)
    }
}
```

**ScreenTimeService.removeAllShields()**:
```swift
func removeAllShields() async throws {
    let store = ManagedSettingsStore()
    
    // Remove ALL shields
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    
    // Clear active session
    try await screenTimeRepo.clearActiveSession()
    
    // User's blocked apps list remains in SwiftData
    // (so when they resubscribe, settings are preserved)
}
```

### 5.3 Edge Case: Subscription Expires Mid-Session

```
User is listening to Quran (active session)
    ↓
Subscription expires (exactly at that moment)
    ↓
Session CONTINUES (don't interrupt mid-Quran)
    ↓
Session ends
    ↓
Check subscription status
    ↓
If expired:
    → Remove all shields
    → Show paywall
    → User must resubscribe
```

### 5.4 Restore Purchases Flow

```
User previously subscribed
User deleted app
User reinstalls app
    ↓
User signs in with Apple
    ↓
Taps "Restore Purchases" on paywall
    ↓
RevenueCat checks Apple:
    "Does this Apple ID have active subscription?"
    ↓
If YES:
    → Update User.isPremium = true
    → Navigate to main tabs
    → User gets full access
    ↓
If NO:
    → Show "No active subscription found"
    → User must purchase new subscription
```

---

## 6. FEATURE SPECIFICATIONS

### 6.1 Authentication

#### 6.1.1 Sign In with Apple

**User Story**: As a new user, I want to sign in quickly using my Apple ID so I can start using the app.

**Acceptance Criteria:**
- Display "Sign in with Apple" button (iOS guidelines compliant)
- Successful auth creates user record in local database (SwiftData)
- Store user ID, email, name from Apple
- Link user ID to RevenueCat for subscription tracking
- Auto-navigate to onboarding survey after first sign-in
- Auto-navigate to main tabs if returning subscribed user
- Auto-navigate to Paywall if returning user without subscription

**Technical Implementation:**

**Entity**: `user.swift`
```swift
@Model
class User {
    @Attribute(.unique) var id: String // Apple User ID
    var authProvider: String // "apple"
    var email: String
    var name: String
    var createdAt: Date
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var subscriptionExpiryDate: Date?
    
    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastEngagementDate: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var sessions: [Session]?
    @Relationship(deleteRule: .cascade) var blockedApps: [BlockedApp]?
    @Relationship(deleteRule: .cascade) var appTimeLimits: [AppTimeLimit]?
    
    init(id: String, email: String, name: String) {
        self.id = id
        self.authProvider = "apple"
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.hasCompletedOnboarding = false
        self.isPremium = false
        self.currentStreak = 0
        self.longestStreak = 0
    }
}
```

**Service**: `AuthService.swift`
```swift
protocol AuthService {
    func signInWithApple() async throws -> User
    func getCurrentUser() throws -> User?
    func signOut() throws
}
```

**Navigation Logic**:
```swift
func handleSignInSuccess(_ user: User) async {
    // Check subscription first
    let isPremium = try await subscriptionService.checkSubscriptionStatus()
    
    if !user.hasCompletedOnboarding {
        router.navigate(to: .onboarding)
    } else if !isPremium {
        router.navigate(to: .paywall)
    } else {
        router.navigate(to: .mainTabs)
    }
}
```

---

### 6.2 Onboarding Survey (4 Screens)

**User Story**: As a new user, I want to share my motivation and see how much time I could spend on Quran instead of social media.

**Flow**: Welcome → Survey 1 → Survey 2 → Survey 3 → Survey 4 → Paywall

#### Screen 1: What brings you here?

**Options** (multi-select):
- I want more consistency with Quran
- I get distracted too easily
- I want a simple daily routine
- I need help focusing
- I want to reconnect with my faith
- Other (text input)

#### Screen 2: When does your phone distract you most?

**Options** (multi-select):
- Late at night
- When I feel overwhelmed
- Throughout the day
- When I feel stressed
- For a minute (turns into hours)

#### Screen 3: What do you want more of?

**Options** (multi-select):
- More consistency with the Quran
- More presence and focus
- Better phone habits

#### Screen 4: Time Calculation & Comparison

**Display**:
```
Based on average usage:

You spend ~2.5 hours daily on social media

That's enough time to:
• Read 5 surahs of the Quran
• Complete 30 minutes of focused work
• Have meaningful conversations

Let's create space for what matters 🌙
```

**Note**: Use average Gen Z social media usage (~2-3 hours/day) for V1. In V2, integrate with actual Screen Time data.

**UI**: 
- Progress indicator (1/4, 2/4, 3/4, 4/4)
- "Continue" button (enabled when selection made)
- "Skip" button (only on screens 1-3, not on screen 4)

**Data Storage**:
- Survey responses saved to user profile (optional analytics for V2)
- For V1: Just validate user saw the flow, no need to process responses

---

### 6.3 Paywall

**User Story**: As a new user, I must subscribe to access the app features, with a free trial option.

**When Shown**:
- After onboarding survey (first-time users)
- On app launch if returning user without active subscription
- When subscription expires

**Layout**:

**Header**:
- App icon
- "Unlock Your Quran Journey"
- "Start your free trial, cancel anytime"

**Features** (comparison):
- ✅ Block distracting apps
- ✅ Read Quran with translations
- ✅ Listen to beautiful recitations
- ✅ Track your daily streak
- ✅ Set time limits & schedules
- ✅ Build a daily Quran habit

**Subscription Options**:

**Yearly** (Recommended badge):
- $29.99/year
- 7-day free trial
- "Save 50% vs monthly"
- Selected by default

**Monthly**:
- $4.99/month
- 3-day free trial

**CTA Button**:
- "Start 7-Day Free Trial" (if yearly selected)
- "Start 3-Day Free Trial" (if monthly selected)

**Footer Links**:
- "Restore Purchases"
- "Terms of Service"
- "Privacy Policy"

**Technical Implementation**:

**ViewModel**: `PaywallViewmodel.swift`
```swift
@MainActor
final class PaywallViewmodel: ObservableObject {
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let subscriptionService: SubscriptionService
    
    func subscribe() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let success = selectedPlan == .yearly 
                ? try await subscriptionService.purchaseYearly()
                : try await subscriptionService.purchaseMonthly()
            
            if success {
                router.navigate(to: .screenTimePermission)
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let success = try await subscriptionService.restorePurchases()
            
            if success {
                // Check if user completed onboarding
                if let user = try userRepo.getCurrentUser(), 
                   user.hasCompletedOnboarding {
                    router.navigate(to: .mainTabs)
                } else {
                    router.navigate(to: .screenTimePermission)
                }
            } else {
                errorMessage = "No active subscription found"
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
    }
}
```

---

### 6.4 Screen Time Permission & Setup

#### 6.4.1 Request Permission

**User Story**: After subscribing, I need to grant Screen Time permission to enable app blocking.

**Screen**:
- Explanation: "To block distracting apps, we need Screen Time permission"
- Visual: Screenshot or illustration showing the permission dialog
- Button: "Grant Permission"

**Flow**:
```swift
func requestPermission() async {
    do {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        // Permission granted
        router.navigate(to: .setupBlockedApps)
    } catch {
        // Permission denied
        showAlert("Screen Time permission is required for Deen First to work. You can enable it in Settings.")
    }
}
```

**If Permission Denied**:
- Show alert with "Open Settings" button
- Deep link: UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)

#### 6.4.2 App Selection & Time Limits

**Screen 1: Select Apps to Block**

**Title**: "Let's start simple, which app distracts you the most?"
**Subtitle**: "You can select more apps or edit this later"

**UI**:
- FamilyActivityPicker (native iOS selector)
- Shows all installed apps with icons
- Multi-select enabled

**Save to SwiftData**:
```swift
// Save each selected app
for app in selectedApps {
    let blockedApp = BlockedApp(
        userId: user.id,
        appBundleId: app.bundleIdentifier,
        appName: app.displayName,
        appToken: app.token.encode()
    )
    try await screenTimeRepo.saveBlockedApp(blockedApp)
}
```

**Screen 2: Set Time Limits**

**Title**: "What's the most time you want to spend on this app each day?"

**For Each Selected App**:
- App icon + name
- Time selector: 15 min, 30 min, 45 min, 1 hour, 2 hours, 3 hours, 4 hours
- Default: 1 hour

**Save to SwiftData**:
```swift
for app in selectedApps {
    let limit = AppTimeLimit(
        userId: user.id,
        appBundleId: app.bundleIdentifier,
        appName: app.displayName,
        limitMinutes: selectedMinutes // e.g., 60
    )
    try await screenTimeRepo.saveAppLimit(limit)
}
```

**Navigation**:
- Setup Complete → Navigate to MainTabView (Quran tab selected)

---

### 6.5 Main Navigation (3-Tab Bottom Bar)

**User Story**: As a user, I want easy access to reading Quran, managing app limits, and viewing my settings.

**Structure**:

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QuranTabView()
                .tabItem {
                    Label("Quran", systemImage: "book")
                }
                .tag(0)
            
            BlockingTabView()
                .tabItem {
                    Label("Blocking", systemImage: "lock.shield")
                }
                .tag(1)
            
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}
```

---

### 6.6 Tab 1: Quran (Reading & Listening)

**Layout**:

**Top Section**:
- User greeting: "As-salamu alaykum, [Name]"
- Streak badge (if currentStreak > 0):
  ```
  🔥 7 Day Streak
  Keep it going! Longest: 12 days
  ```

**Search Bar**:
- Search by surah name (Arabic or English) or number

**Surah List** (scrollable):
- Surah card for each:
  - Number (in circle)
  - Arabic name + English transliteration
  - Revelation type + verse count
  - Tap → Navigate to reading view

**Floating Action Button** (bottom-right):
- Icon: 🎧
- Text: "Start Listening"
- Tap → Navigate to ListenSessionView

**Implementation**:

```swift
@MainActor
final class QuranTabViewmodel: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var filteredSurahs: [Surah] = []
    @Published var searchText: String = ""
    @Published var user: User?
    @Published var isLoading: Bool = true
    
    private let quranService: QuranService
    private let userRepo: UserRepository
    
    func load() async {
        user = try userRepo.getCurrentUser()
        surahs = try await quranService.getAllSurahs()
        filteredSurahs = surahs
        isLoading = false
    }
    
    func search() {
        if searchText.isEmpty {
            filteredSurahs = surahs
        } else {
            filteredSurahs = surahs.filter { surah in
                surah.englishName.lowercased().contains(searchText.lowercased()) ||
                surah.name.contains(searchText) ||
                "\(surah.number)".contains(searchText)
            }
        }
    }
}
```

#### 6.6.1 Surah Reading View

**User Story**: I want to read a surah with Arabic text and English translation, verse by verse.

**UI**:
- Header: Surah name, back button, settings icon
- Bismillah (if not Surah 9)
- Scrollable verses:
  - Verse number (in circle)
  - Arabic text (large, Uthmani font)
  - English translation (smaller, below Arabic)
  - Spacing between verses

**Session Tracking**:
- Start tracking when view appears
- Track duration (time spent reading)
- Save session on view disappear (engagement counts immediately)
- Update streak if new day

**Implementation**:
```swift
@MainActor
final class SurahDetailViewmodel: ObservableObject {
    @Published var surah: Surah?
    @Published var ayahs: [Ayah] = []
    @Published var isLoading: Bool = true
    
    private var sessionStartTime: Date?
    private let quranService: QuranService
    private let sessionService: SessionService
    
    func load(surahId: Int) async {
        sessionStartTime = Date()
        surah = try await quranService.getSurahById(id: surahId, translation: "en")
        ayahs = surah?.ayahs ?? []
        isLoading = false
    }
    
    func saveSession() async {
        guard let startTime = sessionStartTime,
              let surah = surah else { return }

        let duration = Int(Date().timeIntervalSince(startTime))

        // Engagement counts immediately - no minimum time required

        let session = Session(
            userId: user.id,
            sessionType: "read",
            surahNumber: surah.number,
            durationSeconds: duration
        )

        try await sessionService.createSession(session)
    }
    
    deinit {
        Task { await saveSession() }
    }
}
```

---

### 6.7 Listening Session

**User Story**: I want to listen to Quran recitation with my distracting apps blocked during the session.

**Flow**: Setup → Active Session → Complete

#### 6.7.1 Setup Screen

**Title**: "Your Focus Session"

**Selections**:

1. **Select Surah(s)** (required)
   - Tap to open multi-select sheet
   - List of all 114 surahs with checkboxes
   - User can select 1+ surahs
   - Display: "3 surahs selected" or "Al-Fatihah, Al-Baqarah, +1 more"

2. **Select Reciter** (default from Settings)
   - Display: Reciter name from Settings
   - Tap to navigate to Settings (or note that it's configured in Settings)
   - Note: Reciter selection is now in Settings tab, not here

3. **Block Apps During Session** (pre-populated)
   - Display: "Instagram, TikTok, +2 more" (apps selected during onboarding)
   - Tap to change selection (opens FamilyActivityPicker)
   - These apps will be blocked ONLY during the session

**Button**: "Start Session" (enabled when at least 1 surah selected)

**Load Default Values**:
```swift
func loadDefaults() async {
    // Load blocked apps from onboarding
    selectedApps = try await screenTimeService.getBlockedApps(userId: user.id)

    // Load reciter from Settings (not UserDefaults)
    selectedReciter = user.preferredReciter ?? .default

    // Load last selected surahs (or empty)
    if let surahNumbers = UserDefaults.standard.array(forKey: "lastSelectedSurahs") as? [Int] {
        selectedSurahs = surahs.filter { surahNumbers.contains($0.number) }
    }
}
```

**Note**: Reciter selection is now managed in Settings tab (see section 6.9)

#### 6.7.2 Start Session (SAVE PREFERENCES HERE)

**Critical**: Save preferences IMMEDIATELY when user taps "Start Session", NOT at end.

```swift
func startSession() async {
    // STEP 1: SAVE PREFERENCES FIRST (before audio starts)
    UserDefaults.standard.set(selectedSurahs.map(\.number), forKey: "lastSelectedSurahs")
    // Note: Reciter is saved in Settings, not here

    // STEP 2: Apply Shield to selected apps
    try await screenTimeService.startBlockingSession(
        appTokens: selectedApps.map { ApplicationToken(data: $0.appToken) }
    )

    // STEP 3: Fetch audio URL for first surah
    let audioResponse = try await quranService.getAudioURL(
        surahNumber: selectedSurahs[0].number,
        reciterId: selectedReciter.id
    )

    // STEP 4: Load and play audio
    audioPlayer.loadAudio(url: audioResponse.audioUrl)
    audioPlayer.play()

    // STEP 5: Start timer
    startTimer()

    // STEP 6: Update UI
    isSessionActive = true
    currentSurah = selectedSurahs[0]
    currentSurahIndex = 0
}
```

**Why save on START?**
- If user closes app mid-session, preferences are already saved
- Next time they open listening setup, defaults are pre-filled
- More reliable than saving on end (which might not happen)

#### 6.7.3 Active Session Screen

**UI**:
- Current surah name (large): "Surah Al-Baqarah"
- Reciter name (small): "Mishary Rashid Alafasy"
- Timer: "12:34" (MM:SS)
- Progress: "2 / 3 surahs" (if multiple)
- Audio controls:
  - Play/Pause button (center, large)
  - Skip to next surah (if multiple surahs in queue)
- "End Session" button (bottom, secondary color)

**Background Audio**:
```swift
// Configured in AudioPlayerHelper
func setupAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        // Enable background audio
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
    } catch {
        print("Failed to configure audio session: \(error)")
    }
}
```

**Info.plist**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Control Center Integration**:
```swift
func updateNowPlayingInfo() {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = currentSurah.englishName
    nowPlayingInfo[MPMediaItemPropertyArtist] = selectedReciter.name
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.isPlaying ? 1.0 : 0.0
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}
```

**Auto-Play Next Surah**:
```swift
// When current surah finishes
@objc func playerDidFinishPlaying() {
    currentSurahIndex += 1
    
    if currentSurahIndex < selectedSurahs.count {
        // Play next surah
        let nextSurah = selectedSurahs[currentSurahIndex]
        currentSurah = nextSurah
        
        Task {
            let audioResponse = try await quranService.getAudioURL(
                surahNumber: nextSurah.number,
                reciterId: selectedReciter.id
            )
            audioPlayer.loadAudio(url: audioResponse.audioUrl)
            audioPlayer.play()
        }
    } else {
        // All surahs finished
        await endSession()
    }
}
```

#### 6.7.4 End Session

**Trigger**:
- User taps "End Session"
- All surahs finish playing

**Actions**:
```swift
func endSession() async {
    // 1. Stop audio
    audioPlayer.stop()
    
    // 2. Check subscription status FIRST
    let isPremium = try await subscriptionService.checkSubscriptionStatus()
    
    if isPremium {
        // 2a. Normal flow: Remove session shield
        try await screenTimeService.endBlockingSession()
        
        // 3. Save session
        let session = Session(
            userId: user.id,
            sessionType: "listen",
            surahNumber: selectedSurahs.first!.number,
            durationSeconds: elapsedSeconds,
            reciterId: selectedReciter.id
        )
        try await sessionService.createSession(session)
        
        // 4. Navigate back
        router.navigateBack()
        showSuccessMessage("Session completed! 🎧")
    } else {
        // 2b. Subscription expired: Remove ALL shields, show paywall
        try await screenTimeService.removeAllShields()
        router.navigate(to: .paywall)
        showAlert("Your subscription has expired. Resubscribe to continue.")
    }
}
```

**Note**: Preferences already saved at START, so no need to save again here.

---

### 6.8 Tab 2: Blocking (App Limits)

**User Story**: I want to manage my blocked apps and set time limits.

**Layout**:

**Title**: "App Limits"

**List of Blocked Apps**:

For each app:
```
┌─────────────────────────────────┐
│ [App Icon] Instagram            │
│ Daily Limit: 30 minutes         │
│ Schedule: All day               │
│ [Edit] [Remove]                 │
└─────────────────────────────────┘
```

**Add More Apps** button (bottom)

**Tap "Edit"** → Show modal:
- Daily limit picker: 15 min, 30 min, 45 min, 1 hr, 2 hr, 3 hr, 4 hr
- Schedule toggle:
  - "All day" (default)
  - OR "Custom time range":
    - Start time: 9:00 AM
    - End time: 11:00 PM
- Save button

**Implementation**:

**Entity**: `app_time_limit.swift`
```swift
@Model
class AppTimeLimit {
    @Attribute(.unique) var id: String
    var userId: String
    var appBundleId: String
    var appName: String
    var limitMinutes: Int
    var scheduleType: String // "allDay" | "timeRange"
    var startTime: Date?
    var endTime: Date?
    var isEnabled: Bool
    
    init(id: String = UUID().uuidString, userId: String, appBundleId: String, appName: String, limitMinutes: Int) {
        self.id = id
        self.userId = userId
        self.appBundleId = appBundleId
        self.appName = appName
        self.limitMinutes = limitMinutes
        self.scheduleType = "allDay"
        self.isEnabled = true
    }
}
```

**How Limits Work**:

**All Day**:
- Shield applied 24/7
- User can access app until daily limit reached
- At midnight, usage counter resets

**Time Range**:
- Shield applied only during specified hours (e.g., 9 AM - 11 PM)
- Outside this range, app is accessible regardless of usage

**CRITICAL**: No way to unlock apps before limit resets or time range ends. Listening to Quran does NOT earn unblock time.

---

### 6.9 Tab 3: Settings/Profile

**User Story**: I want to view my profile, manage subscription, and configure preferences.

**Layout**:

**Profile Section**:
- Profile circle (first letter of name)
- Name
- Email
- Premium badge: "Premium Member ✓"

**Subscription Section**:
- Current plan: "Yearly - $29.99/year"
- Status: "Active" (green) or "Expired" (red)
- Expiry/Renewal date: "Renews on March 15, 2026"
- Button: "Manage Subscription" → Opens App Store subscriptions

**Preferences**:
- Translation: English (Sahih International) - tap to change
- Default Reciter: Mishary Alafasy - tap to change
  - Options from QuranAPI.pages.dev:
    - Mishary Rashid Alafasy (ID 7, default)
    - Abu Bakr Al-Shatri (ID 3)
    - Abdul Basit Abdul Samad (ID 2)
    - Saad Al-Ghamdi (ID 5)
  - Saved to User.preferredReciter (SwiftData)
  - Used by listening sessions

**Support**:
- Help & FAQ → Opens help page
- Contact Support → mailto: support@deenfirst.com
- Rate the App → Deep link to App Store

**Account**:
- Sign Out → Confirmation dialog
- Delete Account → Warning dialog with confirmation

**Implementation**:
```swift
@MainActor
final class SettingsTabViewmodel: ObservableObject {
    @Published var user: User?
    @Published var subscriptionStatus: String = ""
    @Published var renewalDate: String = ""
    
    func load() async {
        user = try userRepo.getCurrentUser()
        await loadSubscriptionInfo()
    }
    
    func loadSubscriptionInfo() async {
        let customerInfo = try await Purchases.shared.customerInfo()
        
        if let entitlement = customerInfo.entitlements["premium"],
           entitlement.isActive {
            subscriptionStatus = "Active"
            if let expiry = entitlement.expirationDate {
                renewalDate = "Renews on \(expiry.formatted(date: .long, time: .omitted))"
            }
        } else {
            subscriptionStatus = "Expired"
            renewalDate = ""
        }
    }
    
    func signOut() {
        // Show confirmation
        showConfirmation("Are you sure you want to sign out?") {
            try authService.signOut()
            router.replaceNavigationPath(with: [.auth])
        }
    }
    
    func deleteAccount() {
        // Show warning
        showConfirmation("Delete account? This cannot be undone.") {
            try await userRepo.deleteUser(id: user.id)
            try authService.signOut()
            router.replaceNavigationPath(with: [.auth])
        }
    }
}
```

---

### 6.10 Streak Tracking

**User Story**: I want to build a daily Quran habit and see my consecutive days streak.

**What Counts as Engagement**:
- ✅ Opening and reading any surah (engagement starts immediately)
- ✅ Starting a listening session
- ✅ Either activity counts for that day (only need one)
- ✅ **No minimum time requirement** - engagement counts from the moment user opens a surah or starts listening

**What Breaks the Streak**:
- ❌ Missing a full day (no read or listen session)

**Streak Logic**:

```swift
func updateStreak(after session: Session) async {
    // Engagement counts immediately - no minimum time required
    guard var user = try userRepo.getUserById(session.userId) else { return }

    let today = Calendar.current.startOfDay(for: Date())

    guard let lastEngagement = user.lastEngagementDate else {
        // First ever engagement
        user.currentStreak = 1
        user.longestStreak = 1
        user.lastEngagementDate = today
        try await userRepo.updateUser(user)
        return
    }

    let lastDay = Calendar.current.startOfDay(for: lastEngagement)

    if Calendar.current.isDate(today, equalTo: lastDay, toGranularity: .day) {
        // Already engaged today, don't increment
        return
    } else if Calendar.current.isDate(today, inSameDayAs: lastEngagement.addingTimeInterval(86400)) {
        // Yesterday → today (consecutive)
        user.currentStreak += 1
        if user.currentStreak > user.longestStreak {
            user.longestStreak = user.currentStreak
        }
    } else {
        // Missed one or more days, reset
        user.currentStreak = 1
    }

    user.lastEngagementDate = today
    try await userRepo.updateUser(user)
}
```

**Display**:

**Quran Tab (top section)**:
```
🔥 7 Day Streak
Keep it going! Longest: 12 days
```

**Settings Tab (optional)**:
- Show current streak prominently
- Show longest streak
- V2: Calendar view showing engagement days

---

## 7. DATA MODELS

### 7.1 SwiftData Entities

```swift
@Model
class User {
    @Attribute(.unique) var id: String
    var authProvider: String // "apple"
    var email: String
    var name: String
    var createdAt: Date
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var subscriptionExpiryDate: Date?
    
    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastEngagementDate: Date?
    
    @Relationship(deleteRule: .cascade) var sessions: [Session]?
    @Relationship(deleteRule: .cascade) var blockedApps: [BlockedApp]?
    @Relationship(deleteRule: .cascade) var appTimeLimits: [AppTimeLimit]?
    
    init(id: String, email: String, name: String) {
        self.id = id
        self.authProvider = "apple"
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.hasCompletedOnboarding = false
        self.isPremium = false
        self.currentStreak = 0
        self.longestStreak = 0
    }
}

@Model
class Session {
    @Attribute(.unique) var id: String
    var userId: String
    var sessionType: String // "read" | "listen"
    var surahNumber: Int
    var durationSeconds: Int
    var reciterId: Int?
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, sessionType: String, surahNumber: Int, durationSeconds: Int) {
        self.id = id
        self.userId = userId
        self.sessionType = sessionType
        self.surahNumber = surahNumber
        self.durationSeconds = durationSeconds
        self.isCompleted = true
        self.createdAt = Date()
    }
}

@Model
class BlockedApp {
    @Attribute(.unique) var id: String
    var userId: String
    var appBundleId: String
    var appName: String
    var appToken: Data
    var addedAt: Date
}

@Model
class AppTimeLimit {
    @Attribute(.unique) var id: String
    var userId: String
    var appBundleId: String
    var appName: String
    var limitMinutes: Int
    var scheduleType: String // "allDay" | "timeRange"
    var startTime: Date?
    var endTime: Date?
    var isEnabled: Bool
}
```

### 7.2 API Response Models

```swift
struct Surah: Codable, Identifiable {
    var id: Int { number }
    var number: Int
    var name: String
    var englishName: String
    var englishNameTranslation: String
    var revelationType: String
    var numberOfAyahs: Int
    var ayahs: [Ayah]?
}

struct Ayah: Codable, Identifiable {
    var id: Int { number }
    var number: Int
    var text: String
    var numberInSurah: Int
    var translation: String?
}

struct Reciter: Codable, Identifiable {
    var id: Int
    var name: String
    
    static let misharyAlafasy = Reciter(id: 7, name: "Mishary Rashid Alafasy")
    static let abdulBasit = Reciter(id: 2, name: "Abdul Basit Abdul Samad")
    static let saadAlGhamdi = Reciter(id: 5, name: "Saad Al-Ghamdi")
    static let abuBakr = Reciter(id: 3, name: "Abu Bakr Al-Shatri")
    
    static let `default` = misharyAlafasy
    
    static let available = [misharyAlafasy, abdulBasit, saadAlGhamdi, abuBakr]
}

struct AudioResponse: Codable {
    var audioUrl: URL
}
```

---

## 8. NAVIGATION ROUTING

### 8.1 Router Configuration

```swift
class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    enum Route: Hashable {
        case auth
        case onboarding
        case paywall
        case screenTimePermission
        case setupBlockedApps
        case mainTabs
        case surahDetail(surahId: Int)
        case listenSession
    }
    
    func navigate(to route: Route) {
        navigationPath.append(route)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func replaceNavigationPath(with routes: [Route]) {
        navigationPath = NavigationPath()
        routes.forEach { navigationPath.append($0) }
    }
}
```

### 8.2 Navigation Flows

**First-Time User**:
```
Auth → Onboarding Survey (4 screens) → Paywall → Screen Time Permission → Setup Blocked Apps → MainTabs (Quran tab)
```

**Returning User (Subscribed)**:
```
Auth → (check subscription) → MainTabs (Quran tab)
```

**Returning User (No Subscription)**:
```
Auth → Paywall
```

**Subscription Expired**:
```
Any Screen → (subscription check fails) → Remove shields → Paywall
```

---

## 9. DEPENDENCIES

### 9.1 Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.57.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0")
]
```

### 9.2 Native Frameworks
- SwiftUI (iOS 17+)
- SwiftData (iOS 17+)
- FamilyControls (iOS 16+)
- ManagedSettings (iOS 16+)
- DeviceActivity (iOS 16+)
- AuthenticationServices (Sign in with Apple)
- AVFoundation (Audio playback)
- MediaPlayer (Now Playing info)

### 9.3 Info.plist Additions

```xml
<key>NSFamilyControlsUsageDescription</key>
<string>Deen First needs permission to block distracting apps during your Quran focus sessions.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<key>NSUserTrackingUsageDescription</key>
<string>We use analytics to improve your experience.</string>
```

### 9.4 RevenueCat Setup

**1. Create Account**: https://www.revenuecat.com

**2. Configure Products**:
- Product ID: `com.aydev.deenfirst.monthly` ($4.99, 3-day trial)
- Product ID: `com.aydev.deenfirst.yearly` ($29.99, 7-day trial)

**3. Configure Entitlements**:
- Entitlement ID: `premium`
- Attached to both products

**4. Initialize in App**:
```swift
// In DeenFirstApp.swift
import RevenueCat

@main
struct DeenFirstApp: App {
    init() {
        Purchases.configure(withAPIKey: "your_revenuecat_api_key")
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

---

## 10. TIMELINE

### 10.1 Development Sprint (16 days: Feb 3-18)

**Phase 1: Infrastructure (Feb 3, Day 1)**
- ✅ Setup Xcode project
- ✅ Configure SwiftData model container
- ✅ Install RevenueCat SDK
- ✅ Create all entity files
- ✅ Setup DIContainer skeleton
- ✅ Create Router

**Phase 2: Auth + Onboarding (Feb 4-5, Days 2-3)**
- ✅ Implement Sign in with Apple
- ✅ Build 4 survey screens
- ✅ Build paywall screen
- ✅ Integrate RevenueCat (purchase + restore)
- ✅ Test subscription flow end-to-end

**Phase 3: Screen Time Setup (Feb 6, Day 4)**
- ✅ Implement Screen Time permission flow
- ✅ Build app selection screen
- ✅ Build time limit configuration screen
- ✅ Test Shield configuration

**Phase 4: Main Tabs + Quran Reading (Feb 7-8, Days 5-6)**
- ✅ Build MainTabView (3 tabs)
- ✅ Integrate QuranAPI.pages.dev
- ✅ Implement QuranService + Repository
- ✅ Build Quran tab (surah list + search)
- ✅ Build surah reading view
- ✅ Test caching strategy

**Phase 5: Listening Sessions (Feb 9-10, Days 7-8)**
- ✅ Implement audio player (AVFoundation + background)
- ✅ Build listening setup screen
- ✅ Build active session screen
- ✅ Implement multi-surah playback
- ✅ Test blocking during session
- ✅ Save preferences on START

**Phase 6: Blocking + Settings (Feb 11, Day 9)**
- ✅ Build blocking tab (app limits management)
- ✅ Build settings tab (profile, subscription, preferences)
- ✅ Implement subscription expiration handling
- ✅ Test shield removal on expiration

**Phase 7: Streak + Integration (Feb 12, Day 10)**
- ✅ Implement streak tracking logic
- ✅ Display streak on Quran tab
- ✅ Test session saving
- ✅ Test all navigation flows

**Phase 8: Polish (Feb 13-14, Days 11-12)**
- ✅ Fix all critical bugs
- ✅ Polish UI (colors, spacing, fonts, animations)
- ✅ Add loading states everywhere
- ✅ Add error messages
- ✅ Test on multiple devices

**Phase 9: TestFlight (Feb 15, Day 13)**
- ✅ Create App Store listing
- ✅ Prepare screenshots (6 screens)
- ✅ Upload to TestFlight
- ✅ Internal testing (fix critical bugs)

**Phase 10: Buffer (Feb 16-17, Days 14-15)**
- ✅ Fix bugs from TestFlight
- ✅ Final polish
- ✅ Prepare submission materials

**Phase 11: Submission (Feb 18, Day 16)**
- ✅ Submit to App Store
- ✅ Monitor review status
- ✅ 🎯 TARGET: Release by Feb 18

---

## 11. APP STORE SUBMISSION

### 11.1 App Information

**Name**: Deen First  
**Subtitle**: Block Apps, Build Quran Habits  
**Category**: Productivity  
**Age Rating**: 4+

**Description**:
```
Deen First helps you overcome phone addiction by combining Quran reading with screen time management.

🔒 BLOCK DISTRACTING APPS
Set daily time limits for social media and addictive apps. When you hit your limit, apps are blocked until midnight.

📖 READ THE QURAN
Browse all 114 surahs with Arabic text and English translations. Build a daily reading habit.

🎧 LISTENING SESSIONS
Listen to beautiful Quran recitations with apps blocked during your focus sessions. Choose from multiple reciters. Background audio keeps playing even when your phone is locked.

🔥 BUILD YOUR STREAK
Track consecutive days of Quran engagement. Don't break the chain!

⏰ SMART SCHEDULING
Set custom time ranges for blocking. Stay focused during work/study hours.

PERFECT FOR:
• Gen Z Muslims wanting to reduce screen time
• Anyone struggling with phone addiction
• Muslims wanting to reconnect with the Quran
• Parents managing children's screen time

Start your journey toward better phone habits and deeper Quran connection.

---

SUBSCRIPTION INFO:
Deen First requires a subscription to access all features.

• Monthly: $4.99/month (3-day free trial)
• Yearly: $29.99/year (7-day free trial)

Payment charged to Apple Account. Auto-renewal unless cancelled 24 hours before period ends. Manage in Account Settings.

Privacy Policy: [URL]
Terms of Service: [URL]
```

**Keywords**:
```
quran, muslim, islam, screen time, focus, productivity, ramadan, block apps, habit, streak
```

**Screenshots** (6.7" iPhone 15 Pro Max):
1. Quran tab with streak display
2. Surah reading view (Arabic + English)
3. Listening session (active, with audio controls)
4. Blocking tab (app limits)
5. Paywall screen
6. Settings/Profile tab

### 11.2 Privacy Nutrition Label

**Data Collected**:
- Contact Info: Email, Name (for account)
- Purchases: Purchase history (for subscriptions)
- Usage Data: App interactions (for streaks/sessions)

**Data Linked to User**: Yes  
**Data Used to Track**: No  
**Third-Party SDKs**: RevenueCat (subscription management)

---

## 12. RISKS & MITIGATION

### 12.1 Technical Risks

**Screen Time API Complexity**
- **Risk**: Shield configuration fails or buggy
- **Mitigation**: Allocate full day for testing, have fallback instructions

**Background Audio Issues**
- **Risk**: Audio stops when app backgrounds
- **Mitigation**: Test extensively, follow Apple guidelines, use standard AVFoundation patterns

**Subscription Edge Cases**
- **Risk**: Edge cases with expiration, restore, etc.
- **Mitigation**: Thorough testing with sandbox accounts, handle all RevenueCat states

**App Store Rejection**
- **Risk**: Rejected for Screen Time usage, subscription, or content
- **Mitigation**: Follow all guidelines, have Privacy Policy ready, respond quickly

### 12.2 Timeline Risks

**Development Delays**
- **Mitigation**: Strict scope adherence, daily progress tracking, buffer days built in

**TestFlight Issues**
- **Mitigation**: Start TestFlight early (Day 13), have internal testers ready

**App Store Review Time**
- **Mitigation**: Submit by Feb 18, monitor status closely, have 1-2 day buffer if possible

---

## 13. POST-LAUNCH (V1.1 Roadmap)

**Week 1 After Release**:
- Monitor crash reports (Xcode Organizer)
- Fix critical bugs
- Respond to reviews
- Collect user feedback

**V1.1 Features** (if requested):
- Google Sign In
- More reciters
- Additional translations (Urdu, Turkish, etc.)
- Push notifications (streak reminders)
- Widget support

**V2 Features** (2-3 months out):
- Cloud sync with Supabase
- Full offline mode (download audio)
- Verse-by-verse audio while reading
- Memorization tracking
- Social features (leaderboards, challenges)
- Prayer time integration

---

## APPENDIX

### A.1 Glossary

- **Surah**: Chapter of the Quran (114 total)
- **Ayah**: Verse within a surah
- **Reciter**: Person who recites the Quran aloud
- **Shield**: iOS Screen Time feature that blocks app access
- **Streak**: Consecutive days of Quran engagement
- **Session**: A period of reading or listening to Quran

### A.2 API Documentation

- QuranAPI.pages.dev: https://quranapi.pages.dev/introduction
- RevenueCat: https://docs.revenuecat.com
- Apple FamilyControls: https://developer.apple.com/documentation/familycontrols

### A.3 Design References

- Opal: Premium paywall, blocking UX
- Duolingo: Streak tracking, gamification
- Headspace: Onboarding survey, meditation sessions
- Noor Focus: Quran + blocking (competitor)

---

**END OF PRD v3.0**
