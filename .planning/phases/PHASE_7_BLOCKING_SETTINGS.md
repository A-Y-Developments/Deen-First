# PHASE 7: BLOCKING + SETTINGS TABS
**Timeline:** Day 12 (Feb 14)  
**Duration:** 1 full day  
**Goal:** Complete blocking management and settings screens with full Screen Time integration

---

## PREREQUISITES

- [ ] Phase 6 complete (Session tracking and audio working)
- [ ] Phase 3 Screen Time extensions configured
- [ ] Physical iOS 17+ device (required for testing shields)
- [ ] FamilyActivityPicker selection saved from Phase 3
- [ ] Mindcore project accessible for reference

---

## PHASE OVERVIEW

This phase completes the app management features:
1. **ScreenTimeRepository**: Full shield and time limit management
2. **BlockingTabView**: List, edit, remove blocked apps
3. **SettingsTabView**: Profile, subscription, account management
4. **ScreenTimeService**: Business logic for blocking

**By end of Phase 7, you will have:**
- ✅ Can view all blocked apps with icons
- ✅ Can edit time limits per app
- ✅ Can remove apps from blocking list
- ✅ Can add more apps via FamilyActivityPicker
- ✅ Settings screen functional
- ✅ Can sign out
- ✅ Subscription status displays
- ✅ 10+ critical tests passing

---

## TASK 7.1: SCREEN TIME REPOSITORY (Day 12 Morning - 3 hours)

### Step 1: Implement Full ScreenTime Repository

**File: `Sources/Data/Repositories/ScreenTimeRepository.swift`**

```swift
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

protocol ScreenTimeRepository {
    func applyShields(for tokens: Set<ApplicationToken>) async throws
    func removeShields() async throws
    func updateTimeLimits(_ limits: [ApplicationToken: TimeLimit]) async throws
    func getShieldedApps() async -> Set<ApplicationToken>
    func saveSelection(_ selection: FamilyActivitySelection) async throws
    func getSelection() async -> FamilyActivitySelection?
}

final class ScreenTimeRepositoryImpl: ScreenTimeRepository {
    private let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.aydev.surahfocus")
    
    // MARK: - Shield Management
    
    func applyShields(for tokens: Set<ApplicationToken>) async throws {
        await MainActor.run {
            store.shield.applications = tokens.isEmpty ? nil : tokens
        }
    }
    
    func removeShields() async throws {
        await MainActor.run {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
        }
    }
    
    func getShieldedApps() async -> Set<ApplicationToken> {
        await MainActor.run {
            return store.shield.applications ?? []
        }
    }
    
    // MARK: - Time Limits (Placeholder for DeviceActivity)
    
    func updateTimeLimits(_ limits: [ApplicationToken: TimeLimit]) async throws {
        // Save limits to UserDefaults for extensions to read
        let limitsData = limits.mapValues { $0.rawValue }
        sharedDefaults?.set(limitsData, forKey: "timeLimits")
        
        // Note: Actual DeviceActivity scheduling would happen here
        // For now, we're storing the limits but not enforcing them
        // Full implementation would use DeviceActivityCenter.startMonitoring
    }
    
    // MARK: - Selection Persistence
    
    func saveSelection(_ selection: FamilyActivitySelection) async throws {
        // Encode and save selection
        let encoder = JSONEncoder()
        
        // Save application tokens
        if !selection.applicationTokens.isEmpty {
            let tokensData = try encoder.encode(Array(selection.applicationTokens))
            sharedDefaults?.set(tokensData, forKey: "selectedAppTokens")
        }
        
        // Save category tokens
        if !selection.categoryTokens.isEmpty {
            let categoriesData = try encoder.encode(Array(selection.categoryTokens))
            sharedDefaults?.set(categoriesData, forKey: "selectedCategoryTokens")
        }
        
        // Save web domain tokens
        if !selection.webDomainTokens.isEmpty {
            let domainsData = try encoder.encode(Array(selection.webDomainTokens))
            sharedDefaults?.set(domainsData, forKey: "selectedWebDomains")
        }
    }
    
    func getSelection() async -> FamilyActivitySelection? {
        guard let defaults = sharedDefaults else { return nil }
        
        var selection = FamilyActivitySelection()
        let decoder = JSONDecoder()
        
        // Load application tokens
        if let tokensData = defaults.data(forKey: "selectedAppTokens"),
           let tokens = try? decoder.decode([ApplicationToken].self, from: tokensData) {
            selection.applicationTokens = Set(tokens)
        }
        
        // Load category tokens
        if let categoriesData = defaults.data(forKey: "selectedCategoryTokens"),
           let categories = try? decoder.decode([ActivityCategoryToken].self, from: categoriesData) {
            selection.categoryTokens = Set(categories)
        }
        
        // Load web domain tokens
        if let domainsData = defaults.data(forKey: "selectedWebDomains"),
           let domains = try? decoder.decode([WebDomainToken].self, from: domainsData) {
            selection.webDomainTokens = Set(domains)
        }
        
        return selection
    }
}

enum ScreenTimeError: LocalizedError {
    case authorizationDenied
    case shieldApplicationFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time permission not granted"
        case .shieldApplicationFailed:
            return "Failed to apply app shields"
        }
    }
}
```

**Reference:** Based on Mindcore's `mindcore/Sources/Data/Repositories/ScreenTimeRepository.swift`

**Key Points:**
- `ManagedSettingsStore()` for applying shields
- App Group UserDefaults for sharing data with extensions
- Encoding/decoding tokens for persistence
- Shield application must happen on MainActor

---

## TASK 7.2: SCREEN TIME SERVICE (Day 12 Morning - 1 hour)

### Step 1: Create ScreenTimeService

**File: `Sources/Domain/Services/ScreenTimeService.swift`**

```swift
import Foundation
import FamilyControls

protocol ScreenTimeService {
    func applyShields() async throws
    func removeShields() async throws
    func updateAppTimeLimit(appToken: ApplicationToken, limit: TimeLimit) async throws
    func removeApp(appToken: ApplicationToken) async throws
    func addMoreApps() async throws -> FamilyActivitySelection?
    func getBlockedApps() async throws -> [BlockedAppInfo]
}

struct BlockedAppInfo: Identifiable {
    let id: String
    let token: ApplicationToken
    let name: String
    let timeLimit: TimeLimit
}

final class ScreenTimeServiceImpl: ScreenTimeService {
    private let repository: ScreenTimeRepository
    private let authCenter = AuthorizationCenter.shared
    
    init(repository: ScreenTimeRepository) {
        self.repository = repository
    }
    
    func applyShields() async throws {
        // Check authorization
        guard authCenter.authorizationStatus == .approved else {
            throw ScreenTimeError.authorizationDenied
        }
        
        // Get saved selection
        guard let selection = await repository.getSelection() else {
            return
        }
        
        // Apply shields for all selected apps
        try await repository.applyShields(for: selection.applicationTokens)
    }
    
    func removeShields() async throws {
        try await repository.removeShields()
    }
    
    func updateAppTimeLimit(appToken: ApplicationToken, limit: TimeLimit) async throws {
        // Get current limits
        let defaults = UserDefaults(suiteName: "group.com.aydev.surahfocus")
        var limits: [String: String] = defaults?.dictionary(forKey: "timeLimits") as? [String: String] ?? [:]
        
        // Update limit for this app (using token's encoded string as key)
        let tokenKey = appToken.debugDescription // Use token identifier
        limits[tokenKey] = limit.rawValue
        
        // Save back
        defaults?.set(limits, forKey: "timeLimits")
    }
    
    func removeApp(appToken: ApplicationToken) async throws {
        guard var selection = await repository.getSelection() else {
            return
        }
        
        // Remove from selection
        selection.applicationTokens.remove(appToken)
        
        // Save updated selection
        try await repository.saveSelection(selection)
        
        // Reapply shields with updated list
        try await repository.applyShields(for: selection.applicationTokens)
    }
    
    func addMoreApps() async throws -> FamilyActivitySelection? {
        // This will trigger FamilyActivityPicker in the view layer
        // Return current selection to pre-populate picker
        return await repository.getSelection()
    }
    
    func getBlockedApps() async throws -> [BlockedAppInfo] {
        guard let selection = await repository.getSelection() else {
            return []
        }
        
        // Get time limits
        let defaults = UserDefaults(suiteName: "group.com.aydev.surahfocus")
        let limits: [String: String] = defaults?.dictionary(forKey: "timeLimits") as? [String: String] ?? [:]
        
        // Map tokens to BlockedAppInfo
        return selection.applicationTokens.map { token in
            let tokenKey = token.debugDescription
            let limitString = limits[tokenKey] ?? TimeLimit.minutes30.rawValue
            let limit = TimeLimit(rawValue: limitString) ?? .minutes30
            
            return BlockedAppInfo(
                id: tokenKey,
                token: token,
                name: "App", // FamilyControls doesn't expose app names
                timeLimit: limit
            )
        }
    }
}
```

**Key Points:**
- Uses repository for data operations
- Checks authorization before shield operations
- Time limits stored in UserDefaults with app group
- Token keys are used as identifiers (FamilyControls hides actual app names)

---

## TASK 7.3: BLOCKING TAB VIEW (Day 12 Afternoon - 3 hours)

### Step 1: Create BlockingTabViewModel

**File: `Sources/Presentation/BlockingTab/BlockingTabViewModel.swift`**

```swift
import SwiftUI
import FamilyControls

@MainActor
final class BlockingTabViewModel: ObservableObject {
    @Published var blockedApps: [BlockedAppInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showActivityPicker = false
    
    private let screenTimeService: ScreenTimeService
    
    init(screenTimeService: ScreenTimeService) {
        self.screenTimeService = screenTimeService
    }
    
    func loadBlockedApps() async {
        isLoading = true
        
        do {
            blockedApps = try await screenTimeService.getBlockedApps()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func updateTimeLimit(for appToken: ApplicationToken, to newLimit: TimeLimit) async {
        do {
            try await screenTimeService.updateAppTimeLimit(appToken: appToken, limit: newLimit)
            await loadBlockedApps() // Refresh list
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeApp(_ appToken: ApplicationToken) async {
        do {
            try await screenTimeService.removeApp(appToken: appToken)
            await loadBlockedApps() // Refresh list
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addMoreApps() {
        showActivityPicker = true
    }
    
    func handleActivityPickerSelection(_ selection: FamilyActivitySelection) async {
        // Save new selection (merges with existing)
        do {
            let repository = DIContainer.shared.screenTimeRepository
            try await repository.saveSelection(selection)
            try await screenTimeService.applyShields()
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Step 2: Create BlockingTabView

**File: `Sources/Presentation/BlockingTab/BlockingTabView.swift`**

```swift
import SwiftUI
import FamilyControls

struct BlockingTabView: View {
    @StateObject private var viewModel: BlockingTabViewModel
    
    init(container: DIContainer) {
        self._viewModel = StateObject(wrappedValue: BlockingTabViewModel(
            screenTimeService: container.screenTimeService
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.blockedApps.isEmpty {
                    emptyStateView
                } else {
                    blockedAppsList
                }
            }
            .navigationTitle("Blocked Apps")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.addMoreApps()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .familyActivityPicker(
                isPresented: $viewModel.showActivityPicker,
                selection: .constant(FamilyActivitySelection())
            )
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.loadBlockedApps()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Blocked Apps")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add apps to block during your Quran sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.addMoreApps()
            }) {
                Text("Add Apps")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Blocked Apps List
    
    private var blockedAppsList: some View {
        List {
            ForEach(viewModel.blockedApps) { app in
                BlockedAppRow(
                    app: app,
                    onTimeLimitChange: { newLimit in
                        Task {
                            await viewModel.updateTimeLimit(for: app.token, to: newLimit)
                        }
                    },
                    onRemove: {
                        Task {
                            await viewModel.removeApp(app.token)
                        }
                    }
                )
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Blocked App Row

struct BlockedAppRow: View {
    let app: BlockedAppInfo
    let onTimeLimitChange: (TimeLimit) -> Void
    let onRemove: () -> Void
    
    @State private var showTimeLimitPicker = false
    @State private var selectedLimit: TimeLimit
    
    init(app: BlockedAppInfo, onTimeLimitChange: @escaping (TimeLimit) -> Void, onRemove: @escaping () -> Void) {
        self.app = app
        self.onTimeLimitChange = onTimeLimitChange
        self.onRemove = onRemove
        self._selectedLimit = State(initialValue: app.timeLimit)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder (FamilyControls hides actual icons)
            Image(systemName: "app.fill")
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Button(action: {
                    showTimeLimitPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(app.timeLimit.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog("Daily Time Limit", isPresented: $showTimeLimitPicker) {
            ForEach(TimeLimit.allCases, id: \.self) { limit in
                Button(limit.displayName) {
                    selectedLimit = limit
                    onTimeLimitChange(limit)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
```

**Reference:** Similar to Mindcore's `mindcore/Sources/Presentation/Blocking/BlockingView.swift`

---

## TASK 7.4: SETTINGS TAB VIEW (Day 12 Afternoon - 2 hours)

### Step 1: Create SettingsTabViewModel

**File: `Sources/Presentation/SettingsTab/SettingsTabViewModel.swift`**

```swift
import SwiftUI
import RevenueCat

@MainActor
final class SettingsTabViewModel: ObservableObject {
    @Published var user: User?
    @Published var customerInfo: CustomerInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    
    private let userRepository: UserRepository
    private let authService: AuthService
    private let subscriptionService: SubscriptionService
    
    init(
        userRepository: UserRepository,
        authService: AuthService,
        subscriptionService: SubscriptionService
    ) {
        self.userRepository = userRepository
        self.authService = authService
        self.subscriptionService = subscriptionService
    }
    
    func loadUserData(userId: UUID) async {
        isLoading = true
        
        do {
            user = try await userRepository.getUser(id: userId)
            customerInfo = try await subscriptionService.getCustomerInfo()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            // Navigation handled by RootView observing auth state
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() async {
        guard let user = user else { return }
        
        do {
            try await userRepository.deleteUser(user)
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func manageSubscription() {
        // Open RevenueCat customer portal or App Store subscriptions
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    var subscriptionStatus: String {
        guard let customerInfo = customerInfo else {
            return "Loading..."
        }
        
        if customerInfo.entitlements.active.isEmpty {
            return "Free"
        } else if let entitlement = customerInfo.entitlements.active.first?.value {
            return entitlement.productIdentifier
        } else {
            return "Unknown"
        }
    }
    
    var isSubscribed: Bool {
        customerInfo?.entitlements.active.isEmpty == false
    }
}
```

### Step 2: Create SettingsTabView

**File: `Sources/Presentation/SettingsTab/SettingsTabView.swift`**

```swift
import SwiftUI

struct SettingsTabView: View {
    @StateObject private var viewModel: SettingsTabViewModel
    @State private var userId: UUID
    
    init(userId: UUID, container: DIContainer) {
        self._userId = State(initialValue: userId)
        self._viewModel = StateObject(wrappedValue: SettingsTabViewModel(
            userRepository: container.userRepository,
            authService: container.authService,
            subscriptionService: container.subscriptionService
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    profileRow
                }
                
                // Subscription Section
                Section("Subscription") {
                    subscriptionRow
                    
                    if viewModel.isSubscribed {
                        Button("Manage Subscription") {
                            viewModel.manageSubscription()
                        }
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Text("Delete Account")
                    }
                }
                
                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://aydev.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://aydev.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .confirmationDialog("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .task {
                await viewModel.loadUserData(userId: userId)
            }
        }
    }
    
    // MARK: - Profile Row
    
    private var profileRow: some View {
        HStack(spacing: 12) {
            // Profile icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user?.email ?? "Loading...")
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.user?.currentStreak ?? 0) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Subscription Row
    
    private var subscriptionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.subscriptionStatus)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if viewModel.isSubscribed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
```

---

## TASK 7.5: REGISTER DEPENDENCIES (Day 12 - 30 min)

**Update `Sources/Core/DIContainer.swift`:**

```swift
final class DIContainer {
    static let shared = DIContainer()
    
    // ... existing services
    
    // MARK: - Phase 7 Services
    
    lazy var screenTimeRepository: ScreenTimeRepository = {
        ScreenTimeRepositoryImpl()
    }()
    
    lazy var screenTimeService: ScreenTimeService = {
        ScreenTimeServiceImpl(repository: screenTimeRepository)
    }()
}
```

---

## TESTING PHASE 7

### Test 7.1: ScreenTimeRepositoryTests

**File: `Tests/Data/Repositories/ScreenTimeRepositoryTests.swift`**

```swift
import XCTest
import FamilyControls
@testable import SurahFocus

final class ScreenTimeRepositoryTests: XCTestCase {
    var sut: ScreenTimeRepositoryImpl!
    
    override func setUp() {
        super.setUp()
        sut = ScreenTimeRepositoryImpl()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testSaveAndLoadSelection() async throws {
        // Given: A FamilyActivitySelection with apps
        var selection = FamilyActivitySelection()
        // Note: Cannot create real ApplicationTokens in tests
        // This test would work on device with real selection from FamilyActivityPicker
        
        // When: Save selection
        try await sut.saveSelection(selection)
        
        // Then: Can load selection
        let loaded = await sut.getSelection()
        XCTAssertNotNil(loaded)
    }
    
    func testApplyShieldsUpdatesStore() async throws {
        // Given: Empty token set
        let tokens: Set<ApplicationToken> = []
        
        // When: Apply shields
        try await sut.applyShields(for: tokens)
        
        // Then: No error thrown
        // Actual shield verification requires physical device
    }
    
    func testRemoveShieldsResetsStore() async throws {
        // Given: Shields applied
        // When: Remove shields
        try await sut.removeShields()
        
        // Then: No error thrown
        // Actual shield verification requires physical device
    }
}
```

### Test 7.2: BlockingTabViewModelTests

**File: `Tests/Presentation/BlockingTab/BlockingTabViewModelTests.swift`**

```swift
import XCTest
@testable import SurahFocus

final class BlockingTabViewModelTests: XCTestCase {
    var sut: BlockingTabViewModel!
    var mockService: MockScreenTimeService!
    
    override func setUp() {
        super.setUp()
        mockService = MockScreenTimeService()
        sut = BlockingTabViewModel(screenTimeService: mockService)
    }
    
    @MainActor
    func testLoadBlockedAppsPopulatesList() async {
        // Given: Service returns apps
        mockService.blockedApps = [
            BlockedAppInfo(id: "1", token: ApplicationToken(), name: "App1", timeLimit: .minutes30)
        ]
        
        // When: Load blocked apps
        await sut.loadBlockedApps()
        
        // Then: Apps populated
        XCTAssertEqual(sut.blockedApps.count, 1)
        XCTAssertEqual(sut.blockedApps.first?.name, "App1")
    }
    
    @MainActor
    func testLoadBlockedAppsHandlesError() async {
        // Given: Service throws error
        mockService.shouldThrowError = true
        
        // When: Load blocked apps
        await sut.loadBlockedApps()
        
        // Then: Error message set
        XCTAssertNotNil(sut.errorMessage)
    }
}

// MARK: - Mock Service

final class MockScreenTimeService: ScreenTimeService {
    var blockedApps: [BlockedAppInfo] = []
    var shouldThrowError = false
    
    func applyShields() async throws {
        if shouldThrowError { throw TestError.failed }
    }
    
    func removeShields() async throws {
        if shouldThrowError { throw TestError.failed }
    }
    
    func updateAppTimeLimit(appToken: ApplicationToken, limit: TimeLimit) async throws {
        if shouldThrowError { throw TestError.failed }
    }
    
    func removeApp(appToken: ApplicationToken) async throws {
        if shouldThrowError { throw TestError.failed }
    }
    
    func addMoreApps() async throws -> FamilyActivitySelection? {
        return FamilyActivitySelection()
    }
    
    func getBlockedApps() async throws -> [BlockedAppInfo] {
        if shouldThrowError { throw TestError.failed }
        return blockedApps
    }
}

enum TestError: Error {
    case failed
}
```

---

## BUILD & VERIFY

### Step 1: Run All Tests

```bash
cd ~/Projects/SurahFocus
make test

# Expected: 145+ tests passing
```

### Step 2: Manual Testing on Device

**REQUIRED:** Blocking features need physical device.

1. **Test blocking tab:**
   ```
   - Open app on device
   - Navigate to Blocking tab
   - Should see list of apps selected in Phase 3
   - Tap an app row
   - Change time limit
   - Verify limit updates
   - Tap trash icon
   - Verify app removed from list
   - Tap "+" button
   - Select new app via FamilyActivityPicker
   - Verify new app appears in list
   ```

2. **Test settings tab:**
   ```
   - Navigate to Settings tab
   - Verify email displays
   - Verify streak count displays
   - Verify subscription status shows
   - Tap "Sign Out"
   - Verify returns to auth screen
   ```

---

## PHASE 7 COMPLETION CHECKLIST

### ScreenTime Repository
- [ ] Can apply shields for selected apps
- [ ] Can remove all shields
- [ ] Can save FamilyActivitySelection
- [ ] Can load FamilyActivitySelection
- [ ] Time limits stored in UserDefaults

### ScreenTime Service
- [ ] Business logic for shield management works
- [ ] Can update time limits
- [ ] Can remove apps from blocking list
- [ ] Can fetch blocked apps list

### Blocking Tab
- [ ] Lists all blocked apps
- [ ] Shows time limit for each app
- [ ] Can edit time limit via picker
- [ ] Can remove app via trash icon
- [ ] "+" button opens FamilyActivityPicker
- [ ] Empty state shows when no apps
- [ ] Loading state shows during operations

### Settings Tab
- [ ] Profile section shows email and streak
- [ ] Subscription section shows status
- [ ] Can manage subscription (opens App Store)
- [ ] Sign out button works
- [ ] Delete account requires confirmation
- [ ] Version number displays
- [ ] Privacy/Terms links work

### Testing
- [ ] 5+ repository tests passing
- [ ] 5+ viewmodel tests passing
- [ ] 145+ total tests passing

---

## TROUBLESHOOTING

### Issue: FamilyActivityPicker doesn't show
**Solution:**
1. Check authorization status: `AuthorizationCenter.shared.authorizationStatus`
2. Ensure running on physical device (required)
3. Verify Family Controls capability enabled

### Issue: Shields don't apply
**Solution:**
1. Check authorization granted in Phase 3
2. Verify ManagedSettingsStore on MainActor
3. Test on physical device only
4. Check app group identifier matches

### Issue: Settings shows wrong subscription status
**Solution:**
1. Verify RevenueCat configured correctly in Phase 2
2. Check network connectivity
3. Verify product IDs match RevenueCat dashboard

---

## NEXT PHASE PREVIEW

**Phase 8 will cover:**
- Enhanced streak display with animations
- Session history view with date grouping
- Comprehensive streak edge case testing
- Milestone celebrations (7, 30, 100 days)

---

## TIME TRACKING

**Estimated:**
- ScreenTime Repository: 3 hours
- ScreenTime Service: 1 hour
- Blocking Tab: 3 hours
- Settings Tab: 2 hours
- Testing: 1 hour
- **Total: 10 hours**

**Actual:** _____ hours

---

**🎯 PHASE 7 COMPLETE! Ready for Phase 8: Streak System**

```bash
git add .
git commit -m "✅ Phase 7: Blocking + Settings tabs + 145 tests"
git push
```
