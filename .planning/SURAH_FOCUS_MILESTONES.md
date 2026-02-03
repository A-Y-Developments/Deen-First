# SURAH FOCUS - DEVELOPMENT MILESTONES
# 16-Day Sprint: Feb 3-18, 2026

**Project:** Muslim Lock - Surah Focus  
**Bundle ID:** com.aydev.surahfocus  
**Target Release:** February 18, 2026  
**Architecture:** Clean Architecture + MVVM + TDD  
**Testing Strategy:** Unit tests for every layer

---

## CRITICAL PATH OVERVIEW

```
Days 1-2:  Foundation + Testing Setup
Days 3-4:  Auth + RevenueCat + Paywall
Days 5-6:  Onboarding + Screen Time Extensions
Day 7:     Quran API Integration
Days 8-9:  Main Tabs + Quran Reading
Days 10-11: Listening Sessions + Audio
Day 12:    Blocking + Settings Tabs
Day 13:    Streak System + History
Day 14:    Polish + Integration Tests
Day 15:    TestFlight Build
Day 16:    Submission + Buffer
```

---

## PHASE 1: FOUNDATION + PROJECT SETUP
**Timeline:** Days 1-2 (Feb 3-4)  
**Goal:** Complete project structure, data models, core infrastructure

### 1.1 Project Configuration (Day 1 Morning)

**Tasks:**
- [ ] Implement `PROJECT_SETUP.md` structure with Tuist
- [ ] Configure `Project.swift` with 3 targets:
  - Main app: `SurahFocus`
  - Extension 1: `ScreenTimeMonitor`
  - Extension 2: `Shield`
- [ ] Setup `Tuist/Package.swift` with dependencies:
  ```swift
  .remote(url: "https://github.com/RevenueCat/purchases-ios.git", requirement: .upToNextMajor(from: "5.0.0"))
  ```
- [ ] Create `.env` file:
  ```bash
  TUIST_COMPANY_ID=com.aydev
  TUIST_TEAM_ID=YOUR_TEAM_ID
  TUIST_BASE_BUNDLE_ID=com.aydev.surahfocus
  ```
- [ ] Create `Makefile` from `PROJECT_SETUP.md`
- [ ] Run `make` to generate project

**Validation:**
```bash
make generate
make build  # Should compile successfully
```

**Deliverable:** Clean Xcode workspace opens without errors

---

### 1.2 Folder Structure Implementation (Day 1 Afternoon)

**Tasks:**
- [ ] Create complete folder structure:
  ```
  SurahFocus/Sources/
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
  │   │   └── StreakBadge.swift
  │   ├── Auth/
  │   ├── Onboarding/
  │   ├── Paywall/
  │   ├── MainTabs/
  │   │   ├── QuranTab/
  │   │   ├── BlockingTab/
  │   │   └── SettingsTab/
  │   └── ListenSession/
  ├── Utils/
  │   └── Extensions.swift
  ├── RootView.swift
  └── SurahFocusApp.swift
  ```

**Validation:**
- All folders exist
- `make generate` runs successfully
- Xcode shows correct group structure

---

### 1.3 SwiftData Entity Models (Day 1 Evening)

**Reference:** `SURAH_FOCUS_PRD.md` Section 3.3

**Tasks:**
- [ ] Create `Domain/Entities/user.swift`:
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
      
      init(appleUserId: String, email: String? = nil, name: String? = nil) {
          self.id = UUID()
          self.appleUserId = appleUserId
          self.email = email
          self.name = name
          self.isPremium = false
          self.currentStreak = 0
          self.longestStreak = 0
          self.createdAt = Date()
      }
  }
  ```

- [ ] Create `Domain/Entities/session.swift`:
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
      
      init(userId: UUID, type: SessionType, surahNumbers: [Int]) {
          self.id = UUID()
          self.userId = userId
          self.type = type
          self.surahNumbers = surahNumbers
          self.startTime = Date()
          self.durationSeconds = 0
          self.isCompleted = false
      }
  }
  ```

- [ ] Create `Domain/Entities/blocked_app.swift`:
  ```swift
  import Foundation
  import SwiftData
  
  @Model
  final class BlockedApp {
      @Attribute(.unique) var id: UUID
      var userId: UUID
      var appTokenData: Data  // Encoded ApplicationToken
      var appName: String
      var bundleIdentifier: String
      var dailyLimitMinutes: Int
      var isActive: Bool
      var createdAt: Date
      
      init(userId: UUID, appTokenData: Data, appName: String, bundleIdentifier: String, dailyLimitMinutes: Int) {
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

- [ ] Create remaining entities: `surah.swift`, `ayah.swift`, `reciter.swift`, `app_time_limit.swift`

**Unit Tests:**
- [ ] Create `Tests/Domain/Entities/UserTests.swift`:
  ```swift
  import XCTest
  @testable import SurahFocus
  
  final class UserTests: XCTestCase {
      func testUserInitialization() {
          let user = User(appleUserId: "test123", email: "test@test.com")
          
          XCTAssertNotNil(user.id)
          XCTAssertEqual(user.appleUserId, "test123")
          XCTAssertEqual(user.isPremium, false)
          XCTAssertEqual(user.currentStreak, 0)
      }
      
      func testStreakIncrement() {
          let user = User(appleUserId: "test123")
          user.currentStreak = 5
          user.currentStreak += 1
          
          XCTAssertEqual(user.currentStreak, 6)
      }
  }
  ```

- [ ] Create tests for `Session`, `BlockedApp` models
- [ ] Run tests: `make test`

**Validation:**
- All entity models compile
- Unit tests pass (100% coverage on models)
- SwiftData schema generates correctly

---

### 1.4 Core Infrastructure (Day 2 Morning)

**Tasks:**
- [ ] Implement `Core/DataDependency/DIContainer.swift`:
  ```swift
  import Foundation
  import SwiftData
  
  final class DIContainer {
      static let shared = DIContainer()
      
      private let modelContainer: ModelContainer
      
      // Data Sources
      lazy var localDataSource: LocalDataSource = LocalDataSource(container: modelContainer)
      lazy var quranAPIDataSource: QuranAPIDataSource = QuranAPIDataSource()
      
      // Repositories
      lazy var userRepository: UserRepository = UserRepositoryImpl(localDataSource: localDataSource)
      lazy var sessionRepository: SessionRepository = SessionRepositoryImpl(localDataSource: localDataSource)
      lazy var quranRepository: QuranRepository = QuranRepositoryImpl(apiDataSource: quranAPIDataSource)
      lazy var screenTimeRepository: ScreenTimeRepository = ScreenTimeRepositoryImpl(localDataSource: localDataSource)
      
      // Services
      lazy var authService: AuthService = AuthServiceImpl(userRepository: userRepository)
      lazy var subscriptionService: SubscriptionService = SubscriptionServiceImpl(userRepository: userRepository)
      lazy var quranService: QuranService = QuranServiceImpl(quranRepository: quranRepository)
      lazy var sessionService: SessionService = SessionServiceImpl(sessionRepository: sessionRepository, userRepository: userRepository)
      lazy var screenTimeService: ScreenTimeService = ScreenTimeServiceImpl(screenTimeRepository: screenTimeRepository)
      
      private init() {
          do {
              let schema = Schema([
                  User.self,
                  Session.self,
                  BlockedApp.self,
              ])
              let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
              self.modelContainer = try ModelContainer(for: schema, configurations: [config])
          } catch {
              fatalError("Failed to create ModelContainer: \(error)")
          }
      }
  }
  ```

- [ ] Implement `Core/SceneNavigation/Router.swift`:
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
  }
  ```

- [ ] Implement `Core/Networking/HTTPClient.swift`:
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
          
          return try JSONDecoder().decode(T.self, from: data)
      }
  }
  
  enum NetworkError: Error {
      case invalidResponse
      case httpError(Int)
      case decodingError
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Core/RouterTests.swift`:
  ```swift
  @MainActor
  final class RouterTests: XCTestCase {
      var router: Router!
      
      override func setUp() {
          router = Router()
      }
      
      func testNavigateAddsRoute() {
          router.navigate(to: .onboarding)
          XCTAssertEqual(router.navigationPath.count, 1)
      }
      
      func testNavigateBackRemovesRoute() {
          router.navigate(to: .onboarding)
          router.navigateBack()
          XCTAssertEqual(router.navigationPath.count, 0)
      }
      
      func testReplaceWithClearsPath() {
          router.navigate(to: .onboarding)
          router.navigate(to: .paywall)
          router.replaceWith(.mainTabs)
          XCTAssertEqual(router.navigationPath.count, 1)
      }
  }
  ```

**Validation:**
- DIContainer initializes without crashes
- Router tests pass 100%
- HTTPClient compiles (integration tests in Phase 4)

---

### 1.5 Screen Time Extensions Setup (Day 2 Afternoon)

**Reference:** `SCREEN_TIME_API_GUIDE.md`

**Tasks:**
- [ ] Copy `ScreenTimeMonitor/` folder from Mindcore basecode
- [ ] Copy `Shield/` folder from Mindcore basecode
- [ ] Update `Project.swift` to include extensions (see `SURAH_FOCUS_SYSTEM_DESIGN.md` Section 11.5.2)
- [ ] Create entitlements:
  - `SurahFocus/SurahFocus.entitlements`:
    ```xml
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.aydev.surahfocus</string>
    </array>
    ```
  - `ScreenTimeMonitor/ScreenTimeMonitor.entitlements`:
    ```xml
    <key>com.apple.developer.family-controls</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.aydev.surahfocus</string>
    </array>
    ```

- [ ] Update `Info.plist` keys:
  ```xml
  <key>NSFamilyControlsUsageDescription</key>
  <string>Surah Focus needs permission to block distracting apps during your Quran focus sessions.</string>
  <key>UIBackgroundModes</key>
  <array>
      <string>audio</string>
  </array>
  ```

- [ ] Implement `ScreenTimeMonitor/DeviceActivityMonitorExtension.swift` (adapt from Mindcore)
- [ ] Implement `Shield/ShieldConfigurationExtension.swift` (adapt from Mindcore)

**Validation:**
- `make generate` includes all 3 targets
- Extensions have correct bundle IDs:
  - `com.aydev.surahfocus.ScreenTimeMonitor`
  - `com.aydev.surahfocus.Shield`
- Build succeeds for all targets

---

### PHASE 1 DELIVERABLES

**Code:**
- ✅ Complete folder structure
- ✅ 7 SwiftData entity models
- ✅ DIContainer with all dependencies
- ✅ Router with navigation
- ✅ HTTPClient for API calls
- ✅ Screen Time extensions configured

**Tests:**
- ✅ Entity model tests (100% coverage)
- ✅ Router tests (100% coverage)
- ✅ 15+ unit tests passing

**Validation:**
```bash
make test  # All tests pass
make build # All targets compile
```

---

## PHASE 2: AUTHENTICATION + REVENUECAT
**Timeline:** Days 3-4 (Feb 5-6)  
**Goal:** Sign in with Apple working, paywall functional, subscriptions configured

### 2.1 RevenueCat Setup (Day 3 Morning)

**Tasks:**
- [ ] Create RevenueCat account: https://www.revenuecat.com
- [ ] Configure App in RevenueCat dashboard:
  - Bundle ID: `com.aydev.surahfocus`
  - Platform: iOS
- [ ] Create Products:
  - Product ID: `com.aydev.surahfocus.monthly`
    - Price: $4.99/month
    - Trial: 3 days
  - Product ID: `com.aydev.surahfocus.yearly`
    - Price: $29.99/year
    - Trial: 7 days
- [ ] Create Entitlement:
  - ID: `premium`
  - Attach both products
- [ ] Get API Key from RevenueCat
- [ ] Store in `.env`:
  ```bash
  REVENUECAT_API_KEY=your_key_here
  ```

**Validation:**
- RevenueCat dashboard shows products configured
- API key available

---

### 2.2 AuthService Implementation (Day 3 Afternoon)

**Reference:** `PROJECT_RULES.md` Service Pattern

**Tasks:**
- [ ] Create `Domain/Services/AuthService.swift`:
  ```swift
  import AuthenticationServices
  
  protocol AuthService {
      func signInWithApple() async throws -> User
      func getCurrentUser() async throws -> User?
      func signOut() async throws
  }
  
  final class AuthServiceImpl: AuthService {
      private let userRepository: UserRepository
      
      init(userRepository: UserRepository) {
          self.userRepository = userRepository
      }
      
      func signInWithApple() async throws -> User {
          // Request authorization
          let provider = ASAuthorizationAppleIDProvider()
          let request = provider.createRequest()
          request.requestedScopes = [.email, .fullName]
          
          // Will implement in ViewModel with ASAuthorizationControllerDelegate
          throw AuthError.notImplemented
      }
      
      func getCurrentUser() async throws -> User? {
          return try await userRepository.getCurrentUser()
      }
      
      func signOut() async throws {
          try await userRepository.deleteCurrentUser()
      }
  }
  
  enum AuthError: Error {
      case notImplemented
      case cancelled
      case failed
  }
  ```

- [ ] Create `Data/Repositories/UserRepository.swift`:
  ```swift
  protocol UserRepository {
      func createUser(_ user: User) async throws
      func getCurrentUser() async throws -> User?
      func updateUser(_ user: User) async throws
      func deleteCurrentUser() async throws
  }
  
  final class UserRepositoryImpl: UserRepository {
      private let localDataSource: LocalDataSource
      
      init(localDataSource: LocalDataSource) {
          self.localDataSource = localDataSource
      }
      
      func createUser(_ user: User) async throws {
          try await localDataSource.insertUser(user)
      }
      
      func getCurrentUser() async throws -> User? {
          return try await localDataSource.getFirstUser()
      }
      
      func updateUser(_ user: User) async throws {
          // SwiftData auto-saves changes to @Model objects
      }
      
      func deleteCurrentUser() async throws {
          if let user = try await getCurrentUser() {
              try await localDataSource.deleteUser(user)
          }
      }
  }
  ```

- [ ] Create `Data/DataSource/LocalDataSource.swift`:
  ```swift
  import SwiftData
  
  final class LocalDataSource {
      private let container: ModelContainer
      
      init(container: ModelContainer) {
          self.container = container
      }
      
      @MainActor
      func insertUser(_ user: User) throws {
          let context = container.mainContext
          context.insert(user)
          try context.save()
      }
      
      @MainActor
      func getFirstUser() throws -> User? {
          let context = container.mainContext
          let descriptor = FetchDescriptor<User>()
          let users = try context.fetch(descriptor)
          return users.first
      }
      
      @MainActor
      func deleteUser(_ user: User) throws {
          let context = container.mainContext
          context.delete(user)
          try context.save()
      }
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Domain/Services/AuthServiceTests.swift`:
  ```swift
  final class AuthServiceTests: XCTestCase {
      var service: AuthService!
      var mockUserRepository: MockUserRepository!
      
      override func setUp() {
          mockUserRepository = MockUserRepository()
          service = AuthServiceImpl(userRepository: mockUserRepository)
      }
      
      func testGetCurrentUserReturnsUser() async throws {
          let mockUser = User(appleUserId: "test123")
          mockUserRepository.userToReturn = mockUser
          
          let user = try await service.getCurrentUser()
          
          XCTAssertNotNil(user)
          XCTAssertEqual(user?.appleUserId, "test123")
      }
      
      func testSignOutDeletesUser() async throws {
          let mockUser = User(appleUserId: "test123")
          mockUserRepository.userToReturn = mockUser
          
          try await service.signOut()
          
          XCTAssertTrue(mockUserRepository.didDeleteUser)
      }
  }
  
  // Mock
  class MockUserRepository: UserRepository {
      var userToReturn: User?
      var didDeleteUser = false
      
      func getCurrentUser() async throws -> User? { userToReturn }
      func createUser(_ user: User) async throws { }
      func updateUser(_ user: User) async throws { }
      func deleteCurrentUser() async throws { didDeleteUser = true }
  }
  ```

- [ ] Create `Tests/Data/Repositories/UserRepositoryTests.swift`

**Validation:**
- All unit tests pass
- Auth service compiles
- Repository pattern correct

---

### 2.3 AuthView + ViewModel (Day 3 Evening)

**Reference:** `SURAH_FOCUS_UI_UX_DESIGN.md` Section 1

**Tasks:**
- [ ] Create `Presentation/Auth/AuthView.swift`:
  ```swift
  import SwiftUI
  import AuthenticationServices
  
  struct AuthView: View {
      @EnvironmentObject var router: Router
      @EnvironmentObject var vm: AuthViewModel
      
      var body: some View {
          VStack(spacing: 40) {
              Spacer()
              
              // App Icon
              Image(systemName: "moon.stars.fill")
                  .font(.system(size: 80))
                  .foregroundColor(.indigo)
              
              VStack(spacing: 8) {
                  Text("Surah Focus")
                      .font(.system(size: 32, weight: .bold))
                  Text("Block Apps, Build Quran Habits")
                      .font(.system(size: 16))
                      .foregroundColor(.secondary)
              }
              
              Spacer()
              
              // Sign in with Apple
              SignInWithAppleButton(.signIn) { request in
                  request.requestedScopes = [.email, .fullName]
              } onCompletion: { result in
                  Task {
                      await vm.handleSignIn(result: result)
                  }
              }
              .signInWithAppleButtonStyle(.black)
              .frame(height: 50)
              .padding(.horizontal, 32)
          }
          .padding()
      }
  }
  ```

- [ ] Create `Presentation/Auth/AuthViewModel.swift`:
  ```swift
  import AuthenticationServices
  
  @MainActor
  final class AuthViewModel: ObservableObject {
      @Published var isLoading = false
      @Published var errorMessage: String?
      
      private let authService: AuthService
      private let router: Router
      
      init() {
          self.authService = DIContainer.shared.authService
          // Router injected via EnvironmentObject
      }
      
      func handleSignIn(result: Result<ASAuthorization, Error>) async {
          isLoading = true
          defer { isLoading = false }
          
          switch result {
          case .success(let authorization):
              guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                  errorMessage = "Invalid credential"
                  return
              }
              
              // Create user
              let user = User(
                  appleUserId: credential.user,
                  email: credential.email,
                  name: credential.fullName?.givenName
              )
              
              do {
                  try await authService.getCurrentUser()
                  // User exists, navigate to main
                  router.replaceWith(.mainTabs)
              } catch {
                  // New user, go to onboarding
                  router.navigate(to: .onboarding)
              }
              
          case .failure(let error):
              errorMessage = error.localizedDescription
          }
      }
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Presentation/Auth/AuthViewModelTests.swift`:
  ```swift
  @MainActor
  final class AuthViewModelTests: XCTestCase {
      var vm: AuthViewModel!
      var mockAuthService: MockAuthService!
      
      override func setUp() async {
          mockAuthService = MockAuthService()
          // Inject mock via DIContainer or constructor
          vm = AuthViewModel()
      }
      
      func testHandleSignInSuccess() async {
          // Test implementation
      }
      
      func testHandleSignInFailure() async {
          // Test implementation
      }
  }
  ```

**Validation:**
- AuthView renders correctly
- Sign in with Apple button appears
- Tests pass

---

### 2.4 SubscriptionService + Paywall (Day 4)

**Reference:** `SURAH_FOCUS_PRD.md` Section 1.4

**Tasks:**
- [ ] Initialize RevenueCat in `SurahFocusApp.swift`:
  ```swift
  import RevenueCat
  
  @main
  struct SurahFocusApp: App {
      init() {
          Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")
          Purchases.logLevel = .debug
      }
      
      var body: some Scene {
          WindowGroup {
              RootView()
                  .modelContainer(DIContainer.shared.modelContainer)
          }
      }
  }
  ```

- [ ] Create `Domain/Services/SubscriptionService.swift`:
  ```swift
  import RevenueCat
  
  protocol SubscriptionService {
      func checkSubscriptionStatus() async throws -> Bool
      func purchaseMonthly() async throws
      func purchaseYearly() async throws
      func restorePurchases() async throws
  }
  
  final class SubscriptionServiceImpl: SubscriptionService {
      private let userRepository: UserRepository
      
      init(userRepository: UserRepository) {
          self.userRepository = userRepository
      }
      
      func checkSubscriptionStatus() async throws -> Bool {
          let customerInfo = try await Purchases.shared.customerInfo()
          let isPremium = customerInfo.entitlements["premium"]?.isActive == true
          
          // Update local user
          if var user = try await userRepository.getCurrentUser() {
              user.isPremium = isPremium
              user.subscriptionExpiryDate = customerInfo.entitlements["premium"]?.expirationDate
              try await userRepository.updateUser(user)
          }
          
          return isPremium
      }
      
      func purchaseMonthly() async throws {
          let offerings = try await Purchases.shared.offerings()
          guard let package = offerings.current?.monthly else {
              throw SubscriptionError.packageNotFound
          }
          _ = try await Purchases.shared.purchase(package: package)
      }
      
      func purchaseYearly() async throws {
          let offerings = try await Purchases.shared.offerings()
          guard let package = offerings.current?.annual else {
              throw SubscriptionError.packageNotFound
          }
          _ = try await Purchases.shared.purchase(package: package)
      }
      
      func restorePurchases() async throws {
          _ = try await Purchases.shared.restorePurchases()
      }
  }
  
  enum SubscriptionError: Error {
      case packageNotFound
  }
  ```

- [ ] Create `Presentation/Paywall/PaywallView.swift` (see UI/UX doc Section 3)
- [ ] Create `Presentation/Paywall/PaywallViewModel.swift`

**Unit Tests:**
- [ ] Create `Tests/Domain/Services/SubscriptionServiceTests.swift`
- [ ] Create `Tests/Presentation/Paywall/PaywallViewModelTests.swift`

**Validation:**
- RevenueCat initializes without errors
- Paywall displays correctly
- Purchase flow works in sandbox
- Tests pass

---

### PHASE 2 DELIVERABLES

**Code:**
- ✅ Sign in with Apple working
- ✅ RevenueCat integrated
- ✅ Paywall screen functional
- ✅ AuthService + UserRepository complete
- ✅ SubscriptionService complete

**Tests:**
- ✅ AuthService tests (100%)
- ✅ UserRepository tests (100%)
- ✅ SubscriptionService tests (100%)
- ✅ 25+ unit tests passing

**Validation:**
- Can sign in with Apple
- Can purchase subscription (sandbox)
- Can restore purchases
- All tests pass

---

## PHASE 3: ONBOARDING + SCREEN TIME
**Timeline:** Days 5-6 (Feb 7-8)  
**Goal:** Complete 4-screen survey, Screen Time permission, app selection

### 3.1 Onboarding Survey (Day 5)

**Reference:** `SURAH_FOCUS_UI_UX_DESIGN.md` Section 2

**Tasks:**
- [ ] Create `Presentation/Onboarding/OnboardingView.swift` (4 screens)
- [ ] Create `Presentation/Onboarding/OnboardingViewModel.swift`
- [ ] Implement survey logic:
  - Screen 1: Motivation (multi-select)
  - Screen 2: Distraction patterns
  - Screen 3: Goals
  - Screen 4: Time comparison (no input, just info)
- [ ] Store survey results in UserDefaults
- [ ] Navigate to Paywall after survey

**Unit Tests:**
- [ ] Create `Tests/Presentation/Onboarding/OnboardingViewModelTests.swift`
- [ ] Test survey flow
- [ ] Test data storage

**Validation:**
- Survey screens display correctly
- Navigation works
- Data persists

---

### 3.2 Screen Time Permission Flow (Day 5-6)

**Reference:** `SCREEN_TIME_API_GUIDE.md`

**Tasks:**
- [ ] Create `Domain/Services/ScreenTimeService.swift`:
  ```swift
  import FamilyControls
  import ManagedSettings
  
  protocol ScreenTimeService {
      func requestAuthorization() async throws
      func isAuthorized() async -> Bool
      func applyShield(apps: Set<ApplicationToken>) async throws
      func removeAllShields() async throws
  }
  ```

- [ ] Create `Data/Repositories/ScreenTimeRepository.swift` (adapt from Mindcore)
- [ ] Create permission request screen
- [ ] Create app selection screen using `FamilyActivityPicker`
- [ ] Implement time limit configuration

**Unit Tests:**
- [ ] Create `Tests/Domain/Services/ScreenTimeServiceTests.swift`
- [ ] Mock FamilyControls API

**Validation:**
- Permission dialog appears
- Can select apps
- Can set time limits
- Shields apply correctly (test on device)

---

### PHASE 3 DELIVERABLES

**Code:**
- ✅ 4-screen onboarding survey
- ✅ Screen Time permission flow
- ✅ App selection with FamilyActivityPicker
- ✅ Time limit configuration
- ✅ ScreenTimeService complete

**Tests:**
- ✅ OnboardingViewModel tests
- ✅ ScreenTimeService tests
- ✅ 15+ unit tests passing

**Validation:**
- Can complete onboarding
- Can grant Screen Time permission
- Can select apps to block
- Shields work on physical device

---

## PHASE 4: QURAN API INTEGRATION
**Timeline:** Day 7 (Feb 9)  
**Goal:** Quran API client working, caching implemented, data flowing

### 4.1 Quran API Client (Day 7 Morning)

**Reference:** `SURAH_FOCUS_PRD.md` Section 4.1

**Tasks:**
- [ ] Create `Data/DataSource/QuranAPIDataSource.swift`:
  ```swift
  final class QuranAPIDataSource {
      private let baseURL = "https://quranapi.pages.dev/api"
      private let httpClient: HTTPClient
      private let cache: URLCache
      
      init() {
          self.httpClient = HTTPClient()
          self.cache = URLCache.shared
      }
      
      func fetchAllSurahs() async throws -> [SurahDTO] {
          let url = URL(string: "\(baseURL)/surah")!
          return try await httpClient.fetch(url: url)
      }
      
      func fetchSurah(number: Int) async throws -> SurahDetailDTO {
          let url = URL(string: "\(baseURL)/surah/\(number)?lang=en")!
          return try await httpClient.fetch(url: url)
      }
      
      func fetchAudioURL(surahNumber: Int, reciterId: Int) async throws -> AudioResponseDTO {
          let url = URL(string: "\(baseURL)/surah/\(surahNumber)/audio/\(reciterId)")!
          return try await httpClient.fetch(url: url)
      }
      
      func fetchReciters() async throws -> [ReciterDTO] {
          let url = URL(string: "\(baseURL)/reciters")!
          return try await httpClient.fetch(url: url)
      }
  }
  
  // DTOs
  struct SurahDTO: Codable {
      let number: Int
      let name: String
      let englishName: String
      let englishNameTranslation: String
      let numberOfAyahs: Int
      let revelationType: String
  }
  
  struct SurahDetailDTO: Codable {
      let number: Int
      let name: String
      let englishName: String
      let numberOfAyahs: Int
      let ayahs: [AyahDTO]
  }
  
  struct AyahDTO: Codable {
      let number: Int
      let text: String
      let numberInSurah: Int
      let translation: String?
  }
  
  struct AudioResponseDTO: Codable {
      let audioUrl: String
  }
  
  struct ReciterDTO: Codable {
      let id: Int
      let name: String
      let style: String?
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Data/DataSource/QuranAPIDataSourceTests.swift`:
  ```swift
  final class QuranAPIDataSourceTests: XCTestCase {
      var dataSource: QuranAPIDataSource!
      
      override func setUp() {
          dataSource = QuranAPIDataSource()
      }
      
      func testFetchAllSurahs() async throws {
          let surahs = try await dataSource.fetchAllSurahs()
          XCTAssertEqual(surahs.count, 114)
          XCTAssertEqual(surahs[0].number, 1)
          XCTAssertEqual(surahs[0].englishName, "Al-Fatihah")
      }
      
      func testFetchSurahDetail() async throws {
          let surah = try await dataSource.fetchSurah(number: 1)
          XCTAssertEqual(surah.number, 1)
          XCTAssertEqual(surah.numberOfAyahs, 7)
          XCTAssertFalse(surah.ayahs.isEmpty)
      }
  }
  ```

**Validation:**
- API calls work
- JSON parsing works
- Tests pass

---

### 4.2 Quran Repository + Service (Day 7 Afternoon)

**Tasks:**
- [ ] Create `Data/Repositories/QuranRepository.swift`:
  ```swift
  protocol QuranRepository {
      func getAllSurahs() async throws -> [Surah]
      func getSurah(number: Int) async throws -> SurahDetail
      func getAudioURL(surahNumber: Int, reciterId: Int) async throws -> String
      func getReciters() async throws -> [Reciter]
  }
  
  final class QuranRepositoryImpl: QuranRepository {
      private let apiDataSource: QuranAPIDataSource
      private var surahCache: [Surah] = []
      
      init(apiDataSource: QuranAPIDataSource) {
          self.apiDataSource = apiDataSource
      }
      
      func getAllSurahs() async throws -> [Surah] {
          if !surahCache.isEmpty {
              return surahCache
          }
          
          let dtos = try await apiDataSource.fetchAllSurahs()
          let surahs = dtos.map { Surah(from: $0) }
          surahCache = surahs
          return surahs
      }
      
      // ... implement other methods
  }
  ```

- [ ] Create `Domain/Services/QuranService.swift`:
  ```swift
  protocol QuranService {
      func loadSurahs() async throws -> [Surah]
      func loadSurahDetail(number: Int) async throws -> SurahDetail
      func getAudioURL(surah: Int, reciter: Int) async throws -> String
      func loadReciters() async throws -> [Reciter]
  }
  
  final class QuranServiceImpl: QuranService {
      private let quranRepository: QuranRepository
      
      init(quranRepository: QuranRepository) {
          self.quranRepository = quranRepository
      }
      
      func loadSurahs() async throws -> [Surah] {
          return try await quranRepository.getAllSurahs()
      }
      
      // ... implement other methods
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Data/Repositories/QuranRepositoryTests.swift`
- [ ] Create `Tests/Domain/Services/QuranServiceTests.swift`

**Validation:**
- Repository caches correctly
- Service delegates properly
- Tests pass

---

### PHASE 4 DELIVERABLES

**Code:**
- ✅ QuranAPIDataSource complete
- ✅ QuranRepository with caching
- ✅ QuranService complete
- ✅ DTOs for all API responses

**Tests:**
- ✅ API integration tests
- ✅ Repository tests with mocks
- ✅ Service tests
- ✅ 20+ unit tests passing

**Validation:**
- Can fetch all 114 surahs
- Can fetch surah details with ayahs
- Can get audio URLs
- Caching works correctly

---

## PHASE 5: MAIN TABS + QURAN READING
**Timeline:** Days 8-9 (Feb 10-11)  
**Goal:** Tab navigation, surah list, surah detail view, search

### 5.1 Main Tab Navigation (Day 8 Morning)

**Tasks:**
- [ ] Create `Presentation/MainTabs/MainTabView.swift`:
  ```swift
  struct MainTabView: View {
      @State private var selectedTab = 0
      
      var body: some View {
          TabView(selection: $selectedTab) {
              QuranTabView()
                  .tabItem {
                      Label("Quran", systemImage: "book.fill")
                  }
                  .tag(0)
              
              BlockingTabView()
                  .tabItem {
                      Label("Blocking", systemImage: "shield.fill")
                  }
                  .tag(1)
              
              SettingsTabView()
                  .tabItem {
                      Label("Settings", systemImage: "gearshape.fill")
                  }
                  .tag(2)
          }
      }
  }
  ```

**Validation:**
- 3 tabs display correctly
- Can switch between tabs
- Selected state works

---

### 5.2 Quran Tab Implementation (Day 8-9)

**Reference:** `SURAH_FOCUS_UI_UX_DESIGN.md` Section 7

**Tasks:**
- [ ] Create `Presentation/MainTabs/QuranTab/QuranTabView.swift`
- [ ] Create `Presentation/MainTabs/QuranTab/QuranTabViewModel.swift`:
  ```swift
  @MainActor
  final class QuranTabViewModel: ObservableObject {
      @Published var surahs: [Surah] = []
      @Published var searchText = ""
      @Published var isLoading = false
      @Published var currentStreak = 0
      
      private let quranService: QuranService
      private let userRepository: UserRepository
      
      init() {
          self.quranService = DIContainer.shared.quranService
          self.userRepository = DIContainer.shared.userRepository
      }
      
      var filteredSurahs: [Surah] {
          if searchText.isEmpty {
              return surahs
          }
          return surahs.filter {
              $0.englishName.lowercased().contains(searchText.lowercased()) ||
              $0.name.contains(searchText)
          }
      }
      
      func load() {
          Task {
              isLoading = true
              defer { isLoading = false }
              
              do {
                  surahs = try await quranService.loadSurahs()
                  if let user = try await userRepository.getCurrentUser() {
                      currentStreak = user.currentStreak
                  }
              } catch {
                  print("Error loading surahs: \(error)")
              }
          }
      }
  }
  ```

- [ ] Create `Presentation/MainTabs/QuranTab/SurahDetailView.swift`
- [ ] Create `Presentation/MainTabs/QuranTab/SurahDetailViewModel.swift`

- [ ] Create reusable components:
  - `Presentation/Components/SurahCard.swift`
  - `Presentation/Components/StreakBadge.swift`

**Unit Tests:**
- [ ] Create `Tests/Presentation/MainTabs/QuranTab/QuranTabViewModelTests.swift`:
  ```swift
  @MainActor
  final class QuranTabViewModelTests: XCTestCase {
      var vm: QuranTabViewModel!
      var mockQuranService: MockQuranService!
      
      override func setUp() {
          mockQuranService = MockQuranService()
          vm = QuranTabViewModel()
      }
      
      func testLoadSurahsSuccess() async {
          mockQuranService.surahsToReturn = [
              Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", numberOfAyahs: 7)
          ]
          
          await vm.load()
          
          XCTAssertEqual(vm.surahs.count, 1)
          XCTAssertFalse(vm.isLoading)
      }
      
      func testFilteredSurahsWithSearch() {
          vm.surahs = [
              Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", numberOfAyahs: 7),
              Surah(number: 2, name: "Al-Baqarah", englishName: "The Cow", numberOfAyahs: 286)
          ]
          vm.searchText = "cow"
          
          XCTAssertEqual(vm.filteredSurahs.count, 1)
          XCTAssertEqual(vm.filteredSurahs[0].englishName, "The Cow")
      }
  }
  ```

**Validation:**
- Quran tab displays surah list
- Search works correctly
- Streak badge shows
- Can navigate to surah detail
- Tests pass

---

### PHASE 5 DELIVERABLES

**Code:**
- ✅ MainTabView with 3 tabs
- ✅ QuranTabView with search
- ✅ SurahDetailView with ayahs
- ✅ Reusable components (SurahCard, StreakBadge)

**Tests:**
- ✅ QuranTabViewModel tests
- ✅ SurahDetailViewModel tests
- ✅ Search filtering tests
- ✅ 15+ unit tests passing

**Validation:**
- Can browse all 114 surahs
- Search filters correctly
- Can read surah with translation
- Streak displays correctly

---

## PHASE 6: LISTENING SESSIONS + AUDIO
**Timeline:** Days 10-11 (Feb 12-13)  
**Goal:** Audio playback working, background audio, session flow complete

### 6.1 Audio Player Implementation (Day 10)

**Reference:** `SURAH_FOCUS_SYSTEM_DESIGN.md` Section 2.3

**Tasks:**
- [ ] Create `Domain/Services/AudioPlayerService.swift`:
  ```swift
  import AVFoundation
  
  protocol AudioPlayerService {
      var isPlaying: Bool { get }
      var currentTime: TimeInterval { get }
      var duration: TimeInterval { get }
      
      func loadAudio(url: URL) async throws
      func play()
      func pause()
      func stop()
      func seek(to time: TimeInterval)
  }
  
  final class AudioPlayerServiceImpl: NSObject, AudioPlayerService, AVAudioPlayerDelegate {
      private var player: AVPlayer?
      private var playerItem: AVPlayerItem?
      
      var isPlaying: Bool {
          player?.timeControlStatus == .playing
      }
      
      var currentTime: TimeInterval {
          player?.currentTime().seconds ?? 0
      }
      
      var duration: TimeInterval {
          player?.currentItem?.duration.seconds ?? 0
      }
      
      override init() {
          super.init()
          setupAudioSession()
      }
      
      private func setupAudioSession() {
          do {
              let session = AVAudioSession.sharedInstance()
              try session.setCategory(.playback, mode: .default)
              try session.setActive(true)
          } catch {
              print("Audio session setup failed: \(error)")
          }
      }
      
      func loadAudio(url: URL) async throws {
          playerItem = AVPlayerItem(url: url)
          player = AVPlayer(playerItem: playerItem)
          
          // Setup remote controls
          setupRemoteTransportControls()
      }
      
      func play() {
          player?.play()
      }
      
      func pause() {
          player?.pause()
      }
      
      func stop() {
          player?.pause()
          player?.seek(to: .zero)
      }
      
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
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Domain/Services/AudioPlayerServiceTests.swift`
- [ ] Mock AVPlayer for testing

**Validation:**
- Audio loads correctly
- Play/pause works
- Background audio works
- Lock screen controls work

---

### 6.2 Session Service Implementation (Day 10-11)

**Tasks:**
- [ ] Create `Domain/Services/SessionService.swift`:
  ```swift
  protocol SessionService {
      func startSession(type: Session.SessionType, surahNumbers: [Int], reciterId: Int?) async throws -> Session
      func endSession(_ session: Session, durationSeconds: Int) async throws
      func getTodaySession() async throws -> Session?
      func updateStreak(userId: UUID) async throws
  }
  
  final class SessionServiceImpl: SessionService {
      private let sessionRepository: SessionRepository
      private let userRepository: UserRepository
      
      init(sessionRepository: SessionRepository, userRepository: UserRepository) {
          self.sessionRepository = sessionRepository
          self.userRepository = userRepository
      }
      
      func startSession(type: Session.SessionType, surahNumbers: [Int], reciterId: Int?) async throws -> Session {
          guard let user = try await userRepository.getCurrentUser() else {
              throw SessionError.noUser
          }
          
          let session = Session(userId: user.id, type: type, surahNumbers: surahNumbers)
          session.reciterId = reciterId
          try await sessionRepository.createSession(session)
          
          // Save preferences
          UserDefaults.standard.set(surahNumbers, forKey: "lastSelectedSurahs")
          if let reciterId = reciterId {
              UserDefaults.standard.set(reciterId, forKey: "lastSelectedReciter")
          }
          
          return session
      }
      
      func endSession(_ session: Session, durationSeconds: Int) async throws {
          session.endTime = Date()
          session.durationSeconds = durationSeconds
          session.isCompleted = durationSeconds >= 120 // Minimum 2 minutes
          
          try await sessionRepository.updateSession(session)
          
          if session.isCompleted {
              try await updateStreak(userId: session.userId)
          }
      }
      
      func updateStreak(userId: UUID) async throws {
          guard var user = try await userRepository.getCurrentUser() else { return }
          
          let today = Calendar.current.startOfDay(for: Date())
          let lastActiveDay = user.lastActiveDate.map { Calendar.current.startOfDay(for: $0) }
          
          if let lastActive = lastActiveDay {
              let daysDiff = Calendar.current.dateComponents([.day], from: lastActive, to: today).day ?? 0
              
              if daysDiff == 0 {
                  // Already active today, no change
                  return
              } else if daysDiff == 1 {
                  // Consecutive day
                  user.currentStreak += 1
                  if user.currentStreak > user.longestStreak {
                      user.longestStreak = user.currentStreak
                  }
              } else {
                  // Streak broken
                  user.currentStreak = 1
              }
          } else {
              // First session ever
              user.currentStreak = 1
              user.longestStreak = 1
          }
          
          user.lastActiveDate = Date()
          try await userRepository.updateUser(user)
      }
  }
  
  enum SessionError: Error {
      case noUser
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Domain/Services/SessionServiceTests.swift`:
  ```swift
  final class SessionServiceTests: XCTestCase {
      var service: SessionService!
      var mockSessionRepo: MockSessionRepository!
      var mockUserRepo: MockUserRepository!
      
      func testStartSessionSavesPreferences() async throws {
          let session = try await service.startSession(
              type: .listening,
              surahNumbers: [1, 2, 3],
              reciterId: 7
          )
          
          XCTAssertEqual(session.surahNumbers, [1, 2, 3])
          XCTAssertEqual(session.reciterId, 7)
          
          let savedSurahs = UserDefaults.standard.array(forKey: "lastSelectedSurahs") as? [Int]
          XCTAssertEqual(savedSurahs, [1, 2, 3])
      }
      
      func testEndSessionUpdatesStreak() async throws {
          // Test streak logic
      }
      
      func testStreakIncrementOnConsecutiveDays() async throws {
          // Test streak increment
      }
      
      func testStreakBreaksAfterMissedDay() async throws {
          // Test streak reset
      }
  }
  ```

**Validation:**
- Sessions save correctly
- Preferences persist
- Streak logic works
- Tests pass

---

### 6.3 Listen Session View (Day 11)

**Tasks:**
- [ ] Create `Presentation/ListenSession/ListenSessionView.swift`
- [ ] Create `Presentation/ListenSession/ListenSessionViewModel.swift`:
  ```swift
  @MainActor
  final class ListenSessionViewModel: ObservableObject {
      @Published var selectedSurahs: [Int] = []
      @Published var selectedReciter: Int = 7 // Default: Mishary Alafasy
      @Published var isSessionActive = false
      @Published var currentSurahIndex = 0
      @Published var elapsedSeconds = 0
      @Published var isLoading = false
      
      private let quranService: QuranService
      private let sessionService: SessionService
      private let audioService: AudioPlayerService
      private let screenTimeService: ScreenTimeService
      
      private var currentSession: Session?
      private var timer: Timer?
      
      func startSession() async {
          isLoading = true
          
          do {
              // 1. Start session (saves preferences)
              currentSession = try await sessionService.startSession(
                  type: .listening,
                  surahNumbers: selectedSurahs,
                  reciterId: selectedReciter
              )
              
              // 2. Apply shields
              try await screenTimeService.applyListeningShields()
              
              // 3. Load and play first surah
              try await playCurrentSurah()
              
              // 4. Start timer
              startTimer()
              
              isSessionActive = true
          } catch {
              print("Failed to start session: \(error)")
          }
          
          isLoading = false
      }
      
      private func playCurrentSurah() async throws {
          let surahNumber = selectedSurahs[currentSurahIndex]
          let audioURL = try await quranService.getAudioURL(surah: surahNumber, reciter: selectedReciter)
          
          guard let url = URL(string: audioURL) else { return }
          try await audioService.loadAudio(url: url)
          audioService.play()
      }
      
      func endSession() async {
          timer?.invalidate()
          audioService.stop()
          
          if let session = currentSession {
              try? await sessionService.endSession(session, durationSeconds: elapsedSeconds)
          }
          
          // Check subscription before removing shields
          let subscriptionService = DIContainer.shared.subscriptionService
          let isPremium = try? await subscriptionService.checkSubscriptionStatus()
          
          if isPremium == true {
              try? await screenTimeService.removeListeningShields()
          } else {
              // Subscription expired, remove ALL shields
              try? await screenTimeService.removeAllShields()
              // Navigate to paywall
          }
          
          reset()
      }
      
      private func startTimer() {
          timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
              self?.elapsedSeconds += 1
          }
      }
  }
  ```

**Unit Tests:**
- [ ] Create `Tests/Presentation/ListenSession/ListenSessionViewModelTests.swift`

**Validation:**
- Can start session
- Audio plays
- Timer counts correctly
- Can end session
- Shields apply/remove correctly
- Tests pass

---

### PHASE 6 DELIVERABLES

**Code:**
- ✅ AudioPlayerService with background audio
- ✅ SessionService with streak logic
- ✅ ListenSessionView + ViewModel
- ✅ Preference saving on session start

**Tests:**
- ✅ AudioPlayerService tests
- ✅ SessionService tests (streak logic)
- ✅ ListenSessionViewModel tests
- ✅ 20+ unit tests passing

**Validation:**
- Audio plays in background
- Lock screen controls work
- Sessions save correctly
- Streak increments properly
- Preferences persist

---

## PHASE 7: BLOCKING + SETTINGS TABS
**Timeline:** Day 12 (Feb 14)  
**Goal:** Blocking management, settings screen, subscription status

### 7.1 Blocking Tab (Day 12 Morning)

**Tasks:**
- [ ] Create `Presentation/MainTabs/BlockingTab/BlockingTabView.swift`
- [ ] Create `Presentation/MainTabs/BlockingTab/BlockingTabViewModel.swift`
- [ ] Display list of blocked apps with time limits
- [ ] Add "Add More Apps" button
- [ ] Allow editing/removing apps

**Unit Tests:**
- [ ] Create `Tests/Presentation/MainTabs/BlockingTab/BlockingTabViewModelTests.swift`

---

### 7.2 Settings Tab (Day 12 Afternoon)

**Tasks:**
- [ ] Create `Presentation/MainTabs/SettingsTab/SettingsTabView.swift`
- [ ] Create `Presentation/MainTabs/SettingsTab/SettingsTabViewModel.swift`
- [ ] Display:
  - User profile info
  - Subscription status + expiry date
  - Manage subscription button
  - Sign out button
  - Delete account button

**Unit Tests:**
- [ ] Create `Tests/Presentation/MainTabs/SettingsTab/SettingsTabViewModelTests.swift`

---

### PHASE 7 DELIVERABLES

**Code:**
- ✅ BlockingTabView with app management
- ✅ SettingsTabView with profile + subscription
- ✅ Can add/edit/remove blocked apps
- ✅ Can manage subscription

**Tests:**
- ✅ BlockingTabViewModel tests
- ✅ SettingsTabViewModel tests
- ✅ 10+ unit tests passing

---

## PHASE 8: STREAK SYSTEM + HISTORY
**Timeline:** Day 13 (Feb 15)  
**Goal:** Streak display polished, session history visible

### 8.1 Streak Display Enhancement

**Tasks:**
- [ ] Polish StreakBadge component
- [ ] Add streak animation
- [ ] Display on Quran tab

---

### 8.2 Session History

**Tasks:**
- [ ] Create session history view (optional, in settings)
- [ ] Display past sessions with dates and durations

**Unit Tests:**
- [ ] Test session fetching
- [ ] Test date grouping

---

### PHASE 8 DELIVERABLES

**Code:**
- ✅ Polished streak display
- ✅ Session history view (if time permits)

**Tests:**
- ✅ Streak display tests
- ✅ History tests

---

## PHASE 9: POLISH + INTEGRATION TESTS
**Timeline:** Day 14 (Feb 16)  
**Goal:** UI polish, bug fixes, integration tests

### 9.1 UI Polish

**Tasks:**
- [ ] Review all screens for consistency
- [ ] Add loading states everywhere
- [ ] Add error messages
- [ ] Polish colors, spacing, fonts
- [ ] Add animations where appropriate

---

### 9.2 Integration Tests

**Tasks:**
- [ ] Create `Tests/Integration/` folder
- [ ] Test complete user flows:
  - [ ] Onboarding → Paywall → Main Tabs
  - [ ] Start listening session → End session → Streak updates
  - [ ] Purchase subscription → Access app → Subscription expires → Shield removed

**Integration Test Example:**
```swift
final class OnboardingFlowIntegrationTests: XCTestCase {
    func testCompleteOnboardingFlow() async throws {
        // Test full flow from auth to main tabs
    }
}
```

---

### PHASE 9 DELIVERABLES

**Code:**
- ✅ All UI polished
- ✅ Loading states everywhere
- ✅ Error handling consistent

**Tests:**
- ✅ 5+ integration tests
- ✅ Full user flow coverage

---

## PHASE 10: TESTFLIGHT
**Timeline:** Day 15 (Feb 17)  
**Goal:** Build uploaded, internal testing started

### 10.1 Build Preparation

**Tasks:**
- [ ] Bump version to 1.0.0 (build 1)
- [ ] Configure App Store Connect:
  - Create app listing
  - Add screenshots
  - Write description (see PRD Section 11.1)
- [ ] Archive build in Xcode
- [ ] Upload to TestFlight

---

### 10.2 Internal Testing

**Tasks:**
- [ ] Add internal testers
- [ ] Test on multiple devices
- [ ] Document critical bugs
- [ ] Fix critical bugs

---

### PHASE 10 DELIVERABLES

**Code:**
- ✅ TestFlight build uploaded
- ✅ Internal testing started
- ✅ Critical bugs documented

---

## PHASE 11: SUBMISSION + BUFFER
**Timeline:** Day 16 (Feb 18)  
**Goal:** App Store submission complete

### 11.1 Final Fixes

**Tasks:**
- [ ] Fix any critical bugs from TestFlight
- [ ] Final build uploaded

---

### 11.2 App Store Submission

**Tasks:**
- [ ] Complete App Store listing:
  - Name: Surah Focus
  - Subtitle: Block Apps, Build Quran Habits
  - Description (see PRD Section 11.1)
  - Screenshots (6 required)
  - Keywords
  - Privacy Policy URL
  - Terms of Service URL
- [ ] Submit for review
- [ ] 🎯 TARGET: Submit by Feb 18

---

### PHASE 11 DELIVERABLES

**Submission:**
- ✅ App Store submission complete
- ✅ Privacy Policy live
- ✅ Terms of Service live

---

## TESTING SUMMARY

### Unit Test Coverage Goals

| Layer | Target Coverage | Test Count |
|-------|----------------|------------|
| Entities | 100% | 10+ |
| Services | 100% | 40+ |
| Repositories | 100% | 30+ |
| ViewModels | 90%+ | 50+ |
| **Total** | **95%+** | **130+** |

### Test Execution

```bash
# Run all tests
make test

# Run specific test file
xcodebuild test -scheme SurahFocus -only-testing:SurahFocusTests/AuthServiceTests

# Generate coverage report
xcodebuild test -scheme SurahFocus -enableCodeCoverage YES
```

---

## CRITICAL SUCCESS METRICS

### Day-by-Day Checklist

- [ ] **Day 1-2:** Project setup complete, extensions configured
- [ ] **Day 3-4:** Auth + RevenueCat working, can subscribe
- [ ] **Day 5-6:** Onboarding complete, Screen Time working
- [ ] **Day 7:** Quran API integrated, 114 surahs loading
- [ ] **Day 8-9:** Main tabs functional, can read surahs
- [ ] **Day 10-11:** Audio playing, sessions saving, streak working
- [ ] **Day 12:** Blocking + Settings functional
- [ ] **Day 13:** Streak polished
- [ ] **Day 14:** All polish complete
- [ ] **Day 15:** TestFlight uploaded
- [ ] **Day 16:** App Store submitted ✅

---

## RISK MITIGATION

### High-Risk Items

1. **Screen Time API complexity**
   - Mitigation: Test early on physical device (Day 5-6)
   - Fallback: Simplify blocking logic if needed

2. **RevenueCat integration**
   - Mitigation: Setup Day 3, test immediately
   - Fallback: Direct StoreKit if RevenueCat fails

3. **Background audio**
   - Mitigation: Test lock screen controls Day 10
   - Fallback: Standard audio if background fails

4. **Timeline slip**
   - Mitigation: Cut optional features (history view, animations)
   - Critical path: Auth → Paywall → Quran → Audio → Blocking

---

## DAILY COMMIT STRATEGY

```bash
# Commit after each completed phase
git commit -m "✅ Phase 1: Foundation complete - all tests passing"
git commit -m "✅ Phase 2: Auth + RevenueCat - 25 tests passing"
git commit -m "✅ Phase 3: Onboarding + Screen Time - shields working"
# ... etc
```

---

## WHAT CAN BE CUT IF BEHIND SCHEDULE

**Low Priority (cut first):**
- Session history view
- Advanced animations
- Additional reciter options (ship with 3-5)
- Settings tab polish

**Medium Priority (cut if necessary):**
- Search functionality (browse only)
- Streak animations
- Custom shield UI (use default)

**Critical Path (CANNOT CUT):**
- Sign in with Apple
- RevenueCat + Paywall
- Screen Time API + Blocking
- Quran reading (text only)
- Audio playback (basic)
- Streak tracking (basic)

---

## FINAL NOTES

**Testing Philosophy:**
- Write tests WHILE implementing, not after
- Aim for 95%+ coverage on business logic
- Integration tests validate critical paths
- Manual testing on device for Screen Time features

**Code Quality:**
- Follow `PROJECT_RULES.md` patterns strictly
- All ViewModels must have `@MainActor`
- All async methods use `async throws`
- Error handling with `do/catch`
- No force unwraps (!)

**Communication:**
- Daily commit with phase completion
- Document blockers immediately
- Ask for help early if stuck

---

**🎯 TARGET: App Store submission by February 18, 2026**

**Let's build this. 🚀**
