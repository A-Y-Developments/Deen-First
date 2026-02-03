# Stack Research: Surah Focus

**Project:** iOS Quran + Screen Time Management App
**Researched:** 2025-02-03
**Overall Confidence:** HIGH

## Executive Summary

The 2025 iOS stack for Quran + Screen Time apps is mature and stable. Use Apple-first technologies: SwiftUI for UI, SwiftData for persistence, FamilyControls for Screen Time. Quran API is the clear winner for Quran data. RevenueCat 5.x is the standard for subscriptions.

**Primary recommendation:** iOS 17.0 + SwiftUI + SwiftData + FamilyControls + QuranAPI + RevenueCat 5.x + Tuist

---

## Core Technologies

### iOS Platform
| Choice | Version | Why |
|--------|---------|-----|
| **iOS Deployment Target** | **17.0** | FamilyControls requires iOS 16+, SwiftData stable in iOS 17+. iOS 17 gives you Screen Time API improvements |
| **Swift Version** | **5.9+** | Required for iOS 17 development, SwiftData, modern SwiftUI |
| **Xcode** | **15.0+** | SwiftData and iOS 17 SDK support |
| **Confidence** | **HIGH** | Official Apple requirements |

**Critical:** Your current Xcode project uses iOS 26.0 (future version). Must change to iOS 17.0.

**Fix:**
```swift
// In your project file or Package.swift
IPHONEOS_DEPLOYMENT_TARGET = 17.0
```

---

### UI Framework
| Choice | Version | Why |
|--------|---------|-----|
| **SwiftUI** | **iOS 17+** | Declarative UI, native Apple, perfect for Quran text rendering + modern app feel |
| **Navigation** | **NavigationStack** | iOS 16+ API, replaces NavigationView, better programmatic control |
| **State Management** | **@Observable (iOS 17)** | New observation framework, simpler than ObservableObject, better performance |

**Confidence:** HIGH

**Alternatives Considered:**
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftUI | UIKit | UIKit is battle-tested but verbose. SwiftUI is 2025 standard. Only use UIKit if you need complex custom views not yet supported |
| SwiftUI | ReactorKit | RxSwift-based, adds complexity. SwiftUI + @Observable is sufficient for this scope |

**2025 Update:** SwiftUI in iOS 17 includes:
- Scroll view improvements
- SF Symbols effects
- Better Sheet presentations
- Improved performance

**Sources:**
- [Hacking with Swift - What's new in SwiftUI iOS 17](https://www.hackingwithswift.com/articles/260/whats-new-in-swiftui-for-ios-17)
- [WWDC 2025 - What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/256/)

---

## Architecture

### Clean Architecture + MVVM
**Pattern:** Clean Architecture layers + MVVM for UI

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (SwiftUI Views + ViewModels)           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│            Domain Layer                 │
│  (Use Cases, Entities, Gateway Protocols)│
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│            Data Layer                   │
│  (Repository Implementations, API, DB)  │
└─────────────────────────────────────────┘
```

**Confidence:** MEDIUM

**Why this pattern:**
- Separates business logic from UI
- Testable without SwiftUI
- Scalable for future features
- Industry standard for iOS in 2025

**2025 Context:** There's active debate about MVVM vs MV in SwiftUI. MVVM is still safer for apps with complex business logic like yours (blocking rules, subscription state).

**Sources:**
- [SwiftUI MVVM Explained & Built (2025)](https://www.youtube.com/watch?v=ellNNYTJBwg)
- [MV vs MVVM in SwiftUI (2025)](https://dev.to/yossabourne/mv-vs-mvvm-in-swiftui-2025-which-architecture-should-you-use-video-26nb)

---

## Data Persistence

### SwiftData
| Choice | Version | Why |
|--------|---------|-----|
| **SwiftData** | **iOS 17+** | Native replacement for Core Data, SwiftUI-native, simpler API |
| **Alternative** | Core Data | Only if you need advanced features like migration, CloudKit sync (you don't for V1) |

**Confidence:** HIGH

**Why SwiftData:**
- Declarative models (`@Model`)
- SwiftUI integration (`@Query`)
- No boilerplate vs Core Data
- Automatic persistence
- Concurrency by default

**2025 Updates:**
- Mature and stable since iOS 17
- Better performance than early releases
- Active community patterns

**Sources:**
- [SwiftData vs Core Data: Which Should You Use in 2025?](https://commitstudiogs.medium.com/swiftdata-vs-core-data-which-should-you-use-in-2025-61b3f3a1abb1)
- [The Art of SwiftData in 2025](https://medium.com/@matgnt/the-art-of-swiftdata-in-2025-from-scattered-pieces-to-a-masterpiece-1fd0cefd8d87)
- [SwiftUI Data Persistence in 2025](https://swift-pal.com/swiftui-data-persistence-in-2025-swiftdata-core-data-appstorage-scenestorage-explained-f10a012c7c00)

**Use SwiftData for:**
- User progress (which surahs read)
- Reading streaks
- Blocked apps configuration
- Subscription status cache

**Don't use SwiftData for:**
- Complex relationships (use Core Data)
- Cloud sync (V1 doesn't need it)

---

## Quran Data Sources

| API | URL | Reliability | Features | Recommendation |
|-----|-----|-------------|----------|----------------|
| **QuranAPI** | [quranapi.pages.dev](https://quranapi.pages.dev/) | HIGH (updated Nov 2025) | Verses, chapters, audio, no rate limit, no auth | ✅ **USE THIS** |
| **Quran.com API** | api.quran.com | HIGH | Official, comprehensive | Good but may need rate limiting |
| **QuranEngine** | github.com/quran/quran-ios | HIGH | Open-source Quran.com engine | Overkill for API use |
| **Al Quran Cloud** | alquran.cloud | MEDIUM | Community project | Less updated |

**Confidence:** HIGH

**Primary Choice: QuranAPI (quranapi.pages.dev)**

**Why QuranAPI:**
- **No authentication required** - simpler integration
- **No rate limits** - won't block users
- **Audio recitation support** - whole chapter audio (added 2025)
- **Simple JSON responses** - easy to parse
- **Active** - updated November 2025

**API Features:**
- Verses (ayahs) by chapter
- Chapter metadata
- Audio recitations
- Translations (check if your language is supported)

**Sources:**
- [Quran API Official Site](https://quranapi.pages.dev/)
- [QuranEngine GitHub (99% of Quran.com iOS app)](https://github.com/quran/quran-ios)

**Implementation Pattern:**
```swift
// Simple networking with URLSession
struct QuranAPIClient {
    static let baseURL = "https://quranapi.pages.dev/api"

    func fetchSurah(_ number: Int) async throws -> Surah {
        let url = "\(baseURL)/surah/\(number)"
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
        return try JSONDecoder().decode(Surah.self, from: data)
    }
}
```

---

## Screen Time Integration

### FamilyControls Framework
| Component | iOS Required | Purpose |
|-----------|--------------|---------|
| **FamilyControls** | iOS 16+ | Authorization UI, privacy protection |
| **ManagedSettings** | iOS 16+ | Set up app blocks, web domain blocks |
| **DeviceActivity** | iOS 16+ | Monitor screen time usage |

**Confidence:** HIGH

**Capabilities:**
- Block specific apps
- Block app categories (social media, games, etc.)
- Block web domains
- Time-based restrictions
- Override with biometric auth (after Quran reading)

**Limitations:**
- Requires entitlement from Apple (see App Store section)
- Privacy-focused: user must explicitly authorize
- Cannot modify Family Controls set by parents
- Authorization can be revoked by user anytime

**App Store Requirements (CRITICAL):**
1. **Family Controls Entitlement** - Must apply in Apple Developer account
2. **Privacy Policy** - Must explain Screen Time usage
3. **App Store Review** - May need to demonstrate legitimate use case
4. **Not for spying** - Cannot be used to monitor others without consent

**Sources:**
- [Apple: Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [A Developer's Guide to Screen Time APIs](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7)
- [WWDC 2021: Meet the Screen Time API](https://developer.apple.com/videos/play/wwdc2021/10123/)
- [WWDC 2022: What's New in Screen Time API](https://developer.apple.com/videos/play/wwdc2022/110336/)

**Implementation Pattern:**
```swift
import FamilyControls
import ManagedSettings

class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false

    func requestAuthorization() async {
        let center = AuthorizationCenter.shared
        isAuthorized = await center.requestAuthorization(for: .child)
    }

    func blockApps(_ bundleIdentifiers: [String]) {
        let store = ManagedSettingsStore()
        store.application.blockedApplications = Set(bundleIdentifiers)
    }
}
```

---

## Authentication

### Sign in with Apple
| Choice | Version | Why |
|--------|---------|-----|
| **Sign in with Apple** | **AuthenticationServices** | Required by Apple if you offer other social logins (you don't, but still best practice), secure, no password management |

**Confidence:** HIGH

**Why Sign in with Apple:**
- Apple requirement if you have other sign-in options (best practice anyway)
- No password database to secure
- Biometric auth built-in
- User email (can be hidden relay)
- User name included
- Free, no backend needed

**Alternatives Rejected:**
- **Firebase Auth** - Overkill, adds dependency, requires Google setup
- **Custom email/password** - Security burden, password resets, not MVP
- **Google Sign in** - Not needed for V1 iOS-only

**Sources:**
- [Apple: Implementing Sign in with Apple](https://developer.apple.com/documentation/AuthenticationServices/implementing-user-authentication-with-sign-in-with-apple)
- [Sign in with Apple in SwiftUI - Complete Guide](https://medium.com/@mohamed.hacine00/implementing-sign-in-with-apple-in-swiftui-a-complete-guide-40fae22cdf1d)
- [Sign in with Apple HIG](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)

**Implementation:**
```swift
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    authManager.handleAuthorization(authorization)
                case .failure(let error):
                    print(error)
                }
            }
        )
    }
}
```

---

## Monetization

### RevenueCat
| Choice | Version | Why |
|--------|---------|-----|
| **RevenueCat** | **5.0.0 < 6.0.0** | Industry standard, handles StoreKit complexity, free tier, paywalls, analytics |

**Confidence:** HIGH

**Why RevenueCat:**
- **StoreKit 2 support** - Full end-to-end flow
- **No backend required** - Dashboard handles everything
- **Paywalls** - No-code paywall builder, A/B testing
- **Analytics** - Revenue, conversion, churn metrics
- **Customer Center** - Users can manage subscriptions
- **Offline entitlements** - Works without network
- **Webhooks** - For server-side events (if you add backend later)

**Installation:**
```bash
# Swift Package Manager (Recommended)
https://github.com/RevenueCat/purchases-ios-spm.git
# Up to next major: 5.0.0 < 6.0.0
```

Or via CocoaPods:
```ruby
pod 'RevenueCat', '~> 5.2'
```

**Free Tier:**
- Free until $2,500/month revenue
- Then 1% of tracked revenue
- All features included

**Alternatives Rejected:**
- **Native StoreKit** - Too complex, lots of edge cases, receipt validation
- **Qonversion** - Less popular, smaller community
- **OneShot** - Limited feature set

**Sources:**
- [RevenueCat iOS Installation Guide](https://docs.revenuecat.com/docs/getting-started/installation/ios)
- [RevenueCat Changelog](https://www.revenuecat.com/changelog)
- [CocoaPods - RevenueCat](https://cocoapods.org/pods/RevenueCat)

**Pricing for Your App:**
- Monthly: $4.99
- Yearly: $29.99 (save ~50%)
- Free trial: 7 days (recommended)

**Implementation Pattern:**
```swift
import RevenueCat

class SubscriptionManager: ObservableObject {
    @Published var hasAccess = false

    init() {
        Purchases.configure(withAPIKey: "your_key")
        checkSubscriptionStatus()
    }

    func purchase() async {
        do {
            let package = try await getMonthlyPackage()
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled == false {
                hasAccess = true
            }
        } catch {
            print(error)
        }
    }
}
```

---

## Audio Playback

### AVFoundation
| Choice | Version | Why |
|--------|---------|-----|
| **AVFoundation** | **Native iOS 17+** | Background audio, system controls, battle-tested |

**Confidence:** HIGH

**Why AVFoundation:**
- Background playback required
- System audio controls (lock screen, control center)
- Handles interruptions (calls, other audio)
- No dependencies

**Capabilities:**
- Play Quran recitation audio
- Background playback when app closed
- Audio session management
- Now Playing info

**Setup Required:**
```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Sources:**
- [Apple: Configuring your app for media playback](https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback)
- [How to play audio in background using AVFoundation (2025)](https://uiswift.com/enable-background-audio-playback/)
- [WWDC 2025: Enhance audio recording capabilities](https://developer.apple.com/videos/play/wwdc2025/251/)

**Alternatives Rejected:**
- **AudioKit** - Overkill, adds 20MB+
- ** MediaPlayer (old)** - Deprecated, use AVFoundation

---

## Build System

### Tuist
| Choice | Version | Why |
|--------|---------|-----|
| **Tuist** | **4.x (2024+)** | Faster builds, scalable, Swift-based config, caching |

**Confidence:** MEDIUM

**Why Tuist:**
- **90% build time reduction** possible with modular architecture
- **Swift configuration** - No more complex Xcode project files
- **Caching** - Remote and local cache speeds up builds
- **Scalable** - Designed for large projects (your app will grow)
- **Works on top of Xcode** - Not a replacement, enhancement
- **AI-friendly** - 2025 focus on AI agent workflows

**Installation:**
```bash
curl -Ls https://install.tuist.dev | bash
```

**For 16-day MVP:** Tuist might be overkill. Consider starting with Xcode project, migrate to Tuist later if build times become painful.

**Alternatives:**
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tuist | Xcode Project | Simpler for small apps, but slower builds, manual dependency management |
| Tuist | Swift Package Manager | Good for packages, not full apps |
| Tuist | XcodeGen | JSON config, less powerful than Tuist |

**Sources:**
- [Tuist 4 Announcement](https://tuist.dev/blog/2024/02/07/unveiling-tuist-4-and-tuist-cloud)
- [Tuist vs XcodeGen vs Bazel Comparison](https://betterprogramming.pub/guide-on-supercharging-ios-app-project-management-218d8e518582)
- [Getting Started with Tuist](https://www.kodeco.com/24508362-tuist-tutorial-for-xcode)

**Recommendation for V1:**
- **Start with Xcode project** - Faster to get going
- **Add Tuist in Phase 2** - When project grows or build times hurt

---

## What NOT to Use (and Why)

| Don't Use | Reason |
|-----------|--------|
| **UIKit** (unless necessary) | Verbose, not declarative, 2025 is SwiftUI era |
| **Core Data** (for V1) | SwiftData is simpler, sufficient for your needs |
| **RxSwift** | Overkill, adds complexity, SwiftUI + Combine is enough |
| **Alamofire** | URLSession is native, sufficient for API calls |
| **Firebase** | Not needed for V1 (no auth, no backend, no analytics needed yet) |
| **Realm** | SwiftData is native, better SwiftUI integration |
| **PromiseKit** | Swift async/await is native and cleaner |
| **React Native / Flutter** | You're building iOS native, use native tools |
| **GraphQL** | Your API is RESTful, GraphQL adds complexity |
| **Carthage** | Deprecated, use SPM or CocoaPods |

---

## Dependencies Summary

### Swift Package Manager (SPM)
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0")
]
```

### No External Dependencies For:
- SwiftUI (native)
- SwiftData (native)
- FamilyControls (native)
- AVFoundation (native)
- Sign in with Apple (native)
- URLSession (native)

### Optional (Add Later):
- Tuist - Build system (Phase 2)
- RevenueCatUI - Paywall UI templates

---

## Known Issues to Fix

### 1. iOS Deployment Target
**Problem:** Project uses iOS 26.0 (doesn't exist)
**Fix:** Set to iOS 17.0
**Where:** Xcode project settings or Tuist config

### 2. Team ID Hardcoded
**Problem:** Team ID in project file
**Fix:** Use `$(DEVELOPMENT_TEAM)` variable
**Where:** Project.pbxproj or Project.swift

---

## Research Gaps

### LOW Confidence Areas (Need Verification)

1. **Quran API Reliability**
   - What we know: QuranAPI.pages.dev is free, no rate limit
   - Unclear: Production uptime, response times at scale
   - Recommendation: Build in caching, have fallback to local Quran data

2. **FamilyControls Approval Process**
   - What we know: Entitlement required from Apple
   - Unclear: Approval timeline, rejection reasons
   - Recommendation: Apply early, prepare privacy policy

3. **RevenueCat for Quran App Category**
   - What we know: RevenueCat is standard
   - Unclear: Any religious content restrictions
   - Recommendation: Check App Store guidelines for religious apps

### Topics for Phase-Specific Research

1. **Offline Quran Storage** - Phase 2: Caching Quran data locally
2. **App Store Optimization** - Phase 8: Metadata, screenshots, keywords
3. **Analytics** - Phase 8: What to track, privacy considerations
4. **Cloud Sync** - Post-V1: Sync progress across devices (CloudKit?)

---

## Sources

### Primary (HIGH Confidence)
- [Apple: Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [RevenueCat iOS Installation Guide](https://docs.revenuecat.com/docs/getting-started/installation/ios)
- [QuranAPI Official Site](https://quranapi.pages.dev/)
- [Apple: Sign in with Apple Documentation](https://developer.apple.com/documentation/AuthenticationServices/implementing-user-authentication-with-sign-in-with-apple)
- [Apple: Configuring for media playback](https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback)

### Secondary (MEDIUM Confidence)
- [SwiftData vs Core Data 2025](https://commitstudiogs.medium.com/swiftdata-vs-core-data-which-should-you-use-in-2025-61b3f3a1abb1)
- [Developer's Guide to Screen Time APIs](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7)
- [Tuist 4 Announcement](https://tuist.dev/blog/2024/02/07/unveiling-tuist-4-and-tuist-cloud)
- [Sign in with Apple SwiftUI Guide](https://medium.com/@mohamed.hacine00/implementing-sign-in-with-apple-in-swiftui-a-complete-guide-40fae22cdf1d)

### Tertiary (LOW Confidence - Web Search Only)
- Various Medium articles and tutorials on SwiftUI best practices
- Community discussions on Reddit and Stack Overflow
- YouTube tutorials on implementation patterns

---

## Next Steps

1. **Fix iOS deployment target** - Change from 26.0 to 17.0
2. **Apply for Family Controls entitlement** - Do this early, approval takes time
3. **Set up RevenueCat account** - Get API keys, configure products
4. **Test QuranAPI** - Verify reliability, response times
5. **Create privacy policy** - Required for Screen Time features
6. **Start with Xcode project** - Add Tuist later if needed

---

**Last Updated:** 2025-02-03
**Valid Until:** 2025-03-03 (30 days - iOS ecosystem stable)
