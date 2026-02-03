# Architecture Research: Surah Focus

**Researched:** 2026-02-03
**Domain:** iOS Quran + Screen Time Management App
**Architecture:** Clean Architecture + MVVM + SwiftUI + SwiftData
**Confidence:** HIGH

## Summary

This research documents the standard architecture patterns for iOS apps combining **FamilyControls (Screen Time API)**, **RevenueCat (subscriptions)**, and **AVFoundation (background audio)** using **Clean Architecture + MVVM**.

**Primary recommendation:** Use a layered architecture with clear separation between Presentation (Views/ViewModels), Domain (Services/Entities), and Data (Repositories/DataSources). Extensions for Screen Time API communicate with the main app via App Groups.

**Key findings:**
- iOS Screen Time API requires separate extensions (DeviceActivityMonitor, ShieldConfiguration)
- RevenueCat integrates cleanly with MVVM via a dedicated SubscriptionService
- AVFoundation requires proper audio session configuration for background playback
- SwiftData works well with Clean Architecture when wrapped in repositories
- Tuist provides excellent project generation for multi-target iOS apps

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  ┌──────────────┐        ┌──────────────────────┐              │
│  │    Views     │───────▶│     ViewModels       │              │
│  │ (SwiftUI)    │◀──────│  (@ObservableObject) │              │
│  └──────────────┘        └──────────────────────┘              │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                              │
│  ┌──────────────┐        ┌──────────────────────┐              │
│  │   Services   │───────▶│      Entities        │              │
│  │ (Business    │        │   (SwiftData @Model)  │              │
│  │  Logic)      │        │                      │              │
│  └──────────────┘        └──────────────────────┘              │
│  AuthService, SubscriptionService, QuranService, etc.          │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                │
│  ┌──────────────┐        ┌──────────────────────┐              │
│  │ Repositories │───────▶│    DataSources       │              │
│  │ (Data Access)│        │ (SwiftData/Network)  │              │
│  └──────────────┘        └──────────────────────┘              │
│  UserRepository, QuranRepository, SessionRepository            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SCREEN TIME ARCHITECTURE                       │
│  ┌──────────────┐        ┌──────────────────────┐              │
│  │  Main App    │◀─────▶│  App Groups          │              │
│  │ (Config)     │  shared│  (Shared UserDefaults)│            │
│  └──────────────┘        └──────────────────────┘              │
│                                  │                              │
│                                  ▼                              │
│  ┌──────────────────────────────────────────────┐              │
│  │            Extensions                         │              │
│  │  DeviceActivityMonitor (Background monitoring)│              │
│  │  ShieldConfiguration (Custom blocked UI)      │              │
│  └──────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Authentication System
- **Responsibility:** Handle Sign in with Apple, user session management
- **Technologies:** AuthenticationServices, SwiftData
- **Dependencies:** UserRepository, LocalDataSource
- **Build Complexity:** Low
- **Build Order:** Phase 1 (Foundation) - can be built first

**Key Classes:**
- `AuthService` (protocol) + `AuthServiceImpl`
- `AuthViewModel` (@MainActor)
- `AuthView` (SwiftUI)
- `User` entity (@Model)

**Data Flow:**
```
[User taps Sign in with Apple]
    → ASAuthorizationController flow
    → AuthViewModel.handleSignIn()
    → AuthService.signInWithApple()
    → UserRepository.createUser()
    → SwiftData persists User
    → Navigate to Onboarding/Paywall/MainTabs
```

### 2. Subscription System (RevenueCat)
- **Responsibility:** Manage in-app purchases, subscription status, paywall
- **Technologies:** RevenueCat SDK, StoreKit 2
- **Dependencies:** UserRepository, ScreenTimeService
- **Build Complexity:** Medium
- **Build Order:** Phase 2 - requires Auth to be complete first

**Key Classes:**
- `SubscriptionService` (protocol) + `SubscriptionServiceImpl`
- `PaywallViewModel` (@MainActor)
- `PaywallView` (SwiftUI)
- RevenueCat `Purchases` SDK (external)

**Critical Integration Point:**
RevenueCat must be initialized in `SurahFocusApp.swift` before any UI appears:

```swift
@main
struct SurahFocusApp: App {
    init() {
        Purchases.configure(withAPIKey: "YOUR_KEY")
        Purchases.logLevel = .debug
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

**Subscription Status Check Flow:**
```
[App Launch]
    → RootView.onAppear
    → SubscriptionService.checkSubscriptionStatus()
    → Purchases.shared.customerInfo()
    → Update User.isPremium in SwiftData
    → If expired: ScreenTimeService.removeAllShields()
    → Navigate: Paywall (expired) or MainTabs (active)
```

### 3. Screen Time Blocking System
- **Responsibility:** Block apps during listening sessions, enforce daily limits
- **Technologies:** FamilyControls, ManagedSettings, DeviceActivity, App Groups
- **Dependencies:** Shared UserDefaults (App Groups)
- **Build Complexity:** High
- **Build Order:** Phase 3 - requires RevenueCat first (subscription gating)

**Architecture Components:**
```
Main App Target:
├── ScreenTimeService (business logic)
├── ScreenTimeRepository (data access)
└── FamilyActivityPicker (UI for app selection)

Extension Target 1: ScreenTimeMonitor
├── DeviceActivityMonitorExtension
├── Background monitoring
└── Shield application logic

Extension Target 2: Shield
├── ShieldConfigurationExtension
└── Custom blocked UI

Shared Data: App Groups (group.com.aydev.surahfocus)
└── UserDefaults for token sharing
```

**Key Classes:**
- `ScreenTimeService` (protocol) + `ScreenTimeServiceImpl`
- `ScreenTimeRepository` (protocol) + `ScreenTimeRepositoryImpl`
- `DeviceActivityMonitorExtension` (separate target)
- `ShieldConfigurationExtension` (separate target)

**Entitlements Required:**

Main App (`SurahFocus.entitlements`):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aydev.surahfocus</string>
</array>
```

DeviceActivityMonitor Extension (`ScreenTimeMonitor.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aydev.surahfocus</string>
</array>
```

### 4. Quran Reading System
- **Responsibility:** Fetch, cache, and display Quran text + translations
- **Technologies:** URLSession, QuranAPI.pages.dev, SwiftData (cache)
- **Dependencies:** HTTPClient, LocalDataSource
- **Build Complexity:** Low
- **Build Order:** Phase 4 - can be built in parallel with Audio

**Key Classes:**
- `QuranService` (protocol) + `QuranServiceImpl`
- `QuranRepository` (protocol) + `QuranRepositoryImpl`
- `QuranAPIDataSource` (network client)
- `QuranTabViewModel`, `SurahDetailViewModel`
- `Surah`, `Ayah` entities

**Caching Strategy:**
```
[User opens Surah list]
    → QuranRepository.getAllSurahs()
    → Check SwiftData cache
    → If cached: Return immediately
    → If not: Fetch from API
    → Save to SwiftData (indefinite cache)
    → Return to UI

[User opens Surah detail]
    → QuranRepository.getSurah(id:)
    → Check SwiftData cache with expiry
    → If valid cached: Return immediately
    → If expired/missing: Fetch from API
    → Save to SwiftData (30-day cache)
    → Return to UI
```

**Important:** Audio URLs are NOT cached (streaming only)

### 5. Audio Playback System
- **Responsibility:** Play Quran recitation with background support
- **Technologies:** AVFoundation, AVAudioSession, MediaPlayer (Now Playing)
- **Dependencies:** QuranService (for audio URLs)
- **Build Complexity:** Medium
- **Build Order:** Phase 5 - requires Quran API working first

**Key Classes:**
- `AudioPlayerService` (protocol) + `AudioPlayerServiceImpl`
- `ListenSessionViewModel`
- `ListenSessionView`

**Background Audio Configuration:**

In `AudioPlayerServiceImpl`:
```swift
private func setupAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
    } catch {
        print("Failed to configure audio session: \(error)")
    }
}
```

In `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Listening Session Flow:**
```
[User selects surahs + reciter]
    → Taps "Start Session"
    → Save preferences to UserDefaults (immediately)
    → Apply shield to selected apps
    → Fetch audio URL from API
    → Load into AVPlayer
    → Play audio
    → Setup Now Playing info (Control Center, Lock Screen)
    → Start session timer
    → Update UI to active session state
```

### 6. Streak Tracking System
- **Responsibility:** Track consecutive days of Quran engagement
- **Technologies:** SwiftData, Calendar (date math)
- **Dependencies:** SessionRepository, UserRepository
- **Build Complexity:** Low
- **Build Order:** Phase 6 - requires Sessions working first

**Key Classes:**
- `SessionService` (protocol) + `SessionServiceImpl`
- `Session` entity (@Model)

**Streak Logic:**
```
[User completes session >= 2 minutes]
    → SessionService.createSession()
    → SessionService.updateStreak()
    → Calculate days since last engagement
    │
    ├─ Same day: No change
    ├─ Yesterday: Increment streak
    ├─ 2+ days ago: Reset streak to 1
    └─ First ever: Set streak to 1
    → Update User.currentStreak, User.longestStreak
    → Save to SwiftData
```

## Data Flow

### User Onboarding Flow
```
[Launch App]
    → Check if user exists in SwiftData
    │
    ├─ No user:
    │   → Show AuthView
    │   → User signs in with Apple
    │   → CreateUser in SwiftData
    │   → Navigate to Onboarding
    │   │   → 4-screen survey
    │   │   → Navigate to Paywall
    │   │   → User subscribes
    │   │   → Navigate to ScreenTimePermission
    │   │   → User selects apps + limits
    │   │   → Navigate to MainTabs
    │   │
    └─ User exists:
        → Check subscription status
        │
        ├─ Active: Navigate to MainTabs
        └─ Expired: Remove shields + Navigate to Paywall
```

### Daily Usage Flow
```
[Open App]
    → Check subscription status
    → Load MainTabs
    → QuranTab loads surahs
    → Show current streak
    → User can:
    │   ├─ Read surah (SurahDetailView)
    │   ├─ Start listening session (ListenSessionView)
    │   ├─ Manage blocked apps (BlockingTab)
    │   └─ View settings (SettingsTab)
```

### App Blocking Flow (Listening Session)
```
[User starts listening session]
    → ScreenTimeService.startBlockingSession()
    → ManagedSettingsStore.shield.applications = selectedApps
    → Apps blocked immediately
    → Audio starts playing
    │
    ├─ [User tries to open blocked app]
    │   → Shield shown (custom UI)
    │   → "Time to read Quran instead 🌙"
    │   → User can only close (cannot open app)
    │
    └─ [Session ends]
        → ScreenTimeService.endBlockingSession()
        → ManagedSettingsStore.shield.applications = nil
        → Apps accessible again
```

### Subscription Expiration Flow
```
[Subscription expires]
    → Next app launch:
    → SubscriptionService.checkSubscriptionStatus()
    → User.isPremium = false
    → ScreenTimeService.removeAllShields()
    │   → ManagedSettingsStore.clearAllSettings()
    │   → DeviceActivityCenter.stopMonitoring()
    → Navigate to Paywall
    → "Your subscription has expired"
    → User must resubscribe to continue
```

## Critical Integration Points

### FamilyControls (Screen Time API)

**Integration Pattern:**

The Screen Time API uses an **extension-based architecture** where the main app configures blocking rules and separate extensions enforce them in the background.

**Key Classes:**
- `AuthorizationCenter` - Request/manage permissions
- `ManagedSettingsStore` - Apply/remove shields
- `DeviceActivityCenter` - Monitor app usage
- `FamilyActivityPicker` - UI for app selection
- `ApplicationToken` - Opaque token representing an app

**Permissions Flow:**

User interaction REQUIRED (cannot auto-grant):
```swift
func requestPermission() async throws {
    let center = AuthorizationCenter.shared
    try await center.requestAuthorization(for: .individual)
}
```

Shows system dialog: *"Surah Focus Would Like to Access Your Screen Time Data"*

**App Selection Flow:**

```swift
FamilyActivityPicker(selection: $selectedApps)
    // Presents native iOS app picker
    // Returns Set<ApplicationToken>
    // User can select individual apps or categories
```

**Limitations:**
- **Does NOT work in iOS Simulator** - must test on physical device (iOS 17+)
- **Requires parental approval** for users under 18
- **No programmatic access** to app usage data (privacy-first)
- **Opaque tokens** - cannot see app bundle IDs directly
- **Extension communication** only via App Groups

**Build Order:**
1. **Phase 3 (Days 5-6):** Set up extensions, entitlements, App Groups
2. **Phase 6 (Day 11):** Implement listening session blocking
3. **Phase 7 (Day 12):** Implement daily limits with DeviceActivity

### RevenueCat

**Integration Pattern:**

RevenueCat wraps StoreKit 2 and provides a simplified API for subscription management. Integrate as a service in the Domain layer.

**Key Classes:**
- `Purchases` - Main SDK singleton
- `CustomerInfo` - Contains subscription status
- `Offering` - Product configuration
- `Package` - Specific subscription product
- `Entitlement` - Access rights

**Entitlements Required:**
None in entitlements file (RevenueCat uses StoreKit internally)

**App Store Connect Configuration Required:**
1. Create subscription products:
   - `com.aydev.surahfocus.monthly` - $4.99/month, 3-day trial
   - `com.aydev.surahfocus.yearly` - $29.99/year, 7-day trial
2. Create RevenueCat project
3. Configure products in RevenueCat dashboard
4. Create `premium` entitlement
5. Attach both products to `premium` entitlement

**Integration Code:**

```swift
// In SurahFocusApp.swift
import RevenueCat

@main
struct SurahFocusApp: App {
    init() {
        Purchases.configure(withAPIKey: "YOUR_KEY")
        Purchases.logLevel = .debug
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(DIContainer.shared.modelContainer)
        }
    }
}

// In SubscriptionServiceImpl
func checkSubscriptionStatus() async throws -> Bool {
    let customerInfo = try await Purchases.shared.customerInfo()
    let isPremium = customerInfo.entitlements["premium"]?.isActive == true

    // Update local user
    if var user = try await userRepo.getCurrentUser() {
        user.isPremium = isPremium
        user.subscriptionExpiryDate = customerInfo.entitlements["premium"]?.expirationDate
        try await userRepo.updateUser(user)

        // CRITICAL: Remove shields if expired
        if !isPremium {
            try await screenTimeService.removeAllShields()
        }
    }

    return isPremium
}
```

**Build Order:**
**Phase 2 (Days 3-4):** Set up RevenueCat, integrate with Auth, build Paywall

### Background Audio

**Integration Pattern:**

AVFoundation requires proper audio session configuration and Info.plist setup for background playback.

**Key Classes:**
- `AVPlayer` - Play audio streams
- `AVPlayerItem` - Represents audio asset
- `AVAudioSession` - Configure audio behavior
- `MPNowPlayingInfoCenter` - Control Center/Lock Screen info
- `MPRemoteCommandCenter` - Handle remote control events

**Background Modes Required:**

In `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

In Xcode: Target → Signing & Capabilities → + Background Modes → Audio, AirPlay, and Picture in Picture

**Audio Session Setup:**

```swift
private func setupAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        // Enable background playback
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)

        // Optional: Mix with other audio
        try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
    } catch {
        print("Failed to configure audio session: \(error)")
    }
}
```

**Now Playing Info (Control Center):**

```swift
func updateNowPlayingInfo(surahName: String, reciterName: String) {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = surahName
    nowPlayingInfo[MPMediaItemPropertyArtist] = reciterName
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}
```

**Remote Controls (Lock Screen):**

```swift
private func setupRemoteTransportControls() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [weak self] _ in
        self?.play()
        return .success
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
        self?.pause()
        return .success
    }
}
```

**Build Order:**
**Phase 5 (Days 9-10):** Implement audio player, listening session, background playback

## Suggested Build Order

Based on component dependencies and complexity:

### Phase 1 - Foundation (Days 1-2)
1. **Project Setup** - Tuist configuration, folder structure
2. **DIContainer** - Dependency injection skeleton
3. **Router** - Navigation infrastructure
4. **HTTPClient** - Network layer
5. **SwiftData Entities** - User, Session, BlockedApp models
6. **LocalDataSource** - SwiftData wrapper

**Why first:** All other components depend on this foundation.

### Phase 2 - Authentication (Days 3-4)
1. **AuthService** - Sign in with Apple logic
2. **UserRepository** - User data access
3. **AuthViewModel** - Auth UI state
4. **AuthView** - Sign in screen
5. **RevenueCat Integration** - SDK setup, configuration
6. **SubscriptionService** - Purchase/restore logic
7. **PaywallViewModel** - Paywall UI state
8. **PaywallView** - Subscription screen

**Why second:** Most other features require authenticated users + subscription gating.

### Phase 3 - Screen Time Setup (Days 5-6)
1. **App Groups Configuration** - Shared data between app/extensions
2. **Extension Targets Setup** - ScreenTimeMonitor, Shield
3. **ScreenTimeRepository** - Token/limit persistence
4. **ScreenTimeService** - Blocking logic
5. **Onboarding Survey** - 4-screen flow
6. **Permission Request Flow** - FamilyControls authorization
7. **App Selection UI** - FamilyActivityPicker integration
8. **Time Limit Configuration** - Daily limit setup
9. **Shield Configuration** - Custom blocked UI

**Why third:** Critical for core value proposition, but requires RevenueCat to be working first.

### Phase 4 - Quran Integration (Day 7)
1. **QuranAPIClient** - HTTP client for QuranAPI.pages.dev
2. **QuranRepository** - Cache + fetch logic
3. **QuranService** - Business logic layer
4. **QuranTabViewModel** - Quran list state
5. **QuranTabView** - Surah list UI
6. **SurahDetailViewModel** - Surah reading state
7. **SurahDetailView** - Reading UI

**Why fourth:** Independent of Screen Time, can be built in parallel. Core feature.

### Phase 5 - Audio & Sessions (Days 8-9)
1. **AudioPlayerService** - AVFoundation wrapper
2. **SessionRepository** - Session persistence
3. **SessionService** - Streak logic
4. **ListenSessionViewModel** - Session state
5. **ListenSessionView** - Session UI
6. **Background Audio Setup** - Info.plist, audio session
7. **Now Playing Info** - Control Center integration
8. **Auto-play Next Surah** - Queue management

**Why fifth:** Depends on Quran API being functional. Complex integration.

### Phase 6 - Main Tabs (Day 10)
1. **MainTabView** - Tab container
2. **BlockingTabViewModel** - App limits state
3. **BlockingTabView** - App limits UI
4. **SettingsTabViewModel** - Settings state
5. **SettingsTabView** - Settings UI
6. **Navigation Wiring** - Connect all flows

**Why sixth:** Brings everything together. Requires most features to be complete.

### Phase 7 - Polish & Testing (Days 11-16)
1. **Streak Display** - Visual polish
2. **Loading States** - All async operations
3. **Error Handling** - User-friendly messages
4. **Subscription Expiration Flow** - Shield removal
5. **Integration Tests** - End-to-end flows
6. **TestFlight Build** - Internal testing
7. **App Store Submission** - Production

**Why seventh:** Requires all core functionality to be working.

## Module Structure (Tuist)

```
SurahFocus/
├── Project.swift              # Tuist project configuration
├── Tuist/
│   └── Package.swift          # Dependencies (RevenueCat)
├── Makefile                   # Build automation
├── .env                       # Environment variables
│
├── SurahFocus/                # Main App Target
│   ├── Sources/
│   │   ├── Core/
│   │   │   ├── DataDependency/
│   │   │   │   └── DIContainer.swift
│   │   │   ├── Networking/
│   │   │   │   └── HTTPClient.swift
│   │   │   └── SceneNavigation/
│   │   │       └── Router.swift
│   │   │
│   │   ├── Data/
│   │   │   ├── DataSource/
│   │   │   │   ├── LocalDataSource.swift
│   │   │   │   └── QuranAPIDataSource.swift
│   │   │   └── Repositories/
│   │   │       ├── UserRepository.swift
│   │   │       ├── SessionRepository.swift
│   │   │       ├── QuranRepository.swift
│   │   │       └── ScreenTimeRepository.swift
│   │   │
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   │   ├── user.swift
│   │   │   │   ├── session.swift
│   │   │   │   ├── blocked_app.swift
│   │   │   │   ├── app_time_limit.swift
│   │   │   │   ├── surah.swift
│   │   │   │   └── ayah.swift
│   │   │   └── Services/
│   │   │       ├── AuthService.swift
│   │   │       ├── SubscriptionService.swift
│   │   │       ├── ScreenTimeService.swift
│   │   │       ├── QuranService.swift
│   │   │       └── SessionService.swift
│   │   │
│   │   ├── Presentation/
│   │   │   ├── Components/
│   │   │   │   ├── CustomButton.swift
│   │   │   │   ├── SurahCard.swift
│   │   │   │   └── StreakBadge.swift
│   │   │   │
│   │   │   ├── Auth/
│   │   │   │   ├── AuthView.swift
│   │   │   │   └── AuthViewModel.swift
│   │   │   │
│   │   │   ├── Onboarding/
│   │   │   │   ├── OnboardingView.swift
│   │   │   │   └── OnboardingViewModel.swift
│   │   │   │
│   │   │   ├── Paywall/
│   │   │   │   ├── PaywallView.swift
│   │   │   │   └── PaywallViewModel.swift
│   │   │   │
│   │   │   ├── MainTabs/
│   │   │   │   ├── MainTabView.swift
│   │   │   │   ├── QuranTab/
│   │   │   │   │   ├── QuranTabView.swift
│   │   │   │   │   ├── SurahListView.swift
│   │   │   │   │   ├── SurahDetailView.swift
│   │   │   │   │   └── QuranTabViewModel.swift
│   │   │   │   ├── BlockingTab/
│   │   │   │   │   ├── BlockingTabView.swift
│   │   │   │   │   └── BlockingTabViewModel.swift
│   │   │   │   └── SettingsTab/
│   │   │   │       ├── SettingsTabView.swift
│   │   │   │       └── SettingsTabViewModel.swift
│   │   │   │
│   │   │   └── ListenSession/
│   │   │       ├── ListenSessionView.swift
│   │   │       └── ListenSessionViewModel.swift
│   │   │
│   │   ├── Utils/
│   │   │   └── Extensions.swift
│   │   │
│   │   ├── RootView.swift
│   │   └── SurahFocusApp.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       └── Info.plist
│
├── ScreenTimeMonitor/         # Extension Target 1
│   ├── Sources/
│   │   └── DeviceActivityMonitorExtension.swift
│   └── Info.plist
│
└── Shield/                    # Extension Target 2
    ├── Sources/
    │   └── ShieldConfigurationExtension.swift
    └── Info.plist
```

**Tuist Project.swift Configuration:**

```swift
import ProjectDescription

let project = Project(
    name: "SurahFocus",
    targets: [
        // Main App
        .target(
            name: "SurahFocus",
            destinations: .iOS,
            product: .app,
            bundleId: "com.aydev.surahfocus",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSFamilyControlsUsageDescription": "Surah Focus needs permission to block distracting apps during your Quran focus sessions.",
                "UIBackgroundModes": ["audio"]
            ]),
            sources: ["SurahFocus/Sources/**"],
            resources: ["SurahFocus/Resources/**"],
            dependencies: [
                .external(name: "RevenueCat")
            ]
        ),

        // ScreenTime Monitor Extension
        .target(
            name: "ScreenTimeMonitor",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.aydev.surahfocus.ScreenTimeMonitor",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.device-activity.monitor",
                    "NSExtensionPrincipalClass": "DeviceActivityMonitorExtension"
                ]
            ]),
            sources: ["ScreenTimeMonitor/Sources/**"]
        ),

        // Shield Configuration Extension
        .target(
            name: "Shield",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.aydev.surahfocus.Shield",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.shield-configuration",
                    "NSExtensionPrincipalClass": "ShieldConfigurationExtension"
                ]
            ]),
            sources: ["Shield/Sources/**"]
        )
    ]
)
```

## State Management

**Approach:** SwiftUI + @Published + @ObservableObject (MVVM)

**Why:**
- Native to SwiftUI (no third-party dependencies)
- Simple and declarative
- Excellent tooling in Xcode
- Predictable data flow
- Easy to test ViewModels in isolation

**Pattern:**

```swift
@MainActor  // Ensures UI updates on main thread
final class QuranTabViewModel: ObservableObject {
    // Published properties trigger UI updates
    @Published var surahs: [Surah] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = true
    @Published var user: User?

    // Dependencies injected via DIContainer
    private let quranService: QuranService
    private let userRepository: UserRepository

    init() {
        self.quranService = DIContainer.shared.quranService
        self.userRepository = DIContainer.shared.userRepository
    }

    // Business logic methods
    func load() {
        Task {
            do {
                isLoading = true
                user = try await userRepository.getCurrentUser()
                surahs = try await quranService.getAllSurahs()
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
}

// View consumes ViewModel
struct QuranTabView: View {
    @EnvironmentObject var vm: QuranTabViewModel

    var body: some View {
        if vm.isLoading {
            ProgressView()
        } else {
            List(vm.surahs) { surah in
                SurahCard(surah: surah)
            }
        }
        .onAppear {
            vm.load()
        }
    }
}
```

**Complexity:** Medium

**Best Practices:**
- All ViewModels must be `@MainActor` (thread safety)
- Use `@Published` for all reactive state
- Wrap async work in `Task { }`
- Use `do/catch` for error handling
- Set `isLoading` before/after async work
- No UI code in ViewModels

## Background Tasks

### Audio Playback

**How it works:**

1. **Audio Session Configuration** (app launch):
   ```swift
   try audioSession.setCategory(.playback, mode: .default)
   try audioSession.setActive(true)
   ```

2. **Background Mode Enabled** (Info.plist):
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
   </array>
   ```

3. **AVPlayer Plays Audio**:
   - App can be backgrounded
   - Audio continues playing
   - Control Center shows controls
   - Lock Screen shows controls

4. **Remote Control Events**:
   - Play/pause from Control Center
   - Skip to next surah
   - Update Now Playing info

**Limitations:**
- No auto-play next surah in background (must handle via observers)
- Session memory limited (~50MB)
- Audio must be streamed (not downloaded) for V1

### Streak Tracking

**How it works:**

1. **Session Completes** (>= 2 minutes):
   ```swift
   session.durationSeconds >= 120
   ```

2. **Calculate Streak**:
   - Get last engagement date from User
   - Calculate days difference
   - Increment or reset streak

3. **Persist to SwiftData**:
   ```swift
   user.currentStreak = newStreakValue
   user.lastEngagementDate = today
   try context.save()
   ```

**No background task required** - happens synchronously during app use.

### Screen Time Updates

**How it works:**

1. **DeviceActivityMonitor Extension** (separate process):
   - Runs in background continuously
   - Monitors app usage
   - Applies shields when thresholds reached

2. **App Group Communication**:
   - Main app writes rules to shared UserDefaults
   - Extension reads rules from shared UserDefaults
   - No direct function calls allowed

3. **Daily Reset** (midnight):
   ```swift
   override func intervalDidStart(for activity: DeviceActivityName) {
       // New day started
       ManagedSettingsStore().clearAllSettings()
   }
   ```

**Limitations:**
- Extension runs independently (no shared memory)
- Communication only via App Groups (UserDefaults/File)
- Cannot debug extensions easily (use logs)

## Open Questions

1. **Multi-surah Playlist in Background**
   - **What we know:** AVPlayer can auto-play next item
   - **What's unclear:** Handling network errors during auto-play
   - **Recommendation:** Test thoroughly on device, implement retry logic

2. **Screen Time Shield Persistence**
   - **What we know:** Shields persist until explicitly removed
   - **What's unclear:** Behavior after app reinstall
   - **Recommendation:** Test subscription expiration flow end-to-end

3. **SwiftData Migration**
   - **What we know:** SwiftData supports schema migrations
   - **What's unclear:** Complexity of adding new fields post-launch
   - **Recommendation:** Plan V1 schema carefully, minimize changes

4. **RevenueCat Webhook Handling**
   - **What we know:** RevenueCat can notify server of subscription changes
   - **What's unclear:** Needed for V1 (local-only)?
   - **Recommendation:** Skip for V1, add in V2 with cloud sync

## Sources

### Primary (HIGH confidence)

**Apple Official Documentation:**
- [FamilyControls Framework](https://developer.apple.com/documentation/familycontrols) - Screen Time API reference
- [AVAudioSession](https://developer.apple.com/documentation/avfoundation/audio_session_management) - Audio session configuration
- [ManagedSettings](https://developer.apple.com/documentation/managedsettings) - Shield management
- [Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls) - Xcode setup guide

**Community Guides:**
- [A Developer's Guide to Apple's Screen Time APIs](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7) - Comprehensive Screen Time API tutorial (MEDIUM)
- [The Ultimate Guide to Modern iOS Architecture in 2025](https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f) - Clean Architecture patterns (MEDIUM)
- [Modern MVVM in SwiftUI 2025: The Clean Architecture](https://medium.com/@minalkewat/modern-mvvm-in-swiftui-2025-the-clean-architecture-youve-been-waiting-for-72a7d576648e) - MVVM + Clean patterns (MEDIUM)

**RevenueCat:**
- [Official iOS Documentation](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/swiftui-helpers) - SwiftUI integration (HIGH)
- [Detailed Guide to Integrating RevenueCat (Latest 2025)](https://medium.com/codex/detailed-guide-to-integrating-revenuecat-into-apple-app-store-subscriptions-latest-2025-66202e0a075e) - Step-by-step guide (MEDIUM)

**Tuist:**
- [The Modular Architecture (TMA) Documentation](https://docs.tuist.dev/en/guides/features/projects/tma-architecture) - Modular project structure (HIGH)
- [Why you might want to generate your Xcode projects in 2025](https://tuist.dev/blog/2025/02/25/project-generation) - Tuist benefits (HIGH)

### Secondary (MEDIUM confidence)

**Architecture Patterns:**
- [SwiftData Architecture Patterns And Practices](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html) - SwiftData best practices (MEDIUM)
- [2025's Best SwiftUI Architecture: MVVM + Clean + Feature Modules](https://medium.com/@minalkewat/2025s-best-swiftui-architecture-mvvm-clean-feature-modules-3a369a22858c) - Modular architecture (MEDIUM)

**Audio Playback:**
- [Background audio handling with iOS AVPlayer](https://www.mux.com/blog/background-audio-handling-with-ios-avplayer) - Background audio patterns (MEDIUM)
- [iOS — Playing audio in the background](https://medium.com/@sagorin/ios-playing-audio-in-the-background-f5abb6456816) - Background implementation (MEDIUM)

### Tertiary (LOW confidence)

**Community Discussions:**
- [MVVM sucks with SwiftData - Reddit Discussion](https://www.reddit.com/r/iOSProgramming/comments/1nq1lnc/mvvm_sucks_with_swiftdata_what_architecture_are/) - Architecture debate (LOW - needs validation)
- [How to use screen time api?](https://www.reddit.com/r/iOSProgramming/comments/1b8bnpm/how_to_use_screen_time_api/) - Screen Time discussion (LOW)

## Metadata

**Confidence breakdown:**
- Screen Time API architecture: HIGH - Apple docs + community guides
- RevenueCat integration: HIGH - Official docs + tested patterns
- Background audio: HIGH - Apple docs + common patterns
- Clean Architecture + MVVM: HIGH - Well-established pattern
- SwiftData integration: MEDIUM - Newer framework, evolving best practices
- Build order: HIGH - Based on dependency analysis

**Research date:** 2026-02-03
**Valid until:** 2026-03-03 (30 days for stable frameworks, 7 for fast-moving)

**Researcher notes:**
- Screen Time API is stable (iOS 16+)
- RevenueCat is mature and well-documented
- AVFoundation is extremely stable
- SwiftData is newer but stable for basic use cases
- Clean Architecture + MVVM is industry standard

**Gaps identified:**
- Limited real-world examples of RevenueCat + Screen Time API together
- SwiftData + MVVM debates in community (some prefer simpler approach)
- Need to verify extension communication patterns on physical device
