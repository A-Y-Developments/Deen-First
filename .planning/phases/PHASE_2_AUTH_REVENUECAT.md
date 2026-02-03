# PHASE 2: AUTHENTICATION + REVENUECAT
**Timeline:** Days 3-4 (Feb 5-6)  
**Duration:** 2 full days  
**Goal:** Sign in with Apple working, RevenueCat integrated, Paywall functional

---

## PREREQUISITES

- [ ] Phase 1 completed (all tests passing)
- [ ] RevenueCat account created
- [ ] Apple Developer account with App IDs configured
- [ ] Physical device for testing (Sign in with Apple doesn't work on simulator)

---

## PHASE OVERVIEW

This phase implements complete authentication and monetization:
1. RevenueCat SDK integration
2. Sign in with Apple authentication
3. User management with SwiftData
4. Subscription service with purchase logic
5. Paywall UI with pricing options
6. Restore purchases functionality

**By end of Phase 2, you will have:**
- ✅ Sign in with Apple fully functional
- ✅ RevenueCat configured with products
- ✅ Paywall showing subscription options
- ✅ Purchase flow working (sandbox)
- ✅ User persistence with subscription status
- ✅ 25+ unit tests passing

---

## TASK 2.1: REVENUECAT SETUP (Day 3 Morning - 2 hours)

### Step 1: Create RevenueCat Account

1. Go to https://www.revenuecat.com
2. Sign up with your email
3. Create new project: "Surah Focus"
4. Select iOS platform

### Step 2: Configure App in RevenueCat

**In RevenueCat Dashboard:**

1. **Project Settings:**
   - App Name: Surah Focus
   - Bundle ID: `com.aydev.surahfocus`
   - Platform: iOS

2. **Apple App Store Connect:**
   - Connect your App Store Connect account
   - Select your app
   - Enable sandbox testing

### Step 3: Create Products

**Product 1: Monthly Subscription**
- Product ID: `com.aydev.surahfocus.monthly`
- Type: Auto-renewable subscription
- Price: $4.99/month
- Trial: 3 days
- Subscription Group: Default

**Product 2: Yearly Subscription**
- Product ID: `com.aydev.surahfocus.yearly`
- Type: Auto-renewable subscription
- Price: $29.99/year
- Trial: 7 days
- Subscription Group: Default

### Step 4: Create Entitlement

**Entitlement Configuration:**
- Entitlement ID: `premium`
- Description: Premium access to all features
- Attach Products:
  - ✅ com.aydev.surahfocus.monthly
  - ✅ com.aydev.surahfocus.yearly

### Step 5: Get API Key

1. Go to RevenueCat Dashboard > API Keys
2. Copy your **Public API Key** (starts with `appl_`)
3. Save it securely

### Step 6: Update .env File

```bash
# Add to .env
REVENUECAT_API_KEY=appl_YOUR_KEY_HERE
```

### Verification Checkpoint 1:

**In RevenueCat Dashboard:**
- [ ] Project created
- [ ] 2 products configured
- [ ] 1 entitlement created with both products attached
- [ ] API key copied

---

## TASK 2.2: USER REPOSITORY IMPLEMENTATION (Day 3 Morning - 2 hours)

### Step 1: Implement LocalDataSource User Methods

**Update `Sources/Data/DataSource/LocalDataSource.swift`:**

```swift
import SwiftData
import Foundation

final class LocalDataSource {
    private let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }
    
    // MARK: - User Operations
    
    @MainActor
    func insertUser(_ user: User) throws {
        let context = container.mainContext
        context.insert(user)
        try context.save()
    }
    
    @MainActor
    func getUser(byAppleUserId appleUserId: String) throws -> User? {
        let context = container.mainContext
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserId == appleUserId }
        )
        let users = try context.fetch(descriptor)
        return users.first
    }
    
    @MainActor
    func getFirstUser() throws -> User? {
        let context = container.mainContext
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        return users.first
    }
    
    @MainActor
    func updateUser(_ user: User) throws {
        // SwiftData auto-saves changes to @Model objects
        let context = container.mainContext
        try context.save()
    }
    
    @MainActor
    func deleteUser(_ user: User) throws {
        let context = container.mainContext
        context.delete(user)
        try context.save()
    }
    
    @MainActor
    func deleteAllUsers() throws {
        let context = container.mainContext
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        for user in users {
            context.delete(user)
        }
        try context.save()
    }
}
```

### Step 2: Implement UserRepository

**Create `Sources/Data/Repositories/UserRepository.swift`:**

```swift
import Foundation

protocol UserRepository {
    func createUser(_ user: User) async throws
    func getUser(byAppleUserId appleUserId: String) async throws -> User?
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
        try await MainActor.run {
            try localDataSource.insertUser(user)
        }
    }
    
    func getUser(byAppleUserId appleUserId: String) async throws -> User? {
        try await MainActor.run {
            try localDataSource.getUser(byAppleUserId: appleUserId)
        }
    }
    
    func getCurrentUser() async throws -> User? {
        try await MainActor.run {
            try localDataSource.getFirstUser()
        }
    }
    
    func updateUser(_ user: User) async throws {
        try await MainActor.run {
            try localDataSource.updateUser(user)
        }
    }
    
    func deleteCurrentUser() async throws {
        try await MainActor.run {
            guard let user = try localDataSource.getFirstUser() else { return }
            try localDataSource.deleteUser(user)
        }
    }
}
```

### Step 3: Create UserRepository Tests

**Create `Tests/Data/Repositories/UserRepositoryTests.swift`:**

```swift
import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class UserRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var repository: UserRepository!
    
    override func setUp() async throws {
        let schema = Schema([User.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        repository = UserRepositoryImpl(localDataSource: localDataSource)
    }
    
    override func tearDown() {
        container = nil
        localDataSource = nil
        repository = nil
    }
    
    func testCreateUser() async throws {
        let user = User(appleUserId: "test123", email: "test@example.com")
        
        try await repository.createUser(user)
        
        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.appleUserId, "test123")
    }
    
    func testGetUserByAppleUserId() async throws {
        let user = User(appleUserId: "test456", email: "test456@example.com")
        try await repository.createUser(user)
        
        let fetchedUser = try await repository.getUser(byAppleUserId: "test456")
        
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.email, "test456@example.com")
    }
    
    func testGetUserByAppleUserIdReturnsNilWhenNotFound() async throws {
        let fetchedUser = try await repository.getUser(byAppleUserId: "nonexistent")
        
        XCTAssertNil(fetchedUser)
    }
    
    func testGetCurrentUser() async throws {
        let user = User(appleUserId: "current123")
        try await repository.createUser(user)
        
        let currentUser = try await repository.getCurrentUser()
        
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.appleUserId, "current123")
    }
    
    func testGetCurrentUserReturnsNilWhenNoUsers() async throws {
        let currentUser = try await repository.getCurrentUser()
        
        XCTAssertNil(currentUser)
    }
    
    func testUpdateUser() async throws {
        let user = User(appleUserId: "update123")
        try await repository.createUser(user)
        
        guard var fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }
        
        fetchedUser.isPremium = true
        fetchedUser.currentStreak = 5
        try await repository.updateUser(fetchedUser)
        
        let updatedUser = try await repository.getCurrentUser()
        XCTAssertTrue(updatedUser?.isPremium ?? false)
        XCTAssertEqual(updatedUser?.currentStreak, 5)
    }
    
    func testDeleteCurrentUser() async throws {
        let user = User(appleUserId: "delete123")
        try await repository.createUser(user)
        
        try await repository.deleteCurrentUser()
        
        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNil(fetchedUser)
    }
}
```

### Verification Checkpoint 2:

```bash
make test
```

**Expected Output:**
```
Test Suite 'UserRepositoryTests' passed (7 tests)
```

---

## TASK 2.3: AUTH SERVICE IMPLEMENTATION (Day 3 Afternoon - 3 hours)

### Step 1: Implement AuthService

**Create `Sources/Domain/Services/AuthService.swift`:**

```swift
import Foundation
import AuthenticationServices

protocol AuthService {
    func signInWithApple(
        authorization: ASAuthorization
    ) async throws -> User
    func getCurrentUser() async throws -> User?
    func signOut() async throws
}

final class AuthServiceImpl: AuthService {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    func signInWithApple(
        authorization: ASAuthorization
    ) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }
        
        let appleUserId = credential.user
        
        // Check if user already exists
        if let existingUser = try await userRepository.getUser(byAppleUserId: appleUserId) {
            return existingUser
        }
        
        // Create new user
        let newUser = User(
            appleUserId: appleUserId,
            email: credential.email,
            name: credential.fullName?.givenName
        )
        
        try await userRepository.createUser(newUser)
        return newUser
    }
    
    func getCurrentUser() async throws -> User? {
        return try await userRepository.getCurrentUser()
    }
    
    func signOut() async throws {
        try await userRepository.deleteCurrentUser()
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case userNotFound
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credential"
        case .userNotFound:
            return "User not found"
        case .cancelled:
            return "Authentication was cancelled"
        }
    }
}
```

### Step 2: Create AuthService Tests

**Create `Tests/Domain/Services/AuthServiceTests.swift`:**

```swift
import XCTest
import AuthenticationServices
@testable import SurahFocus

@MainActor
final class AuthServiceTests: XCTestCase {
    var mockUserRepository: MockUserRepository!
    var authService: AuthService!
    
    override func setUp() {
        mockUserRepository = MockUserRepository()
        authService = AuthServiceImpl(userRepository: mockUserRepository)
    }
    
    override func tearDown() {
        mockUserRepository = nil
        authService = nil
    }
    
    func testGetCurrentUserReturnsUser() async throws {
        let mockUser = User(appleUserId: "test123")
        mockUserRepository.userToReturn = mockUser
        
        let user = try await authService.getCurrentUser()
        
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.appleUserId, "test123")
    }
    
    func testGetCurrentUserReturnsNilWhenNoUser() async throws {
        mockUserRepository.userToReturn = nil
        
        let user = try await authService.getCurrentUser()
        
        XCTAssertNil(user)
    }
    
    func testSignOutDeletesUser() async throws {
        try await authService.signOut()
        
        XCTAssertTrue(mockUserRepository.didCallDeleteCurrentUser)
    }
    
    func testAuthErrorDescriptions() {
        XCTAssertEqual(
            AuthError.invalidCredential.errorDescription,
            "Invalid authentication credential"
        )
        XCTAssertEqual(
            AuthError.userNotFound.errorDescription,
            "User not found"
        )
        XCTAssertEqual(
            AuthError.cancelled.errorDescription,
            "Authentication was cancelled"
        )
    }
}

// MARK: - Mock Repository

class MockUserRepository: UserRepository {
    var userToReturn: User?
    var didCallCreateUser = false
    var didCallDeleteCurrentUser = false
    var didCallUpdateUser = false
    
    func createUser(_ user: User) async throws {
        didCallCreateUser = true
    }
    
    func getUser(byAppleUserId appleUserId: String) async throws -> User? {
        return userToReturn
    }
    
    func getCurrentUser() async throws -> User? {
        return userToReturn
    }
    
    func updateUser(_ user: User) async throws {
        didCallUpdateUser = true
    }
    
    func deleteCurrentUser() async throws {
        didCallDeleteCurrentUser = true
    }
}
```

### Verification Checkpoint 3:

```bash
make test
```

**Expected Output:**
```
Test Suite 'AuthServiceTests' passed (4 tests)
```

---

## TASK 2.4: SUBSCRIPTION SERVICE (Day 3 Evening - 3 hours)

### Step 1: Initialize RevenueCat in App

**Update `Sources/SurahFocusApp.swift`:**

```swift
import SwiftUI
import SwiftData
import RevenueCat

@main
struct SurahFocusApp: App {
    
    init() {
        // Configure RevenueCat
        if let apiKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
            Purchases.configure(withAPIKey: apiKey)
            Purchases.logLevel = .debug
        } else {
            print("⚠️ RevenueCat API key not found in environment")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(DIContainer.shared.mainContext.container)
        }
    }
}
```

### Step 2: Implement SubscriptionService

**Create `Sources/Domain/Services/SubscriptionService.swift`:**

```swift
import Foundation
import RevenueCat

protocol SubscriptionService {
    func checkSubscriptionStatus() async throws -> Bool
    func fetchOfferings() async throws -> Offerings
    func purchaseMonthly() async throws -> Bool
    func purchaseYearly() async throws -> Bool
    func restorePurchases() async throws -> Bool
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
    
    func fetchOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        
        guard let current = offerings.current else {
            throw SubscriptionError.noOfferingsAvailable
        }
        
        return offerings
    }
    
    func purchaseMonthly() async throws -> Bool {
        let offerings = try await Purchases.shared.offerings()
        
        guard let package = offerings.current?.monthly else {
            throw SubscriptionError.packageNotFound("monthly")
        }
        
        let result = try await Purchases.shared.purchase(package: package)
        let isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
        
        // Update local user
        if var user = try await userRepository.getCurrentUser() {
            user.isPremium = isPremium
            user.subscriptionExpiryDate = result.customerInfo.entitlements["premium"]?.expirationDate
            try await userRepository.updateUser(user)
        }
        
        return isPremium
    }
    
    func purchaseYearly() async throws -> Bool {
        let offerings = try await Purchases.shared.offerings()
        
        guard let package = offerings.current?.annual else {
            throw SubscriptionError.packageNotFound("yearly")
        }
        
        let result = try await Purchases.shared.purchase(package: package)
        let isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
        
        // Update local user
        if var user = try await userRepository.getCurrentUser() {
            user.isPremium = isPremium
            user.subscriptionExpiryDate = result.customerInfo.entitlements["premium"]?.expirationDate
            try await userRepository.updateUser(user)
        }
        
        return isPremium
    }
    
    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        let isPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        // Update local user
        if var user = try await userRepository.getCurrentUser() {
            user.isPremium = isPremium
            user.subscriptionExpiryDate = customerInfo.entitlements["premium"]?.expirationDate
            try await userRepository.updateUser(user)
        }
        
        return isPremium
    }
}

enum SubscriptionError: Error, LocalizedError {
    case packageNotFound(String)
    case noOfferingsAvailable
    case purchaseCancelled
    case purchaseFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .packageNotFound(let type):
            return "Subscription package '\(type)' not found"
        case .noOfferingsAvailable:
            return "No subscription offerings available"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        }
    }
}
```

### Step 3: Create SubscriptionService Tests

**Create `Tests/Domain/Services/SubscriptionServiceTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

@MainActor
final class SubscriptionServiceTests: XCTestCase {
    var mockUserRepository: MockUserRepository!
    var subscriptionService: SubscriptionService!
    
    override func setUp() {
        mockUserRepository = MockUserRepository()
        subscriptionService = SubscriptionServiceImpl(userRepository: mockUserRepository)
    }
    
    override func tearDown() {
        mockUserRepository = nil
        subscriptionService = nil
    }
    
    // Note: Full RevenueCat integration tests require sandbox environment
    // These are unit tests for the service logic only
    
    func testSubscriptionErrorDescriptions() {
        let packageError = SubscriptionError.packageNotFound("monthly")
        XCTAssertEqual(
            packageError.errorDescription,
            "Subscription package 'monthly' not found"
        )
        
        let offeringsError = SubscriptionError.noOfferingsAvailable
        XCTAssertEqual(
            offeringsError.errorDescription,
            "No subscription offerings available"
        )
    }
}
```

### Verification Checkpoint 4:

```bash
make test
```

**Expected Output:**
```
Test Suite 'SubscriptionServiceTests' passed (1 test)
```

---

## TASK 2.5: AUTH VIEW + VIEWMODEL (Day 4 Morning - 3 hours)

### Step 1: Create AuthViewModel

**Create `Sources/Presentation/Auth/AuthViewModel.swift`:**

```swift
import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let authService: AuthService
    
    init(authService: AuthService? = nil) {
        self.authService = authService ?? DIContainer.shared.authService
    }
    
    func handleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        defer { isLoading = false }
        
        switch result {
        case .success(let authorization):
            do {
                _ = try await authService.signInWithApple(authorization: authorization)
                // Navigation handled by RootView
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func checkExistingUser() async -> Bool {
        do {
            let user = try await authService.getCurrentUser()
            return user != nil
        } catch {
            return false
        }
    }
}
```

### Step 2: Create AuthView

**Create `Sources/Presentation/Auth/AuthView.swift`:**

```swift
import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // App Name & Tagline
                VStack(spacing: 8) {
                    Text("Surah Focus")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Block Apps, Build Quran Habits")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Sign in with Apple Button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        await viewModel.handleSignIn(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 32)
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            // Check if user already signed in
            if await viewModel.checkExistingUser() {
                router.replaceWith(.onboarding)
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(Router())
}
```

### Step 3: Create AuthViewModel Tests

**Create `Tests/Presentation/Auth/AuthViewModelTests.swift`:**

```swift
import XCTest
import AuthenticationServices
@testable import SurahFocus

@MainActor
final class AuthViewModelTests: XCTestCase {
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testCheckExistingUserReturnsTrue() async {
        mockAuthService.userToReturn = User(appleUserId: "test123")
        
        let hasUser = await viewModel.checkExistingUser()
        
        XCTAssertTrue(hasUser)
    }
    
    func testCheckExistingUserReturnsFalse() async {
        mockAuthService.userToReturn = nil
        
        let hasUser = await viewModel.checkExistingUser()
        
        XCTAssertFalse(hasUser)
    }
}

// MARK: - Mock Auth Service

class MockAuthService: AuthService {
    var userToReturn: User?
    var shouldThrowError = false
    
    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        if shouldThrowError {
            throw AuthError.invalidCredential
        }
        let user = User(appleUserId: "mock123")
        userToReturn = user
        return user
    }
    
    func getCurrentUser() async throws -> User? {
        return userToReturn
    }
    
    func signOut() async throws {
        userToReturn = nil
    }
}
```

### Verification Checkpoint 5:

```bash
make test
```

**Expected Output:**
```
Test Suite 'AuthViewModelTests' passed (3 tests)
```

---

## TASK 2.6: PAYWALL VIEW + VIEWMODEL (Day 4 Afternoon - 4 hours)

### Step 1: Create PaywallViewModel

**Create `Sources/Presentation/Paywall/PaywallViewModel.swift`:**

```swift
import SwiftUI
import RevenueCat

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var monthlyPackage: Package?
    @Published var yearlyPackage: Package?
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let subscriptionService: SubscriptionService
    
    enum SubscriptionPlan {
        case monthly
        case yearly
    }
    
    init(subscriptionService: SubscriptionService? = nil) {
        self.subscriptionService = subscriptionService ?? DIContainer.shared.subscriptionService
    }
    
    func loadOfferings() async {
        isLoading = true
        
        do {
            let offerings = try await subscriptionService.fetchOfferings()
            monthlyPackage = offerings.current?.monthly
            yearlyPackage = offerings.current?.annual
        } catch {
            errorMessage = "Failed to load subscription options"
            showError = true
        }
        
        isLoading = false
    }
    
    func purchase() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let success: Bool
            
            switch selectedPlan {
            case .monthly:
                success = try await subscriptionService.purchaseMonthly()
            case .yearly:
                success = try await subscriptionService.purchaseYearly()
            }
            
            return success
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            return try await subscriptionService.restorePurchases()
        } catch {
            errorMessage = "No purchases to restore"
            showError = true
            return false
        }
    }
    
    var selectedPackagePrice: String {
        switch selectedPlan {
        case .monthly:
            return monthlyPackage?.localizedPriceString ?? "$4.99"
        case .yearly:
            return yearlyPackage?.localizedPriceString ?? "$29.99"
        }
    }
    
    var trialDurationText: String {
        switch selectedPlan {
        case .monthly:
            return "3-day"
        case .yearly:
            return "7-day"
        }
    }
}
```

### Step 2: Create PaywallView

**Create `Sources/Presentation/Paywall/PaywallView.swift`:**

```swift
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Unlock Your Quran Journey")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Start your free trial, cancel anytime")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "shield.fill", text: "Block distracting apps")
                        FeatureRow(icon: "book.fill", text: "Read Quran with translations")
                        FeatureRow(icon: "speaker.wave.2.fill", text: "Listen to beautiful recitations")
                        FeatureRow(icon: "flame.fill", text: "Track your daily streak")
                        FeatureRow(icon: "clock.fill", text: "Set time limits & schedules")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Build a daily Quran habit")
                    }
                    .padding(.horizontal, 24)
                    
                    // Subscription Plans
                    VStack(spacing: 12) {
                        // Yearly Plan
                        SubscriptionCard(
                            title: "Yearly",
                            price: viewModel.yearlyPackage?.localizedPriceString ?? "$29.99/year",
                            savings: "Save 50%",
                            trial: "7-day free trial",
                            isSelected: viewModel.selectedPlan == .yearly,
                            badge: "RECOMMENDED"
                        ) {
                            viewModel.selectedPlan = .yearly
                        }
                        
                        // Monthly Plan
                        SubscriptionCard(
                            title: "Monthly",
                            price: viewModel.monthlyPackage?.localizedPriceString ?? "$4.99/month",
                            savings: nil,
                            trial: "3-day free trial",
                            isSelected: viewModel.selectedPlan == .monthly,
                            badge: nil
                        ) {
                            viewModel.selectedPlan = .monthly
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // CTA Button
                    Button {
                        Task {
                            if await viewModel.purchase() {
                                router.navigate(to: .screenTimePermission)
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start \(viewModel.trialDurationText) Free Trial")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    
                    // Footer Links
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task {
                                if await viewModel.restorePurchases() {
                                    router.navigate(to: .mainTabs)
                                }
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // Open terms URL
                            }
                            
                            Text("•")
                            
                            Button("Privacy") {
                                // Open privacy URL
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            await viewModel.loadOfferings()
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "4facfe"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let title: String
    let price: String
    let savings: String?
    let trial: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "1a1a2e"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "FFD700"))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(price)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "4facfe"))
                        }
                        
                        Text(trial)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Circle()
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.white.opacity(0.3),
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "4facfe") : Color.clear)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(Router())
}
```

### Step 3: Create PaywallViewModel Tests

**Create `Tests/Presentation/Paywall/PaywallViewModelTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

@MainActor
final class PaywallViewModelTests: XCTestCase {
    var viewModel: PaywallViewModel!
    var mockSubscriptionService: MockSubscriptionService!
    
    override func setUp() {
        mockSubscriptionService = MockSubscriptionService()
        viewModel = PaywallViewModel(subscriptionService: mockSubscriptionService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockSubscriptionService = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.selectedPlan, .yearly)
        XCTAssertNil(viewModel.monthlyPackage)
        XCTAssertNil(viewModel.yearlyPackage)
    }
    
    func testTrialDurationTextForMonthly() {
        viewModel.selectedPlan = .monthly
        XCTAssertEqual(viewModel.trialDurationText, "3-day")
    }
    
    func testTrialDurationTextForYearly() {
        viewModel.selectedPlan = .yearly
        XCTAssertEqual(viewModel.trialDurationText, "7-day")
    }
}

// MARK: - Mock Subscription Service

class MockSubscriptionService: SubscriptionService {
    var shouldReturnPremium = true
    var shouldThrowError = false
    
    func checkSubscriptionStatus() async throws -> Bool {
        return shouldReturnPremium
    }
    
    func fetchOfferings() async throws -> RevenueCat.Offerings {
        // Mock implementation
        fatalError("Use real RevenueCat for integration tests")
    }
    
    func purchaseMonthly() async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }
    
    func purchaseYearly() async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }
    
    func restorePurchases() async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }
}
```

### Verification Checkpoint 6:

```bash
make test
```

**Expected Output:**
```
Test Suite 'PaywallViewModelTests' passed (3 tests)
```

---

## TASK 2.7: UPDATE ROOTVIEW WITH NAVIGATION (Day 4 Evening - 1 hour)

**Update `Sources/RootView.swift`:**

```swift
import SwiftUI

struct RootView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            AuthView()
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
            AuthView()
        case .onboarding:
            Text("Onboarding View - Phase 3")
        case .paywall:
            PaywallView()
        case .screenTimePermission:
            Text("Screen Time Permission - Phase 3")
        case .appSelection:
            Text("App Selection - Phase 3")
        case .mainTabs:
            Text("Main Tabs - Phase 5")
        case .surahDetail(let surahId):
            Text("Surah \(surahId) - Phase 5")
        case .listenSession:
            Text("Listen Session - Phase 6")
        }
    }
}

#Preview {
    RootView()
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
Test Suite 'UserRepositoryTests' passed (7 tests)
Test Suite 'AuthServiceTests' passed (4 tests)
Test Suite 'SubscriptionServiceTests' passed (1 test)
Test Suite 'AuthViewModelTests' passed (3 tests)
Test Suite 'PaywallViewModelTests' passed (3 tests)

Test Suite 'SurahFocusTests' passed (48 tests)
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

### Step 3: Test on Physical Device (CRITICAL)

**Sign in with Apple requires physical device:**

1. Connect your iOS 17+ device
2. In Xcode, select your device
3. Build and run (Cmd+R)
4. Test flow:
   - [ ] App launches
   - [ ] Auth screen appears
   - [ ] Tap "Sign in with Apple"
   - [ ] Apple authentication dialog appears
   - [ ] Sign in successfully
   - [ ] Navigate to paywall
   - [ ] Paywall displays correct pricing
   - [ ] Can select monthly/yearly
   - [ ] Can tap purchase (test in sandbox)

### Step 4: Test RevenueCat Integration

**In Sandbox Environment:**

1. Sign out of App Store on device
2. Settings > App Store > Sign Out
3. Run app
4. Complete sign in
5. On paywall, tap purchase
6. Enter sandbox test account
7. Verify purchase completes
8. Check RevenueCat dashboard for event

---

## PHASE 2 COMPLETION CHECKLIST

### RevenueCat Setup
- [ ] RevenueCat account created
- [ ] App configured in dashboard
- [ ] 2 products created (monthly, yearly)
- [ ] Entitlement created ("premium")
- [ ] API key obtained and added to .env
- [ ] Sandbox test account created

### User Repository
- [ ] LocalDataSource user methods implemented
- [ ] UserRepository protocol defined
- [ ] UserRepositoryImpl implemented
- [ ] 7 repository tests passing

### Auth Service
- [ ] AuthService protocol defined
- [ ] AuthServiceImpl with Sign in with Apple
- [ ] AuthError enum with descriptions
- [ ] 4 auth service tests passing

### Subscription Service
- [ ] SubscriptionService protocol defined
- [ ] SubscriptionServiceImpl with RevenueCat
- [ ] Purchase methods (monthly, yearly, restore)
- [ ] Subscription status checking
- [ ] 1 subscription service test passing

### Auth View
- [ ] AuthViewModel implemented
- [ ] AuthView with Sign in with Apple button
- [ ] Loading states
- [ ] Error handling
- [ ] 3 auth viewmodel tests passing

### Paywall View
- [ ] PaywallViewModel implemented
- [ ] PaywallView with pricing cards
- [ ] Plan selection (monthly/yearly)
- [ ] Purchase flow
- [ ] Restore purchases
- [ ] 3 paywall viewmodel tests passing

### Integration
- [ ] RootView updated with navigation
- [ ] DIContainer updated with new services
- [ ] All tests passing (48+ tests)
- [ ] App builds successfully
- [ ] Sign in works on physical device
- [ ] Purchase flow works in sandbox

### Verification Commands
```bash
# All tests pass
make test

# Build succeeds
make build

# Check RevenueCat initialization
# Should see in console: "RevenueCat configured"
```

---

## TROUBLESHOOTING

### Issue: RevenueCat not initializing
**Solution:**
1. Check REVENUECAT_API_KEY in .env
2. Verify API key is correct in RevenueCat dashboard
3. Check console for RevenueCat logs

### Issue: Sign in with Apple not working
**Solution:**
1. Must use physical device (doesn't work in simulator)
2. Check App ID has "Sign in with Apple" capability enabled
3. Verify entitlements file is correct
4. Check device is signed in to iCloud

### Issue: Products not loading
**Solution:**
1. Check product IDs match exactly in RevenueCat and App Store Connect
2. Verify products are approved in App Store Connect
3. Check App Store Connect agreement is signed
4. Wait 24 hours after creating products

### Issue: Purchase fails in sandbox
**Solution:**
1. Sign out of real App Store account on device
2. Use sandbox test account when prompted
3. Check sandbox account is valid in App Store Connect
4. Clear app data and try again

---

## NEXT PHASE PREVIEW

**Phase 3 will cover:**
- 4-screen onboarding survey
- Screen Time permission request
- App selection with FamilyActivityPicker
- Time limit configuration
- First Screen Time shield test

**Prerequisites for Phase 3:**
- Phase 2 fully complete
- Can sign in successfully
- Can access paywall
- RevenueCat working in sandbox

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 2.1 (RevenueCat Setup): 2 hours
- Task 2.2 (User Repository): 2 hours
- Task 2.3 (Auth Service): 3 hours
- Task 2.4 (Subscription Service): 3 hours
- Task 2.5 (Auth View): 3 hours
- Task 2.6 (Paywall View): 4 hours
- Task 2.7 (RootView Update): 1 hour
- **Total: 18 hours over 2 days**

**If behind schedule:**
- Skip some unit tests (add post-launch)
- Simplify paywall UI
- Test with mock data instead of sandbox

---

**🎯 PHASE 2 COMPLETE! Ready for Phase 3: Onboarding + Screen Time**

Commit your work:
```bash
git add .
git commit -m "✅ Phase 2 complete: Auth + RevenueCat + 48 tests passing"
git push
```
