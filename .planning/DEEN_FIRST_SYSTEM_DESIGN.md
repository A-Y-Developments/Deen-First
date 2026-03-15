# HIGH-LEVEL SYSTEM DESIGN
# Deen First - Quran Reading & Screen Time Management

**Version:** 3.0 (Final)  
**Date:** February 2, 2026  
**Related Document:** DEEN_FIRST_PRD.md v3.0

---

## 1. SYSTEM OVERVIEW

### 1.1 Technology Stack

```
┌─────────────────────────────────────────────────┐
│          iOS App (Swift/SwiftUI)                │
├─────────────────────────────────────────────────┤
│  Platform: iOS 17+                              │
│  Language: Swift 5.9+                           │
│  UI Framework: SwiftUI                          │
│  Architecture: Clean Architecture + MVVM        │
│  Database: SwiftData (local only)               │
│  Auth: Sign in with Apple (native)              │
│  Monetization: RevenueCat SDK                   │
│  Screen Time: FamilyControls framework          │
│  Audio: AVFoundation (background enabled)       │
└─────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│           External Services                      │
├─────────────────────────────────────────────────┤
│  • QuranAPI.pages.dev (text + audio)            │
│  • Apple Authentication Services                │
│  • RevenueCat (Subscription Management)         │
└─────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│          Device-Level Integration                │
├─────────────────────────────────────────────────┤
│  • FamilyControls (Screen Time API)             │
│  • ManagedSettings (App Blocking)               │
│  • AVAudioSession (Background Audio)            │
│  • Apple In-App Purchase                        │
└─────────────────────────────────────────────────┘
```

### 1.2 Architecture Pattern

**Clean Architecture + MVVM (3 Layers)**

```
┌────────────────────────────────────────────────────────┐
│                PRESENTATION LAYER                       │
│  ┌──────────────┐        ┌──────────────────────┐     │
│  │    Views     │───────▶│     ViewModels       │     │
│  │ (SwiftUI)    │        │  (@ObservableObject) │     │
│  └──────────────┘        └──────────────────────┘     │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│                   DOMAIN LAYER                          │
│  ┌──────────────┐        ┌──────────────────────┐     │
│  │   Services   │───────▶│      Entities        │     │
│  │ (Business    │        │   (Data Models)      │     │
│  │  Logic)      │        │                      │     │
│  └──────────────┘        └──────────────────────┘     │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│                    DATA LAYER                           │
│  ┌──────────────┐        ┌──────────────────────┐     │
│  │ Repositories │───────▶│    DataSources       │     │
│  │ (Data Access)│        │ (SwiftData/Network)  │     │
│  └──────────────┘        └──────────────────────┘     │
└────────────────────────────────────────────────────────┘
```

---

## 2. KEY FEATURES & DATA FLOWS

### 2.1 App Structure (3-Tab Navigation)

```
MainTabView
    ├─ Tab 1: Quran (Default)
    │   ├─ Streak display
    │   ├─ Search bar
    │   ├─ Surah list
    │   └─ Floating button: "Start Listening"
    │
    ├─ Tab 2: Blocking
    │   ├─ List of blocked apps with limits
    │   └─ "Add More Apps" button
    │
    └─ Tab 3: Settings/Profile
        ├─ Profile info
        ├─ Subscription status
        ├─ Preferences
        └─ Sign out / Delete account
```

### 2.2 Subscription Status Check (On Every App Launch)

```
App launches
    ↓
RootView appears
    ↓
Check subscription status:
    Purchases.shared.customerInfo()
    ↓
Is premium?
    ├─ YES → Navigate to MainTabs
    │
    └─ NO → Remove all shields + Navigate to Paywall
        ↓
        ManagedSettingsStore.shield.applications = nil
        ↓
        User must resubscribe to access app
```

**Critical Code**:
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
    
    // Navigate
    if !isPremium {
        router.navigate(to: .paywall)
    } else {
        router.navigate(to: .mainTabs)
    }
}
```

### 2.3 Listening Session Flow (with Preference Saving on START)

```
User opens Listening Setup
    ↓
Load defaults:
    - Blocked apps (from onboarding)
    - Last selected reciter (from UserDefaults)
    - Last selected surahs (from UserDefaults)
    ↓
User selects:
    - Surahs: [Al-Baqarah, Al-Imran]
    - Reciter: Mishary Alafasy
    - Apps: Instagram, TikTok
    ↓
User taps "Start Session"
    ↓
STEP 1: SAVE PREFERENCES IMMEDIATELY
    UserDefaults.standard.set([2, 3], forKey: "lastSelectedSurahs")
    UserDefaults.standard.set(7, forKey: "lastSelectedReciter")
    ↓
STEP 2: Apply Shield
    ManagedSettingsStore.shield.applications = appTokens
    ↓
STEP 3: Fetch audio URL from API
    GET /surah/2/audio/7
    → Returns: { "audioUrl": "https://..." }
    ↓
STEP 4: Load and play audio
    audioPlayer.loadAudio(url)
    audioPlayer.play()
    ↓
STEP 5: Start timer
    Timer counts elapsedSeconds
    ↓
STEP 6: Update UI
    isSessionActive = true
    currentSurah = Al-Baqarah
    ↓
User listens (audio plays in background)
    ↓
First surah finishes → Auto-play next surah
    ↓
User taps "End Session" OR all surahs finish
    ↓
endSession():
    ├─ Stop audio
    ├─ Check subscription status
    │   ├─ If expired: Remove ALL shields, show paywall
    │   └─ If active: Remove session shield only
    ├─ Save session to SwiftData
    └─ Update streak (if new day)
```

**Why save preferences on START?**
- If user closes app mid-session, preferences already saved
- More reliable than saving on end
- Next session will pre-populate correctly

---

## 3. CORE MECHANICS

### 3.1 App Blocking (No Reward System)

```
User sets Instagram limit: 30 min/day
    ↓
User uses Instagram for 30 minutes
    ↓
Limit reached → Shield activated
    ↓
Instagram BLOCKED until midnight
    ↓
NO WAY to unlock
(Listening to Quran does NOT unblock apps)
    ↓
At midnight → Limit resets, Instagram accessible again
```

### 3.2 Streak System

```
Day 1: User reads 3 min → Streak: 1 🔥
Day 2: User listens 5 min → Streak: 2 🔥🔥
Day 3: User reads 2 min → Streak: 3 🔥🔥🔥
Day 4: User forgets → Streak: RESET to 0 ❌
Day 5: User listens 10 min → Streak: 1 🔥
```

**Rules**:
- Engagement counts immediately (no minimum time)
- Only one activity per day needed (read OR listen)
- Consecutive days only

### 3.3 Caching Strategy

**Text Content**:
```
Surah list: Cache indefinitely (static, ~50KB)
Surah content: Cache 30 days (~10-50KB per surah)
```

**Audio**:
```
NO caching (streaming only)
Reason: Too large (5-30MB per surah)
V2: Add offline mode with audio downloads
```

**Behavior**:
```
With internet: Fetch from API
Without internet: Use cached text (if available)
Cannot stream audio without internet
```

---

## 4. API INTEGRATION

### 4.1 QuranAPI.pages.dev Client

```swift
final class QuranAPIClient {
    private let baseURL = "https://quranapi.pages.dev/api"
    private let http: HTTPClient

    init(http: HTTPClient = .shared) {
        self.http = http
    }

    // MARK: - Text Content

    func fetchAllSurahs() async throws -> [Surah] {
        let url = URL(string: "\(baseURL)/surah")!
        return try await http.fetch(url: url)
    }

    func fetchSurah(id: Int, language: String = "en") async throws -> Surah {
        struct Query: Encodable { let lang: String }
        let url = URL(string: "\(baseURL)/surah/\(id)")!
        return try await http.fetch(url: url, parameters: Query(lang: language))
    }
    
    // MARK: - Audio

    func fetchAudioURL(surahNumber: Int, reciterId: Int) async throws -> AudioResponse {
        let url = URL(string: "\(baseURL)/surah/\(surahNumber)/audio/\(reciterId)")!
        return try await http.fetch(url: url)
    }
}

struct AudioResponse: Codable {
    let audioUrl: URL
}
```

### 4.2 Caching Implementation

```swift
final class QuranRepository {
    private let apiClient: QuranAPIClient
    private let localDataSource: LocalDataSource
    
    func getAllSurahs() async throws -> [Surah] {
        // Check cache first
        if let cached = try? localDataSource.getCachedSurahs() {
            return cached
        }
        
        // Fetch from API
        let surahs = try await apiClient.fetchAllSurahs()
        
        // Cache indefinitely
        try localDataSource.cacheSurahs(surahs)
        
        return surahs
    }
    
    func getSurahById(id: Int, translation: String) async throws -> Surah {
        // Check cache (with expiry)
        if let cached = try? localDataSource.getCachedSurah(id: id),
           !cached.isExpired {
            return cached.surah
        }
        
        // Fetch from API
        let surah = try await apiClient.fetchSurah(id: id, language: translation)
        
        // Cache for 30 days
        try localDataSource.cacheSurah(surah, expiryDays: 30)
        
        return surah
    }
    
    func getAudioURL(surahNumber: Int, reciterId: Int) async throws -> URL {
        // NO caching for audio URLs (fetch fresh every time)
        let response = try await apiClient.fetchAudioURL(
            surahNumber: surahNumber,
            reciterId: reciterId
        )
        return response.audioUrl
    }
}
```

---

## 5. SERVICE SPECIFICATIONS

### 5.1 SubscriptionService (with Expiration Handling)

```swift
protocol SubscriptionService {
    func checkSubscriptionStatus() async throws -> Bool
    func purchaseMonthly() async throws -> Bool
    func purchaseYearly() async throws -> Bool
    func restorePurchases() async throws -> Bool
}

class SubscriptionServiceImpl: SubscriptionService {
    private let userRepo: UserRepository
    private let screenTimeService: ScreenTimeService
    
    func checkSubscriptionStatus() async throws -> Bool {
        let customerInfo = try await Purchases.shared.customerInfo()
        let isPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        // Update local user
        if var user = try userRepo.getCurrentUser() {
            let wasPremium = user.isPremium
            user.isPremium = isPremium
            user.subscriptionExpiryDate = customerInfo.entitlements["premium"]?.expirationDate
            try await userRepo.updateUser(user)
            
            // If subscription just expired, remove shields
            if wasPremium && !isPremium {
                try await screenTimeService.removeAllShields()
            }
        }
        
        return isPremium
    }
    
    func purchaseMonthly() async throws -> Bool {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.monthly else {
            throw SubscriptionError.packageNotFound
        }
        
        let result = try await Purchases.shared.purchase(package: package)
        
        // Update user
        if var user = try userRepo.getCurrentUser() {
            user.isPremium = true
            user.subscriptionExpiryDate = result.customerInfo.entitlements["premium"]?.expirationDate
            try await userRepo.updateUser(user)
        }
        
        return result.customerInfo.entitlements["premium"]?.isActive == true
    }
    
    func purchaseYearly() async throws -> Bool {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.annual else {
            throw SubscriptionError.packageNotFound
        }
        
        let result = try await Purchases.shared.purchase(package: package)
        
        // Update user
        if var user = try userRepo.getCurrentUser() {
            user.isPremium = true
            user.subscriptionExpiryDate = result.customerInfo.entitlements["premium"]?.expirationDate
            try await userRepo.updateUser(user)
        }
        
        return result.customerInfo.entitlements["premium"]?.isActive == true
    }
    
    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        let isPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        // Update user
        if var user = try userRepo.getCurrentUser() {
            user.isPremium = isPremium
            user.subscriptionExpiryDate = customerInfo.entitlements["premium"]?.expirationDate
            try await userRepo.updateUser(user)
        }
        
        return isPremium
    }
}
```

### 5.2 ScreenTimeService (with Shield Removal)

```swift
protocol ScreenTimeService {
    func requestAuthorization() async throws
    func getBlockedApps(userId: String) async throws -> [BlockedApp]
    func saveBlockedApps(_ apps: [BlockedApp]) async throws
    func startBlockingSession(appTokens: [ApplicationToken]) async throws
    func endBlockingSession() async throws
    func removeAllShields() async throws // NEW: For subscription expiration
}

class ScreenTimeServiceImpl: ScreenTimeService {
    private let screenTimeRepo: ScreenTimeRepository
    
    func requestAuthorization() async throws {
        let center = AuthorizationCenter.shared
        try await center.requestAuthorization(for: .individual)
    }
    
    func startBlockingSession(appTokens: [ApplicationToken]) async throws {
        let store = ManagedSettingsStore()
        let applications = Set(appTokens.compactMap(\.application))
        store.shield.applications = applications
        try await screenTimeRepo.saveActiveSession(appTokens: appTokens)
    }
    
    func endBlockingSession() async throws {
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        try await screenTimeRepo.clearActiveSession()
    }
    
    func removeAllShields() async throws {
        let store = ManagedSettingsStore()
        
        // Remove ALL shields (when subscription expires)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // Clear active session
        try await screenTimeRepo.clearActiveSession()
        
        // Note: User's saved app list remains in SwiftData
        // When they resubscribe, settings are preserved
    }
}
```

### 5.3 SessionService (with Streak Logic)

```swift
protocol SessionService {
    func createSession(session: Session) async throws
    func getRecentSessions(userId: String, limit: Int) async throws -> [Session]
    func updateStreak(after session: Session) async throws
}

class SessionServiceImpl: SessionService {
    private let sessionRepo: SessionRepository
    private let userRepo: UserRepository

    func createSession(session: Session) async throws {
        // Engagement counts immediately - no minimum time required

        // Save session
        try await sessionRepo.createSession(session)

        // Update streak
        try await updateStreak(after: session)
    }

    func updateStreak(after session: Session) async throws {
        // Engagement counts immediately - no minimum time required

        guard var user = try userRepo.getUserById(session.userId) else { return }

        let today = Calendar.current.startOfDay(for: Date())

        guard let lastEngagement = user.lastEngagementDate else {
            // First engagement
            user.currentStreak = 1
            user.longestStreak = 1
            user.lastEngagementDate = today
            try await userRepo.updateUser(user)
            return
        }

        let lastDay = Calendar.current.startOfDay(for: lastEngagement)

        if Calendar.current.isDate(today, equalTo: lastDay, toGranularity: .day) {
            // Already engaged today
            return
        } else if Calendar.current.isDate(today, inSameDayAs: lastEngagement.addingTimeInterval(86400)) {
            // Yesterday → today (consecutive)
            user.currentStreak += 1
            if user.currentStreak > user.longestStreak {
                user.longestStreak = user.currentStreak
            }
        } else {
            // Missed days
            user.currentStreak = 1
        }

        user.lastEngagementDate = today
        try await userRepo.updateUser(user)
    }
}
```

---

## 6. AUDIO PLAYBACK (Background Enabled)

### 6.1 AudioPlayerHelper Implementation

```swift
import AVFoundation
import MediaPlayer

class AudioPlayerHelper: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    var onFinish: (() -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Background Audio Setup
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Enable background audio
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Load & Play
    
    func loadAudio(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe duration
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                if let duration = self?.player?.currentItem?.asset.duration {
                    self?.duration = CMTimeGetSeconds(duration)
                }
            }
        }
        
        // Observe progress
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
        
        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        onFinish?()
    }
    
    // MARK: - Now Playing Info (Control Center)
    
    func updateNowPlayingInfo(surahName: String, reciterName: String) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = surahName
        nowPlayingInfo[MPMediaItemPropertyArtist] = reciterName
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
```

### 6.2 Info.plist Configuration

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### 6.3 Usage in ListenSessionViewmodel

```swift
@MainActor
final class ListenSessionViewmodel: ObservableObject {
    @Published var selectedSurahs: [Surah] = []
    @Published var selectedReciter: Reciter = .default
    @Published var selectedApps: [BlockedApp] = []
    @Published var isSessionActive: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var currentSurah: Surah?
    @Published var currentSurahIndex: Int = 0
    
    private var audioPlayer = AudioPlayerHelper()
    private var timer: Timer?
    
    func startSession() async {
        // STEP 1: Save preferences FIRST
        UserDefaults.standard.set(selectedSurahs.map(\.number), forKey: "lastSelectedSurahs")
        UserDefaults.standard.set(selectedReciter.id, forKey: "lastSelectedReciter")
        
        // STEP 2: Apply shield
        try await screenTimeService.startBlockingSession(
            appTokens: selectedApps.map { ApplicationToken(data: $0.appToken) }
        )
        
        // STEP 3: Load audio
        let audioResponse = try await quranService.getAudioURL(
            surahNumber: selectedSurahs[0].number,
            reciterId: selectedReciter.id
        )
        
        audioPlayer.loadAudio(url: audioResponse.audioUrl)
        audioPlayer.onFinish = { [weak self] in
            Task { @MainActor in
                await self?.playNextSurah()
            }
        }
        
        // STEP 4: Play
        audioPlayer.play()
        audioPlayer.updateNowPlayingInfo(
            surahName: selectedSurahs[0].englishName,
            reciterName: selectedReciter.name
        )
        
        // STEP 5: Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
        
        // STEP 6: Update UI
        isSessionActive = true
        currentSurah = selectedSurahs[0]
        currentSurahIndex = 0
    }
    
    func playNextSurah() async {
        currentSurahIndex += 1
        
        if currentSurahIndex < selectedSurahs.count {
            let nextSurah = selectedSurahs[currentSurahIndex]
            currentSurah = nextSurah
            
            let audioResponse = try await quranService.getAudioURL(
                surahNumber: nextSurah.number,
                reciterId: selectedReciter.id
            )
            
            audioPlayer.loadAudio(url: audioResponse.audioUrl)
            audioPlayer.play()
            audioPlayer.updateNowPlayingInfo(
                surahName: nextSurah.englishName,
                reciterName: selectedReciter.name
            )
        } else {
            // All surahs finished
            await endSession()
        }
    }
    
    func endSession() async {
        // Stop timer
        timer?.invalidate()
        timer = nil
        
        // Stop audio
        audioPlayer.stop()
        
        // Check subscription
        let isPremium = try await subscriptionService.checkSubscriptionStatus()
        
        if isPremium {
            // Remove session shield
            try await screenTimeService.endBlockingSession()
            
            // Save session
            let session = Session(
                userId: user.id,
                sessionType: "listen",
                surahNumber: selectedSurahs.first!.number,
                durationSeconds: elapsedSeconds,
                reciterId: selectedReciter.id
            )
            try await sessionService.createSession(session)
            
            // Navigate
            router.navigateBack()
        } else {
            // Subscription expired
            try await screenTimeService.removeAllShields()
            router.navigate(to: .paywall)
        }
    }
}
```

---

## 7. DATABASE SCHEMA

### 7.1 SwiftData Models

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
    
    // Streak
    var currentStreak: Int
    var longestStreak: Int
    var lastEngagementDate: Date?
    
    @Relationship(deleteRule: .cascade) var sessions: [Session]?
    @Relationship(deleteRule: .cascade) var blockedApps: [BlockedApp]?
    @Relationship(deleteRule: .cascade) var appTimeLimits: [AppTimeLimit]?
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

---

## 8. NAVIGATION FLOWS

### 8.1 First-Time User

```
Auth
    ↓
Onboarding Survey (4 screens)
    ↓
Paywall
    ↓
Subscribe (3 or 7 day trial)
    ↓
Screen Time Permission
    ↓
App Selection + Time Limits
    ↓
MainTabView (Quran tab selected)
```

### 8.2 Returning User (Active Subscription)

```
Auth
    ↓
Check subscription: ACTIVE
    ↓
MainTabView (Quran tab)
```

### 8.3 Returning User (Expired Subscription)

```
Auth
    ↓
Check subscription: EXPIRED
    ↓
Remove all shields
    ↓
Paywall
    ↓
Must resubscribe
```

### 8.4 Mid-Session Expiration

```
User in listening session
    ↓
Subscription expires (background)
    ↓
Session CONTINUES (don't interrupt)
    ↓
Session ends
    ↓
Check subscription: EXPIRED
    ↓
Remove all shields + Show paywall
```

---

## 9. PERFORMANCE CONSIDERATIONS

### 9.1 Text Caching

- Surah list: Cache indefinitely (~50KB total)
- Surah content: Cache 30 days (~10-50KB each)
- Store in SwiftData with expiry timestamps
- Check cache before API call

### 9.2 Audio Streaming

- Stream directly (no local storage)
- AVPlayer handles buffering automatically
- Set preferred buffer: 30 seconds
- Background playback enabled

### 9.3 Memory Management

- Load surahs lazily (not all at once)
- Release audio player when session ends
- Clear cached surahs if storage exceeds limit

---

## 10. SCREEN TIME API INTEGRATION

### 10.1 Overview

Deen First uses iOS Screen Time API (FamilyControls framework) to block apps during listening sessions and enforce daily time limits. The implementation follows Apple's extension-based architecture.

**Architecture Components**:
```
┌─────────────────────────────────────────────────┐
│          Main App (Deen First)                 │
│  - User configuration                            │
│  - Rule management                               │
│  - UI/UX                                         │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│          App Groups (Shared Data)                │
│  - tokenMapping (app tokens)                     │
│  - categoryTokens                                │
│  - Rule configurations                           │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│          Extensions                              │
│  ┌───────────────────────────────────────┐      │
│  │  DeviceActivityMonitor                │      │
│  │  - Background monitoring              │      │
│  │  - Shield application                 │      │
│  │  - Event handling                     │      │
│  └───────────────────────────────────────┘      │
│  ┌───────────────────────────────────────┐      │
│  │  ShieldConfiguration                  │      │
│  │  - Custom blocked screen UI           │      │
│  │  - Branding                           │      │
│  └───────────────────────────────────────┘      │
└─────────────────────────────────────────────────┘
```

### 10.2 Project Setup Requirements

#### 10.2.1 Required Frameworks
- **FamilyControls**: Authorization and app selection picker
- **ManagedSettings**: Shield configuration
- **DeviceActivity**: Activity monitoring and events

#### 10.2.2 Entitlements Configuration

**Main App (`DeenFirst.entitlements`)**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.aydev.deenfirst</string>
    </array>
</dict>
</plist>
```

**DeviceActivityMonitor Extension (`ScreenTimeMonitor.entitlements`)**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.family-controls</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.aydev.deenfirst</string>
    </array>
</dict>
</plist>
```

**Critical**: Both app and extension MUST use the same App Group identifier for communication.

#### 10.2.3 App Group Configuration

**App Group Identifier**: `group.com.aydev.deenfirst`

**Shared UserDefaults Access**:
```swift
private let sharedDefaults = UserDefaults(suiteName: "group.com.aydev.deenfirst")
```

This allows the main app to write configuration and extensions to read it.

### 10.3 Extension Architecture

#### 10.3.1 DeviceActivityMonitor Extension

**Purpose**: Background process that monitors app usage and applies shields when limits are reached.

**Key Responsibilities**:
- Monitor app usage against configured limits
- Apply shields when thresholds reached
- Clear shields at interval boundaries (midnight)
- Handle multiple concurrent rules

**File**: `ScreenTimeMonitor/DeviceActivityMonitorExtension.swift`

**Critical Methods**:
```swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    // Called when monitoring interval starts (e.g., new day at midnight)
    override func intervalDidStart(for activity: DeviceActivityName) {
        let store = ManagedSettingsStore()
        store.clearAllSettings()
        // Reset shields for new day
    }
    
    // Called when usage threshold reached (limit exceeded)
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name, 
        activity: DeviceActivityName
    ) {
        // Apply shield for this specific app/category
        applyShield(for: event)
    }
    
    // Called when interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        let store = ManagedSettingsStore()
        store.clearAllSettings()
    }
}
```

#### 10.3.2 ShieldConfiguration Extension

**Purpose**: Custom UI shown when apps are blocked.

**File**: `Shield/ShieldConfigurationExtension.swift`

**Implementation**:
```swift
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            icon: UIImage(named: "shield-icon") ?? UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(
                text: "Deen First", 
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Time to read Quran instead 🌙", 
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close", 
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#5C64D0") // Brand color
        )
    }
}
```

### 10.4 Implementation for Deen First

#### 10.4.1 Use Cases

**For V1, we implement TWO scenarios**:

1. **Listening Session Blocking** (Temporary)
   - User starts listening session
   - Selected apps blocked DURING session only
   - Shield removed when session ends

2. **Daily App Limits** (Persistent)
   - User sets 30-min/day limit for Instagram
   - App accessible until limit reached
   - Shield applied automatically when limit hit
   - Resets at midnight

**NOT implementing**:
- Time-of-day blocking (e.g., 9 AM - 5 PM only) → V2
- Category blocking (block all "Social" apps) → V2
- Custom schedules beyond daily reset → V2

#### 10.4.2 High-Level Implementation Flow

**Listening Session**:
```swift
// When user starts listening session
func startBlockingSession(appTokens: [ApplicationToken]) async throws {
    let store = ManagedSettingsStore()
    
    // Convert tokens to shieldable format
    let applications = Set(appTokens.compactMap(\.application))
    
    // Apply shield immediately
    store.shield.applications = applications
    
    // No DeviceActivity monitoring needed (manual control)
}

// When session ends
func endBlockingSession() async throws {
    let store = ManagedSettingsStore()
    
    // Remove session shield
    store.shield.applications = nil
}
```

**Daily Limits**:
```swift
// When user configures daily limit (e.g., Instagram 30 min/day)
func setDailyLimit(app: ApplicationToken, minutes: Int) async throws {
    let center = DeviceActivityCenter()
    
    // Create 24-hour schedule (midnight to midnight)
    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59),
        repeats: true
    )
    
    // Create event: trigger when 30 minutes used
    let threshold = DateComponents(minute: minutes)
    let event = DeviceActivityEvent(
        applications: [app],
        threshold: threshold
    )
    
    // Start monitoring
    try center.startMonitoring(
        .init(rawValue: "dailyLimit_\(app.bundleIdentifier)"),
        during: schedule,
        events: [.init(rawValue: "limitReached"): event]
    )
    
    // Extension will apply shield when threshold reached
}
```

#### 10.4.3 Shield Removal on Subscription Expiration

**Critical**: When subscription expires, remove ALL shields.

```swift
func removeAllShields() async throws {
    let store = ManagedSettingsStore()
    let center = DeviceActivityCenter()
    
    // Remove all active shields
    store.clearAllSettings()
    
    // Stop all monitoring activities
    let activities = center.activities // Get all active activities
    for activity in activities {
        center.stopMonitoring([activity])
    }
}
```

This ensures users don't stay blocked after subscription expires.

### 10.5 Data Persistence

**What's Stored in App Groups**:

```swift
// Token mapping for shield application
// Key: App bundle ID or UUID
// Value: Encoded ApplicationToken
sharedDefaults.set(tokenMapping, forKey: "tokenMapping")

// Example structure
let tokenMapping: [String: Data] = [
    "com.instagram.app": encodedToken1,
    "com.tiktok.app": encodedToken2
]
```

**What's Stored in SwiftData** (Main App):

```swift
@Model
class BlockedApp {
    var id: String
    var userId: String
    var appBundleId: String
    var appName: String
    var appToken: Data // ApplicationToken serialized
    var addedAt: Date
}

@Model
class AppTimeLimit {
    var id: String
    var userId: String
    var appBundleId: String
    var limitMinutes: Int
    var scheduleType: String // "allDay" for V1
    var isEnabled: Bool
}
```

### 10.6 Testing Considerations

**Simulator Limitations**:
- Screen Time API does NOT work in simulator
- Must test on physical device (iOS 17+)
- TestFlight works for Screen Time features

**Testing Checklist**:
1. Authorization flow (permission granted/denied)
2. App selection picker (FamilyActivityPicker)
3. Shield application (immediate)
4. Shield customization (branding, text)
5. Daily limit threshold (time-based)
6. Midnight reset (wait until 12 AM or manually advance date)
7. Multiple apps simultaneously blocked
8. Subscription expiration → shield removal

### 10.7 Common Issues & Solutions

**Issue**: Shield doesn't apply
- **Solution**: Verify App Group identifier matches in both entitlements
- **Solution**: Check authorization status with `AuthorizationCenter.shared.authorizationStatus`

**Issue**: Extension crashes
- **Solution**: Ensure extension has `com.apple.developer.family-controls` entitlement
- **Solution**: Check shared UserDefaults access with correct suite name

**Issue**: Shields persist after removal
- **Solution**: Call `store.clearAllSettings()` explicitly
- **Solution**: Restart device (known iOS bug)

**Issue**: Midnight reset doesn't work
- **Solution**: Verify `intervalDidStart` is called in extension
- **Solution**: Check schedule has `repeats: true`

### 10.8 Implementation Reference

**For detailed implementation including**:
- Complete extension setup
- Event system architecture
- Rule types (Time Limit, Time of Day, All Day)
- Advanced shield management
- Code examples and patterns
- Troubleshooting guide

**See**: `SCREEN_TIME_API_GUIDE.md` (comprehensive 975-line reference)

**Key Sections in Guide**:
- Extension Architecture (Lines 143-217)
- App Limit Implementation (Lines 356-424)
- Shield System (Lines 565-743)
- Event System (Lines 885-913)

---

## 11. DEVELOPMENT SETUP & STANDARDS

### 11.1 Overview

Deen First follows Clean Architecture + MVVM patterns with Tuist for project management and automated build tooling. All development standards, project setup, and architectural patterns are documented in companion guides.

**Document Structure**:
```
📄 PROJECT_SETUP.md
   ↓ Project initialization with Tuist

📄 PROJECT_RULES.md
   ↓ Architecture patterns & code style

📄 DEEN_FIRST_SYSTEM_DESIGN.md (this document)
   ↓ App-specific architecture
```

### 11.2 Project Initialization

**For complete project setup including**:
- Tuist installation and configuration
- Makefile automation
- Environment variables (.env)
- Folder structure generation
- Dependency management
- Xcode project generation
- Common Tuist commands

**See**: `PROJECT_SETUP.md`

**Quick Start**:
```bash
# 1. Install Tuist
curl -Ls https://install.tuist.io | bash

# 2. Create project structure
mkdir DeenFirst && cd DeenFirst
mkdir -p Sources/{Core,Data,Domain,Presentation,Helper,Utils}
mkdir -p Resources/Assets.xcassets

# 3. Create config files
touch Project.swift Tuist/Package.swift .env Makefile

# 4. Configure & generate
make  # Runs: install → generate → build
```

### 11.3 Architecture Standards

**For complete coding standards including**:
- Folder structure conventions
- Naming conventions (files, classes, variables)
- View/ViewModel patterns
- Service/Repository patterns
- Dependency injection (DIContainer)
- Navigation patterns (Router)
- Component patterns
- Entity patterns
- Error handling
- SwiftUI style guide
- Threading rules (@MainActor)

**See**: `PROJECT_RULES.md`

### 11.4 Key Patterns for Deen First

#### 11.4.1 Folder Structure

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
│       ├── UserRepository.swift
│       ├── SessionRepository.swift
│       └── ScreenTimeRepository.swift
├── Domain/
│   ├── Entities/
│   │   ├── user.swift
│   │   ├── surah.swift
│   │   ├── session.swift
│   │   └── blocked_app.swift
│   └── Services/
│       ├── QuranService.swift
│       ├── AuthService.swift
│       ├── SessionService.swift
│       ├── SubscriptionService.swift
│       └── ScreenTimeService.swift
├── Presentation/
│   ├── Components/
│   │   ├── CustomButton.swift
│   │   ├── SurahCard.swift
│   │   ├── StreakBadge.swift
│   │   └── AudioPlayerControls.swift
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── SurveyView.swift
│   │   └── OnboardingViewmodel.swift
│   ├── Auth/
│   │   ├── AuthView.swift
│   │   └── AuthViewmodel.swift
│   ├── Paywall/
│   │   ├── PaywallView.swift
│   │   └── PaywallViewmodel.swift
│   ├── MainTabs/
│   │   ├── MainTabView.swift
│   │   ├── QuranTab/
│   │   ├── BlockingTab/
│   │   └── SettingsTab/
│   └── ListenSession/
│       ├── ListenSessionView.swift
│       └── ListenSessionViewmodel.swift
├── Helper/
│   └── (Add only if needed - see Section 3.2)
├── Utils/
│   └── Extensions.swift
├── RootView.swift
└── DeenFirstApp.swift
```

#### 11.4.2 ViewModel Pattern Example

```swift
@MainActor
final class QuranTabViewmodel: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = true
    @Published var user: User?
    
    private let quranService: QuranService
    private let userRepo: UserRepository
    
    init() {
        self.quranService = DIContainer.shared.quranService
        self.userRepo = DIContainer.shared.userRepository
    }
    
    func load() {
        Task {
            do {
                isLoading = true
                user = try userRepo.getCurrentUser()
                surahs = try await quranService.getAllSurahs()
            } catch {
                print("Error loading: \(error)")
            }
            isLoading = false
        }
    }
}
```

**Key Rules**:
- `@MainActor` decorator always
- `final class {Name}Viewmodel: ObservableObject`
- Inject dependencies via `DIContainer.shared` in `init()`
- `@Published var` for reactive state
- Wrap async work in `Task { }`
- Set `isLoading = true` before, `false` after
- Use `do/catch` for error handling

#### 11.4.3 Service Pattern Example

```swift
protocol QuranService {
    func getAllSurahs() async throws -> [Surah]
    func getSurahById(id: Int, translation: String) async throws -> Surah
    func getAudioURL(surahNumber: Int, reciterId: Int) async throws -> URL
}

class QuranServiceImpl: QuranService {
    private let repo: QuranRepository
    
    init(repo: QuranRepository) {
        self.repo = repo
    }
    
    func getAllSurahs() async throws -> [Surah] {
        return try await repo.getAllSurahs()
    }
    
    func getSurahById(id: Int, translation: String) async throws -> Surah {
        return try await repo.getSurahById(id: id, translation: translation)
    }
    
    func getAudioURL(surahNumber: Int, reciterId: Int) async throws -> URL {
        let response = try await repo.getAudioURL(
            surahNumber: surahNumber,
            reciterId: reciterId
        )
        return response.audioUrl
    }
}
```

**Key Rules**:
- Protocol-first design
- Implementation: `{Name}ServiceImpl: {Name}Service`
- Inject repositories in `init()`
- Business logic layer (coordinates repositories)
- Use `async throws` for async methods

#### 11.4.4 DIContainer Configuration

```swift
final class DIContainer {
    static let shared: DIContainer = {
        let container = try? ModelContainer(
            for: User.self, Session.self, 
            BlockedApp.self, AppTimeLimit.self
        )
        return DIContainer(modelContainer: container ?? inMemoryContainer)
    }()
    
    private let modelContainer: ModelContainer
    
    private init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Data Sources
    
    lazy var localDataSource: LocalDataSource = 
        LocalDataSource(container: modelContainer)
    
    lazy var quranAPIDataSource: QuranAPIDataSource = 
        QuranAPIDataSource()
    
    // MARK: - Repositories
    
    lazy var userRepository: UserRepository = 
        UserRepositoryImpl(localDataSource: localDataSource)
    
    lazy var quranRepository: QuranRepository = 
        QuranRepositoryImpl(
            apiDataSource: quranAPIDataSource,
            localDataSource: localDataSource
        )
    
    lazy var sessionRepository: SessionRepository = 
        SessionRepositoryImpl(localDataSource: localDataSource)
    
    lazy var screenTimeRepository: ScreenTimeRepository = 
        ScreenTimeRepositoryImpl()
    
    // MARK: - Services
    
    lazy var authService: AuthService = 
        AuthServiceImpl(repo: userRepository)
    
    lazy var quranService: QuranService = 
        QuranServiceImpl(repo: quranRepository)
    
    lazy var sessionService: SessionService = 
        SessionServiceImpl(
            sessionRepo: sessionRepository,
            userRepo: userRepository
        )
    
    lazy var subscriptionService: SubscriptionService = 
        SubscriptionServiceImpl(
            userRepo: userRepository,
            screenTimeService: screenTimeService
        )
    
    lazy var screenTimeService: ScreenTimeService = 
        ScreenTimeServiceImpl(repo: screenTimeRepository)
}
```

#### 11.4.5 Navigation Pattern

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

**RootView Setup**:
```swift
struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var authVM = AuthViewmodel()
    @StateObject private var quranTabVM = QuranTabViewmodel()
    @StateObject private var paywallVM = PaywallViewmodel()
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            AuthView()
                .navigationDestination(for: Router.Route.self) { route in
                    destinationView(for: route)
                }
        }
        .environmentObject(router)
        .environmentObject(authVM)
        .environmentObject(quranTabVM)
        .environmentObject(paywallVM)
    }
    
    @ViewBuilder
    private func destinationView(for route: Router.Route) -> some View {
        switch route {
        case .auth:
            AuthView()
        case .onboarding:
            OnboardingView()
        case .paywall:
            PaywallView()
        case .mainTabs:
            MainTabView()
        case .surahDetail(let surahId):
            SurahDetailView(surahId: surahId)
        case .listenSession:
            ListenSessionView()
        default:
            EmptyView()
        }
    }
}
```

### 11.5 Project Configuration

#### 11.5.1 Required Dependencies (Tuist/Package.swift)

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init([
        .remote(
            url: "https://github.com/RevenueCat/purchases-ios.git",
            requirement: .upToNextMajor(from: "5.0.0")
        )
    ])
)
```

#### 11.5.2 Project.swift Configuration

```swift
import ProjectDescription

let project = Project(
    name: "DeenFirst",
    targets: [
        .target(
            name: "DeenFirst",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.aydev.deenfirst",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "UILaunchScreen": [:],
                "NSFamilyControlsUsageDescription": "Deen First needs permission to block distracting apps during your Quran focus sessions.",
                "UIBackgroundModes": ["audio"]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "RevenueCat")
            ]
        ),
        
        // DeviceActivityMonitor Extension
        .target(
            name: "ScreenTimeMonitor",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.aydev.deenfirst.ScreenTimeMonitor",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.device-activity.monitor",
                    "NSExtensionPrincipalClass": "DeviceActivityMonitorExtension"
                ]
            ]),
            sources: ["ScreenTimeMonitor/**"],
            dependencies: []
        ),
        
        // ShieldConfiguration Extension
        .target(
            name: "Shield",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.aydev.deenfirst.Shield",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.shield-configuration",
                    "NSExtensionPrincipalClass": "ShieldConfigurationExtension"
                ]
            ]),
            sources: ["Shield/**"],
            dependencies: []
        )
    ]
)
```

#### 11.5.3 Environment Variables (.env)

```bash
TUIST_COMPANY_ID=com.aydev
TUIST_TEAM_ID=YOUR_TEAM_ID
TUIST_BASE_BUNDLE_ID=com.aydev.deenfirst
```

#### 11.5.4 Makefile

```makefile
.PHONY: all env generate build clean install test

all: clean install generate

generate:
	@echo "✓ Generating Xcode project..."
	@tuist generate

build:
	@echo "✓ Building app..."
	@xcodebuild -workspace DeenFirst.xcworkspace \
		-scheme DeenFirst \
		-destination 'platform=iOS Simulator,name=iPhone 15' \
		build | xcpretty

clean:
	@echo "✓ Cleaning..."
	@rm -rf DerivedData
	@tuist clean

install:
	@echo "✓ Installing dependencies..."
	@tuist install

test:
	@xcodebuild test \
		-workspace DeenFirst.xcworkspace \
		-scheme DeenFirst \
		-destination 'platform=iOS Simulator,name=iPhone 15'
```

### 11.6 Development Workflow

#### Day 1: Project Setup
```bash
# 1. Install Tuist
curl -Ls https://install.tuist.io | bash

# 2. Clone/create project
mkdir DeenFirst && cd DeenFirst

# 3. Create structure (see Section 11.4.1)

# 4. Copy Project.swift, Tuist/Package.swift from examples above

# 5. Configure environment
echo "TUIST_TEAM_ID=YOUR_TEAM_ID" > .env

# 6. Generate project
make
```

#### Day 2-16: Development
```bash
# Daily workflow
make generate  # Regenerate when adding files
make build     # Build and test
make clean     # Clean when needed
```

#### Testing on Device
```bash
# Screen Time API requires physical device (iOS 17+)
# Select device in Xcode
# Build & Run (Cmd+R)
```

### 11.7 Code Style Checklist

**Before Committing**:
- [ ] All ViewModels have `@MainActor`
- [ ] Services follow Protocol + Impl pattern
- [ ] Dependencies injected via DIContainer
- [ ] File names follow conventions (PascalCase views, snake_case entities)
- [ ] No force unwraps (!)
- [ ] Error handling with do/catch
- [ ] Loading states managed properly
- [ ] Navigation uses Router
- [ ] Components in Presentation/Components/
- [ ] No business logic in Views

### 11.8 Common Development Issues

**Issue**: Xcode project out of sync after adding files
- **Solution**: Run `make generate`

**Issue**: Dependencies not found
- **Solution**: Run `make install` then `make generate`

**Issue**: Build errors after merging
- **Solution**: `make clean` then `make`

**Issue**: Simulator doesn't show new assets
- **Solution**: Clean build folder (Cmd+Shift+K) and rebuild

**Issue**: Screen Time features don't work
- **Solution**: Must test on physical device (iOS 17+), simulator not supported

### 11.9 Quick Reference

| Task | Command |
|------|---------|
| Setup project | `make` |
| Generate Xcode project | `make generate` |
| Build app | `make build` |
| Clean build | `make clean` |
| Install dependencies | `make install` |
| Run tests | `make test` |
| Open in Xcode | `open DeenFirst.xcworkspace` |

**For Complete Documentation**:
- Project setup & Tuist: **PROJECT_SETUP.md**
- Code patterns & architecture: **PROJECT_RULES.md**
- Screen Time API: **SCREEN_TIME_API_GUIDE.md**

---

## 12. TIMELINE SUMMARY

**Total**: 16 days (Feb 3-18)

**Critical Path**:
1. Days 1-3: Infrastructure + Auth + Paywall
2. Days 4-6: Screen Time + Main Tabs + Quran
3. Days 7-10: Listening + Blocking + Settings + Streak
4. Days 11-12: Polish + Bug fixes
5. Days 13-15: TestFlight + Buffer
6. Day 16: Submission

**Risk Mitigation**:
- Built-in buffer days (15-17)
- Submit by Feb 18 (not earlier)
- Monitor review status closely

**Screen Time Testing Priority**:
- Day 4: Permission flow + basic shield test
- Day 9: Listening session blocking
- Day 11: Daily limits testing
- Day 13: Full integration test on device

---

**END OF SYSTEM DESIGN v3.0**
