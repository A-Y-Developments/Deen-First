# PHASE 1: FOUNDATION + PROJECT SETUP
**Timeline:** Days 1-2 (Feb 3-4)  
**Duration:** 2 full days  
**Goal:** Complete project structure, data models, core infrastructure, extensions configured

---

## PREREQUISITES

- [ ] Xcode installed (latest version)
- [ ] Tuist installed: `curl -Ls https://install.tuist.io | bash`
- [ ] xcpretty installed: `gem install xcpretty`
- [ ] Apple Team ID ready
- [ ] Physical iOS 17+ device for testing
- [ ] Mindcore project available at `/Users/adithyafp_/Projects/mindcore`

---

## PHASE OVERVIEW

This phase establishes the complete foundation:
1. Project configuration with Tuist (3 targets)
2. Complete folder structure
3. All SwiftData entity models
4. Core infrastructure (DIContainer, Router, HTTPClient)
5. Screen Time extensions setup
6. Unit tests for all entities and core components

**By end of Phase 1, you will have:**
- ✅ Clean Xcode workspace with 3 targets
- ✅ 7 entity models with 100% test coverage
- ✅ DIContainer, Router, HTTPClient implemented
- ✅ Screen Time extensions configured
- ✅ 20+ unit tests passing
- ✅ Project builds successfully

---

## TASK 1.1: PROJECT CONFIGURATION (Day 1 Morning - 2 hours)

### Step 1: Create Project Directory

```bash
cd ~/Projects
mkdir SurahFocus
cd SurahFocus
```

### Step 2: Create Tuist Configuration Files

**Create `Project.swift`:**

```swift
import ProjectDescription

let project = Project(
    name: "SurahFocus",
    options: .options(
        automaticSchemesOptions: .enabled(
            targetSchemeName: .targetName
        )
    ),
    targets: [
        // Main App Target
        .target(
            name: "SurahFocus",
            destinations: [.iPhone],
            product: .app,
            bundleId: Env.baseBundleId,
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "UILaunchScreen": [:],
                "NSFamilyControlsUsageDescription": "Surah Focus needs permission to block distracting apps during your Quran focus sessions.",
                "UIBackgroundModes": ["audio"]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "RevenueCat")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": Env.teamId,
                    "CODE_SIGN_STYLE": "Automatic"
                ]
            )
        ),
        
        // ScreenTimeMonitor Extension
        .target(
            name: "ScreenTimeMonitor",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "\(Env.baseBundleId).ScreenTimeMonitor",
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
        
        // Shield Extension
        .target(
            name: "Shield",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "\(Env.baseBundleId).Shield",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.shield-configuration",
                    "NSExtensionPrincipalClass": "ShieldConfigurationExtension"
                ]
            ]),
            sources: ["Shield/**"],
            dependencies: []
        ),
        
        // Test Target
        .target(
            name: "SurahFocusTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(Env.baseBundleId).Tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "SurahFocus")
            ]
        )
    ]
)

// Environment Variables Helper
public extension Env {
    static var companyId: String {
        guard let value = Environment.shared["TUIST_COMPANY_ID"] else {
            return "com.aydev"
        }
        return value.getString(default: "com.aydev")
    }
    
    static var teamId: String {
        guard let value = Environment.shared["TUIST_TEAM_ID"] else {
            return "YOUR_TEAM_ID"
        }
        return value.getString(default: "YOUR_TEAM_ID")
    }
    
    static var baseBundleId: String {
        guard let value = Environment.shared["TUIST_BASE_BUNDLE_ID"] else {
            return "\(companyId).surahfocus"
        }
        return value.getString(default: "\(companyId).surahfocus")
    }
}
```

**Create `Tuist/Package.swift`:**

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

**Create `.env`:**

```bash
TUIST_COMPANY_ID=com.aydev
TUIST_TEAM_ID=YOUR_TEAM_ID_HERE
TUIST_BASE_BUNDLE_ID=com.aydev.surahfocus
```

**⚠️ IMPORTANT:** Replace `YOUR_TEAM_ID_HERE` with your actual Apple Team ID!

**Create `Makefile`:**

```makefile
.PHONY: all env generate build clean install edit test

all: clean install generate

env:
	@echo "✓ Loading environment variables..."

generate:
	@echo "✓ Generating Xcode project..."
	@tuist generate

build:
	@echo "✓ Building app..."
	@xcodebuild -workspace SurahFocus.xcworkspace \
		-scheme SurahFocus \
		-destination 'platform=iOS Simulator,name=iPhone 15' \
		build | xcpretty

clean:
	@echo "✓ Cleaning build artifacts..."
	@rm -rf DerivedData
	@tuist clean

install:
	@echo "✓ Installing dependencies..."
	@tuist install

edit:
	@tuist edit

test:
	@echo "✓ Running tests..."
	@xcodebuild test \
		-workspace SurahFocus.xcworkspace \
		-scheme SurahFocus \
		-destination 'platform=iOS Simulator,name=iPhone 15' \
		| xcpretty
```

**Create `.gitignore`:**

```
# Xcode
DerivedData/
*.xcworkspace
*.xcodeproj
.swiftpm/

# Tuist
Tuist/Dependencies/
.tuist-cache/

# Environment
.env

# macOS
.DS_Store

# Build
*.ipa
*.dSYM.zip
```

### Step 3: Generate Initial Project

```bash
make
```

**Expected Output:**
```
✓ Installing dependencies...
✓ Generating Xcode project...
Project generated successfully!
```

### Verification Checkpoint 1:

```bash
# Should open Xcode with 3 targets visible
open SurahFocus.xcworkspace
```

**In Xcode, verify:**
- [ ] 3 targets: SurahFocus, ScreenTimeMonitor, Shield
- [ ] Bundle IDs correct:
  - SurahFocus: `com.aydev.surahfocus`
  - ScreenTimeMonitor: `com.aydev.surahfocus.ScreenTimeMonitor`
  - Shield: `com.aydev.surahfocus.Shield`

---

## TASK 1.2: FOLDER STRUCTURE (Day 1 Afternoon - 1 hour)

### Step 1: Create Complete Directory Structure

```bash
# From project root
mkdir -p Sources/Core/DataDependency
mkdir -p Sources/Core/Networking
mkdir -p Sources/Core/SceneNavigation
mkdir -p Sources/Data/DataSource
mkdir -p Sources/Data/Repositories
mkdir -p Sources/Domain/Entities
mkdir -p Sources/Domain/Services
mkdir -p Sources/Presentation/Components
mkdir -p Sources/Presentation/Auth
mkdir -p Sources/Presentation/Onboarding
mkdir -p Sources/Presentation/Paywall
mkdir -p Sources/Presentation/MainTabs/QuranTab
mkdir -p Sources/Presentation/MainTabs/BlockingTab
mkdir -p Sources/Presentation/MainTabs/SettingsTab
mkdir -p Sources/Presentation/ListenSession
mkdir -p Sources/Utils/ScreenTime
mkdir -p Resources/Assets.xcassets
mkdir -p Tests/Domain/Entities
mkdir -p Tests/Domain/Services
mkdir -p Tests/Data/Repositories
mkdir -p Tests/Core
mkdir -p Tests/Presentation
```

### Step 2: Create Placeholder Files

```bash
# Main app entry
touch Sources/SurahFocusApp.swift
touch Sources/RootView.swift

# Utils
touch Sources/Utils/Extensions.swift
```

### Verification Checkpoint 2:

```bash
# Should show complete folder structure
tree Sources -L 3
```

---

## TASK 1.3: SWIFTDATA ENTITY MODELS (Day 1 Evening - 3 hours)

### Entity 1: User Model

**Create `Sources/Domain/Entities/user.swift`:**

```swift
import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var appleUserId: String
    var email: String?
    var name: String?
    var isPremium: Bool
    var subscriptionExpiryDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    var createdAt: Date
    var lastActiveDate: Date?
    
    init(
        appleUserId: String,
        email: String? = nil,
        name: String? = nil
    ) {
        self.id = UUID()
        self.appleUserId = appleUserId
        self.email = email
        self.name = name
        self.isPremium = false
        self.currentStreak = 0
        self.longestStreak = 0
        self.createdAt = Date()
        self.lastActiveDate = nil
    }
    
    // Helper methods
    func updateStreak(isActiveToday: Bool) {
        if isActiveToday {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if let lastActive = lastActiveDate {
                let lastActiveDay = calendar.startOfDay(for: lastActive)
                let daysDiff = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
                
                if daysDiff == 0 {
                    // Already active today
                    return
                } else if daysDiff == 1 {
                    // Consecutive day
                    currentStreak += 1
                    if currentStreak > longestStreak {
                        longestStreak = currentStreak
                    }
                } else {
                    // Streak broken
                    currentStreak = 1
                }
            } else {
                // First activity
                currentStreak = 1
                longestStreak = 1
            }
            
            lastActiveDate = Date()
        }
    }
}
```

**Create `Tests/Domain/Entities/UserTests.swift`:**

```swift
import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class UserTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([User.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }
    
    override func tearDown() {
        container = nil
        context = nil
    }
    
    func testUserInitialization() {
        let user = User(
            appleUserId: "test123",
            email: "test@example.com",
            name: "Test User"
        )
        
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.appleUserId, "test123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertFalse(user.isPremium)
        XCTAssertEqual(user.currentStreak, 0)
        XCTAssertEqual(user.longestStreak, 0)
        XCTAssertNil(user.lastActiveDate)
    }
    
    func testStreakIncrementOnFirstActivity() {
        let user = User(appleUserId: "test123")
        
        user.updateStreak(isActiveToday: true)
        
        XCTAssertEqual(user.currentStreak, 1)
        XCTAssertEqual(user.longestStreak, 1)
        XCTAssertNotNil(user.lastActiveDate)
    }
    
    func testStreakIncrementOnConsecutiveDays() {
        let user = User(appleUserId: "test123")
        
        // Day 1
        user.lastActiveDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        user.currentStreak = 1
        user.longestStreak = 1
        
        // Day 2
        user.updateStreak(isActiveToday: true)
        
        XCTAssertEqual(user.currentStreak, 2)
        XCTAssertEqual(user.longestStreak, 2)
    }
    
    func testStreakResetsAfterMissedDay() {
        let user = User(appleUserId: "test123")
        
        // Day 1
        user.lastActiveDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        user.currentStreak = 5
        user.longestStreak = 5
        
        // Day 3 (missed day 2)
        user.updateStreak(isActiveToday: true)
        
        XCTAssertEqual(user.currentStreak, 1)
        XCTAssertEqual(user.longestStreak, 5) // Longest unchanged
    }
    
    func testStreakUnchangedIfAlreadyActiveToday() {
        let user = User(appleUserId: "test123")
        user.currentStreak = 3
        user.lastActiveDate = Date()
        
        user.updateStreak(isActiveToday: true)
        
        XCTAssertEqual(user.currentStreak, 3) // Unchanged
    }
    
    func testPersistenceInSwiftData() throws {
        let user = User(appleUserId: "persist123", email: "persist@test.com")
        context.insert(user)
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.appleUserId, "persist123")
    }
}
```

### Entity 2: Session Model

**Create `Sources/Domain/Entities/session.swift`:**

```swift
import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var type: SessionType
    var surahNumbers: [Int]
    var reciterId: Int?
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int
    var isCompleted: Bool
    
    enum SessionType: String, Codable {
        case reading
        case listening
    }
    
    init(
        userId: UUID,
        type: SessionType,
        surahNumbers: [Int],
        reciterId: Int? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.type = type
        self.surahNumbers = surahNumbers
        self.reciterId = reciterId
        self.startTime = Date()
        self.endTime = nil
        self.durationSeconds = 0
        self.isCompleted = false
    }
    
    // Helper computed property
    // Engagement counts immediately - no minimum time required
    var isValid: Bool {
        return true
    }
}
```

**Create `Tests/Domain/Entities/SessionTests.swift`:**

```swift
import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class SessionTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([Session.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }
    
    override func tearDown() {
        container = nil
        context = nil
    }
    
    func testSessionInitialization() {
        let userId = UUID()
        let session = Session(
            userId: userId,
            type: .listening,
            surahNumbers: [1, 2, 3],
            reciterId: 7
        )
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.userId, userId)
        XCTAssertEqual(session.type, .listening)
        XCTAssertEqual(session.surahNumbers, [1, 2, 3])
        XCTAssertEqual(session.reciterId, 7)
        XCTAssertEqual(session.durationSeconds, 0)
        XCTAssertFalse(session.isCompleted)
    }
    
    func testSessionAlwaysValid() {
        // Engagement counts immediately - no minimum time
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1])
        session.durationSeconds = 1  // Even 1 second counts

        XCTAssertTrue(session.isValid)
    }
    
    func testReadingSessionType() {
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1])
        
        XCTAssertEqual(session.type, .reading)
        XCTAssertNil(session.reciterId)
    }
    
    func testListeningSessionType() {
        let session = Session(userId: UUID(), type: .listening, surahNumbers: [1], reciterId: 7)
        
        XCTAssertEqual(session.type, .listening)
        XCTAssertEqual(session.reciterId, 7)
    }
    
    func testPersistenceInSwiftData() throws {
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1, 2])
        context.insert(session)
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.surahNumbers, [1, 2])
    }
}
```

### Entity 3: BlockedApp Model

**Create `Sources/Domain/Entities/blocked_app.swift`:**

```swift
import Foundation
import SwiftData

@Model
final class BlockedApp {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var appTokenData: Data
    var appName: String
    var bundleIdentifier: String
    var dailyLimitMinutes: Int
    var isActive: Bool
    var createdAt: Date
    
    init(
        userId: UUID,
        appTokenData: Data,
        appName: String,
        bundleIdentifier: String,
        dailyLimitMinutes: Int
    ) {
        self.id = UUID()
        self.userId = userId
        self.appTokenData = appTokenData
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.dailyLimitMinutes = dailyLimitMinutes
        self.isActive = true
        self.createdAt = Date()
    }
}
```

**Create `Tests/Domain/Entities/BlockedAppTests.swift`:**

```swift
import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class BlockedAppTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([BlockedApp.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }
    
    override func tearDown() {
        container = nil
        context = nil
    }
    
    func testBlockedAppInitialization() {
        let userId = UUID()
        let tokenData = "mocktoken".data(using: .utf8)!
        
        let app = BlockedApp(
            userId: userId,
            appTokenData: tokenData,
            appName: "Instagram",
            bundleIdentifier: "com.instagram.app",
            dailyLimitMinutes: 30
        )
        
        XCTAssertNotNil(app.id)
        XCTAssertEqual(app.userId, userId)
        XCTAssertEqual(app.appName, "Instagram")
        XCTAssertEqual(app.bundleIdentifier, "com.instagram.app")
        XCTAssertEqual(app.dailyLimitMinutes, 30)
        XCTAssertTrue(app.isActive)
    }
    
    func testBlockedAppDefaultsToActive() {
        let app = BlockedApp(
            userId: UUID(),
            appTokenData: Data(),
            appName: "TikTok",
            bundleIdentifier: "com.tiktok.app",
            dailyLimitMinutes: 15
        )
        
        XCTAssertTrue(app.isActive)
    }
    
    func testPersistenceInSwiftData() throws {
        let app = BlockedApp(
            userId: UUID(),
            appTokenData: Data(),
            appName: "Twitter",
            bundleIdentifier: "com.twitter.app",
            dailyLimitMinutes: 45
        )
        context.insert(app)
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<BlockedApp>()
        let apps = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps.first?.appName, "Twitter")
    }
}
```

### Entities 4-7: Additional Models (Simplified for now)

**Create `Sources/Domain/Entities/surah.swift`:**

```swift
import Foundation

struct Surah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    
    init(number: Int, name: String, englishName: String, englishNameTranslation: String, numberOfAyahs: Int, revelationType: String) {
        self.id = number
        self.number = number
        self.name = name
        self.englishName = englishName
        self.englishNameTranslation = englishNameTranslation
        self.numberOfAyahs = numberOfAyahs
        self.revelationType = revelationType
    }
}
```

**Create `Sources/Domain/Entities/ayah.swift`:**

```swift
import Foundation

struct Ayah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let text: String
    let numberInSurah: Int
    let translation: String?
    
    init(number: Int, text: String, numberInSurah: Int, translation: String? = nil) {
        self.id = number
        self.number = number
        self.text = text
        self.numberInSurah = numberInSurah
        self.translation = translation
    }
}
```

**Create `Sources/Domain/Entities/reciter.swift`:**

```swift
import Foundation

struct Reciter: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let style: String?
    
    init(id: Int, name: String, style: String? = nil) {
        self.id = id
        self.name = name
        self.style = style
    }
}
```

**Create `Sources/Domain/Entities/app_time_limit.swift`:**

```swift
import Foundation

enum TimeLimit: Int, CaseIterable {
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case ninety = 90
    case oneHundredTwenty = 120
    
    var displayName: String {
        switch self {
        case .fifteen: return "15 min"
        case .thirty: return "30 min"
        case .fortyFive: return "45 min"
        case .sixty: return "1 hour"
        case .ninety: return "1.5 hours"
        case .oneHundredTwenty: return "2 hours"
        }
    }
    
    var minutes: Int {
        return self.rawValue
    }
}
```

### Run Entity Tests

```bash
make test
```

**Expected Output:**
```
Test Suite 'UserTests' passed
Test Suite 'SessionTests' passed
Test Suite 'BlockedAppTests' passed
All tests passed (18 tests)
```

### Verification Checkpoint 3:

```bash
# All entity tests should pass
make test

# Should show 18 passing tests
```

**If tests fail:**
1. Check SwiftData schema configuration
2. Verify all entity files are in correct location
3. Ensure test target has access to main target

---

## TASK 1.4: CORE INFRASTRUCTURE (Day 2 Morning - 3 hours)

### Component 1: DIContainer

**Create `Sources/Core/DataDependency/DIContainer.swift`:**

```swift
import Foundation
import SwiftData

final class DIContainer {
    static let shared = DIContainer()
    
    private let modelContainer: ModelContainer
    
    // Data Sources
    lazy var localDataSource: LocalDataSource = LocalDataSource(container: modelContainer)
    lazy var quranAPIDataSource: QuranAPIDataSource = QuranAPIDataSource()
    
    // Repositories (will implement in later phases)
    lazy var userRepository: UserRepository = UserRepositoryImpl(localDataSource: localDataSource)
    lazy var sessionRepository: SessionRepository = SessionRepositoryImpl(localDataSource: localDataSource)
    lazy var quranRepository: QuranRepository = QuranRepositoryImpl(apiDataSource: quranAPIDataSource)
    lazy var screenTimeRepository: ScreenTimeRepository = ScreenTimeRepositoryImpl(localDataSource: localDataSource)
    
    // Services (will implement in later phases)
    lazy var authService: AuthService = AuthServiceImpl(userRepository: userRepository)
    lazy var subscriptionService: SubscriptionService = SubscriptionServiceImpl(userRepository: userRepository)
    lazy var quranService: QuranService = QuranServiceImpl(quranRepository: quranRepository)
    lazy var sessionService: SessionService = SessionServiceImpl(
        sessionRepository: sessionRepository,
        userRepository: userRepository
    )
    lazy var screenTimeService: ScreenTimeService = ScreenTimeServiceImpl(screenTimeRepository: screenTimeRepository)
    
    var mainContext: ModelContext {
        return modelContainer.mainContext
    }
    
    private init() {
        do {
            let schema = Schema([
                User.self,
                Session.self,
                BlockedApp.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // For testing with in-memory container
    static func makeTestContainer() -> DIContainer {
        let schema = Schema([
            User.self,
            Session.self,
            BlockedApp.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            fatalError("Failed to create test container")
        }
        
        return DIContainer(testContainer: container)
    }
    
    private init(testContainer: ModelContainer) {
        self.modelContainer = testContainer
    }
}

// Protocol stubs (will implement in later phases)
protocol UserRepository {}
protocol SessionRepository {}
protocol QuranRepository {}
protocol ScreenTimeRepository {}
protocol AuthService {}
protocol SubscriptionService {}
protocol QuranService {}
protocol SessionService {}
protocol ScreenTimeService {}

// Implementation stubs
class UserRepositoryImpl: UserRepository {
    let localDataSource: LocalDataSource
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
}

class SessionRepositoryImpl: SessionRepository {
    let localDataSource: LocalDataSource
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
}

class QuranRepositoryImpl: QuranRepository {
    let apiDataSource: QuranAPIDataSource
    init(apiDataSource: QuranAPIDataSource) {
        self.apiDataSource = apiDataSource
    }
}

class ScreenTimeRepositoryImpl: ScreenTimeRepository {
    let localDataSource: LocalDataSource
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
}

class AuthServiceImpl: AuthService {
    let userRepository: UserRepository
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
}

class SubscriptionServiceImpl: SubscriptionService {
    let userRepository: UserRepository
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
}

class QuranServiceImpl: QuranService {
    let quranRepository: QuranRepository
    init(quranRepository: QuranRepository) {
        self.quranRepository = quranRepository
    }
}

class SessionServiceImpl: SessionService {
    let sessionRepository: SessionRepository
    let userRepository: UserRepository
    init(sessionRepository: SessionRepository, userRepository: UserRepository) {
        self.sessionRepository = sessionRepository
        self.userRepository = userRepository
    }
}

class ScreenTimeServiceImpl: ScreenTimeService {
    let screenTimeRepository: ScreenTimeRepository
    init(screenTimeRepository: ScreenTimeRepository) {
        self.screenTimeRepository = screenTimeRepository
    }
}

// Data source stubs
class LocalDataSource {
    let container: ModelContainer
    init(container: ModelContainer) {
        self.container = container
    }
}

class QuranAPIDataSource {
    init() {}
}
```

**Create `Tests/Core/DIContainerTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

final class DIContainerTests: XCTestCase {
    
    func testDIContainerIsSingleton() {
        let instance1 = DIContainer.shared
        let instance2 = DIContainer.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testDIContainerCreatesDataSources() {
        let container = DIContainer.shared
        
        XCTAssertNotNil(container.localDataSource)
        XCTAssertNotNil(container.quranAPIDataSource)
    }
    
    func testDIContainerCreatesRepositories() {
        let container = DIContainer.shared
        
        XCTAssertNotNil(container.userRepository)
        XCTAssertNotNil(container.sessionRepository)
        XCTAssertNotNil(container.quranRepository)
        XCTAssertNotNil(container.screenTimeRepository)
    }
    
    func testDIContainerCreatesServices() {
        let container = DIContainer.shared
        
        XCTAssertNotNil(container.authService)
        XCTAssertNotNil(container.subscriptionService)
        XCTAssertNotNil(container.quranService)
        XCTAssertNotNil(container.sessionService)
        XCTAssertNotNil(container.screenTimeService)
    }
    
    func testTestContainerCreation() {
        let testContainer = DIContainer.makeTestContainer()
        
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContainer.mainContext)
    }
}
```

### Component 2: Router

**Create `Sources/Core/SceneNavigation/Router.swift`:**

```swift
import SwiftUI

@MainActor
final class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    enum Route: Hashable {
        case auth
        case onboarding
        case paywall
        case screenTimePermission
        case appSelection
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
    
    func replaceWith(_ route: Route) {
        navigationPath = NavigationPath()
        navigationPath.append(route)
    }
    
    func reset() {
        navigationPath = NavigationPath()
    }
}
```

**Create `Tests/Core/RouterTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

@MainActor
final class RouterTests: XCTestCase {
    var router: Router!
    
    override func setUp() {
        router = Router()
    }
    
    override func tearDown() {
        router = nil
    }
    
    func testInitialPathIsEmpty() {
        XCTAssertEqual(router.navigationPath.count, 0)
    }
    
    func testNavigateAddsRoute() {
        router.navigate(to: .onboarding)
        
        XCTAssertEqual(router.navigationPath.count, 1)
    }
    
    func testNavigateMultipleRoutes() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)
        router.navigate(to: .mainTabs)
        
        XCTAssertEqual(router.navigationPath.count, 3)
    }
    
    func testNavigateBackRemovesLastRoute() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)
        
        router.navigateBack()
        
        XCTAssertEqual(router.navigationPath.count, 1)
    }
    
    func testNavigateBackOnEmptyPathDoesNothing() {
        router.navigateBack()
        
        XCTAssertEqual(router.navigationPath.count, 0)
    }
    
    func testReplaceWithClearsPathAndAddsNewRoute() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)
        
        router.replaceWith(.mainTabs)
        
        XCTAssertEqual(router.navigationPath.count, 1)
    }
    
    func testResetClearsAllRoutes() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)
        router.navigate(to: .mainTabs)
        
        router.reset()
        
        XCTAssertEqual(router.navigationPath.count, 0)
    }
}
```

### Component 3: HTTPClient

**Create `Sources/Core/Networking/HTTPClient.swift`:**

```swift
import Foundation

final class HTTPClient {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }
    
    func fetch<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode: \(error.localizedDescription)"
        }
    }
}
```

**Create `Tests/Core/HTTPClientTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

final class HTTPClientTests: XCTestCase {
    var client: HTTPClient!
    
    override func setUp() {
        client = HTTPClient()
    }
    
    override func tearDown() {
        client = nil
    }
    
    func testHTTPClientInitialization() {
        XCTAssertNotNil(client)
    }
    
    func testNetworkErrorDescriptions() {
        let invalidResponse = NetworkError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid server response")
        
        let httpError = NetworkError.httpError(404)
        XCTAssertEqual(httpError.errorDescription, "HTTP error: 404")
    }
    
    // Note: Integration tests for actual API calls will be in Phase 4
}
```

### Run Core Infrastructure Tests

```bash
make test
```

**Expected Output:**
```
Test Suite 'DIContainerTests' passed (5 tests)
Test Suite 'RouterTests' passed (7 tests)
Test Suite 'HTTPClientTests' passed (2 tests)
```

### Verification Checkpoint 4:

```bash
make test
# Should show 32+ tests passing (18 entity + 14 core)

make build
# Should compile successfully
```

---

## TASK 1.5: SCREEN TIME EXTENSIONS (Day 2 Afternoon - 3 hours)

### Step 1: Copy Extension Folders from Mindcore

```bash
# From your SurahFocus project root
cp -r /Users/adithyafp_/Projects/mindcore/ScreenTimeMonitor ./
cp -r /Users/adithyafp_/Projects/mindcore/Shield ./
```

### Step 2: Update ScreenTimeMonitor Entitlements

**Edit `ScreenTimeMonitor/ScreenTimeMonitor.entitlements`:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.aydev.surahfocus</string>
	</array>
	<key>com.apple.developer.family-controls</key>
	<true/>
</dict>
</plist>
```

### Step 3: Update Shield Entitlements

**Edit `Shield/Shield.entitlements`:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.aydev.surahfocus</string>
	</array>
</dict>
</plist>
```

### Step 4: Update UserDefaults References

**Search and replace in all Swift files:**

```bash
# From project root
grep -r "group.com.alexis.screentime" ScreenTimeMonitor/ Shield/

# Each file found, replace:
# group.com.alexis.screentime → group.com.aydev.surahfocus
```

**Files likely to update:**
- `ScreenTimeMonitor/DeviceActivityMonitorExtension.swift`
- Any shared constants or configuration files

### Step 5: Create Main App Entitlements

**Create `Sources/SurahFocus.entitlements`:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.aydev.surahfocus</string>
	</array>
	<key>com.apple.developer.family-controls</key>
	<true/>
</dict>
</plist>
```

### Step 6: Regenerate Project

```bash
make clean
make generate
```

### Verification Checkpoint 5:

**Open Xcode:**
```bash
open SurahFocus.xcworkspace
```

**Verify in Xcode:**
1. Check all 3 targets are present
2. Check Signing & Capabilities for each target:
   - [ ] Main app: App Groups enabled (`group.com.aydev.surahfocus`)
   - [ ] Main app: Family Controls enabled
   - [ ] ScreenTimeMonitor: App Groups enabled
   - [ ] ScreenTimeMonitor: Family Controls enabled
   - [ ] Shield: App Groups enabled

3. Check bundle IDs are correct:
   - [ ] Main: `com.aydev.surahfocus`
   - [ ] Monitor: `com.aydev.surahfocus.ScreenTimeMonitor`
   - [ ] Shield: `com.aydev.surahfocus.Shield`

**Search for old identifiers:**
```bash
# Should return ZERO results
grep -r "group.com.alexis.screentime" .
grep -r "com.alexis" .
```

---

## TASK 1.6: MINIMAL APP FILES (Day 2 Evening - 1 hour)

### Create App Entry Point

**Create `Sources/SurahFocusApp.swift`:**

```swift
import SwiftUI
import SwiftData

@main
struct SurahFocusApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(DIContainer.shared.mainContext.container)
        }
    }
}
```

### Create Root View

**Create `Sources/RootView.swift`:**

```swift
import SwiftUI

struct RootView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            Text("Surah Focus")
                .font(.largeTitle)
                .navigationDestination(for: Router.Route.self) { route in
                    destinationView(for: route)
                }
        }
        .environmentObject(router)
    }
    
    @ViewBuilder
    private func destinationView(for route: Router.Route) -> some View {
        switch route {
        case .auth:
            Text("Auth View")
        case .onboarding:
            Text("Onboarding View")
        case .paywall:
            Text("Paywall View")
        case .screenTimePermission:
            Text("Screen Time Permission")
        case .appSelection:
            Text("App Selection")
        case .mainTabs:
            Text("Main Tabs")
        case .surahDetail(let surahId):
            Text("Surah \(surahId)")
        case .listenSession:
            Text("Listen Session")
        }
    }
}

#Preview {
    RootView()
}
```

### Create Extensions File

**Create `Sources/Utils/Extensions.swift`:**

```swift
import SwiftUI

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extensions
extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
```

---

## FINAL BUILD & TEST

### Step 1: Run All Tests

```bash
make test
```

**Expected Output:**
```
Test Suite 'UserTests' passed (6 tests)
Test Suite 'SessionTests' passed (7 tests)
Test Suite 'BlockedAppTests' passed (3 tests)
Test Suite 'DIContainerTests' passed (5 tests)
Test Suite 'RouterTests' passed (7 tests)
Test Suite 'HTTPClientTests' passed (2 tests)

Test Suite 'SurahFocusTests' passed (30 tests)
```

### Step 2: Build All Targets

```bash
make build
```

**Expected Output:**
```
✓ Building app...
Build succeeded

** BUILD SUCCEEDED **
```

### Step 3: Test on Simulator

```bash
# Open Xcode
open SurahFocus.xcworkspace

# In Xcode:
# 1. Select iPhone 15 simulator
# 2. Press Cmd+R to build and run
# 3. App should launch showing "Surah Focus" text
```

### Step 4: Test on Physical Device

**CRITICAL for Screen Time testing:**

1. Connect your iOS 17+ device
2. In Xcode, select your device
3. Build and run (Cmd+R)
4. App should launch successfully
5. Extensions should be loaded (verify in Settings > Developer)

---

## PHASE 1 COMPLETION CHECKLIST

### Project Configuration
- [ ] Tuist configured with 3 targets
- [ ] .env file created with correct Team ID
- [ ] Makefile working (`make`, `make test`, `make build`)
- [ ] .gitignore configured

### Folder Structure
- [ ] All folders created (Core, Data, Domain, Presentation, Utils)
- [ ] Tests folder structure matches main structure
- [ ] Extensions folders present (ScreenTimeMonitor, Shield)

### Entity Models (7 total)
- [ ] User model created with streak logic
- [ ] Session model created with validity check
- [ ] BlockedApp model created
- [ ] Surah, Ayah, Reciter models created
- [ ] TimeLimit enum created
- [ ] All entity tests passing (16+ tests)

### Core Infrastructure
- [ ] DIContainer implemented with singleton pattern
- [ ] Router implemented with NavigationPath
- [ ] HTTPClient implemented with error handling
- [ ] All core tests passing (14+ tests)

### Screen Time Extensions
- [ ] ScreenTimeMonitor folder copied and updated
- [ ] Shield folder copied and updated
- [ ] All entitlements updated with correct app group
- [ ] UserDefaults references updated
- [ ] No references to old bundle IDs remain

### App Files
- [ ] SurahFocusApp.swift created
- [ ] RootView.swift created with basic navigation
- [ ] Extensions.swift created

### Testing & Build
- [ ] 30+ unit tests passing
- [ ] All targets build successfully
- [ ] App runs on simulator
- [ ] App runs on physical device
- [ ] No compile errors or warnings

### Verification Commands
```bash
# All tests pass
make test

# Build succeeds
make build

# No old identifiers
grep -r "group.com.alexis.screentime" .
grep -r "com.alexis" .
# Both should return ZERO results

# Correct identifiers present
grep -r "group.com.aydev.surahfocus" .
# Should find multiple files
```

---

## TROUBLESHOOTING

### Issue: Tests fail to compile
**Solution:**
1. Run `make clean && make generate`
2. Verify test target has dependency on main target in Project.swift
3. Check all test files have `@testable import SurahFocus`

### Issue: Extensions not showing in Xcode
**Solution:**
1. Run `make clean && make generate`
2. Check Project.swift has extension targets defined
3. Verify extension folders are in project root (not in Sources/)

### Issue: Entitlements error
**Solution:**
1. Check .entitlements files are in correct locations
2. Verify app group identifier matches in all 3 entitlements
3. Check Team ID is set correctly in .env
4. Ensure you have App Groups capability enabled in Developer Portal

### Issue: Build fails with "Cannot find 'User' in scope"
**Solution:**
1. Check all entity files are in Domain/Entities/
2. Run `make generate` to refresh Xcode project
3. Verify Sources/** is in target sources in Project.swift

---

## NEXT PHASE PREVIEW

**Phase 2 will cover:**
- RevenueCat setup and configuration
- Sign in with Apple implementation
- AuthService with full authentication flow
- Paywall screen with subscription logic
- Full integration testing of auth + subscription

**Prerequisites for Phase 2:**
- Phase 1 fully complete
- RevenueCat account created
- API key obtained
- Products configured in RevenueCat dashboard

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 1.1 (Project Config): 2 hours
- Task 1.2 (Folder Structure): 1 hour
- Task 1.3 (Entity Models): 3 hours
- Task 1.4 (Core Infrastructure): 3 hours
- Task 1.5 (Screen Time Extensions): 3 hours
- Task 1.6 (App Files): 1 hour
- **Total: 13 hours over 2 days**

**Track your actual time and adjust Phase 2 estimates accordingly.**

---

**🎯 PHASE 1 COMPLETE! Ready for Phase 2: Auth + RevenueCat**

Commit your work:
```bash
git add .
git commit -m "✅ Phase 1 complete: Foundation + 30 tests passing"
git push
```
