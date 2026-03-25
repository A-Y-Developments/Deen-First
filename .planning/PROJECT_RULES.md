# PROJECT RULES - iOS Swift MVVM Clean Architecture
# Deen First

## FOLDER STRUCTURE

```
deenfirst/Sources/
├── Core/
│   ├── DataDependency/DIContainer.swift
│   ├── Networking/
│   │   ├── HTTPClient.swift
│   │   └── NetworkLoggingInterceptor.swift
│   └── SceneNavigation/Router.swift
├── Domain/
│   ├── Entities/
│   │   └── {entity}.swift (snake_case)
│   └── Services/
│       └── {Name}Service.swift
├── Data/
│   ├── DataSource/
│   │   ├── API/
│   │   │   ├── AlQuranAPIDataSource.swift
│   │   │   ├── AlQuranAPIDTOs.swift
│   │   │   ├── QuranAPIDataSource.swift
│   │   │   └── QuranAPIDTOs.swift
│   │   └── LocalDataSource.swift
│   └── Repositories/
│       └── {Name}Repository.swift
├── Presentation/
│   ├── Components/
│   │   └── {ComponentName}.swift
│   ├── Auth/
│   │   ├── AuthView.swift
│   │   └── AuthViewModel.swift
│   ├── Paywall/
│   │   ├── PaywallView.swift
│   │   └── PaywallViewModel.swift
│   ├── Survey/
│   │   ├── SurveyView.swift
│   │   ├── SurveyViewModel.swift
│   │   ├── SurveyStep1View.swift
│   │   ├── SurveyStep2View.swift
│   │   ├── SurveyStep3View.swift
│   │   └── SurveyStep4View.swift
│   ├── Summary/
│   │   ├── Summary1View.swift
│   │   ├── Summary2View.swift
│   │   ├── Summary3View.swift
│   │   ├── SummaryViewModel.swift
│   │   ├── CalculateSurveyView.swift
│   │   ├── FinalSummaryView.swift
│   │   ├── HowAppWork1View.swift
│   │   ├── HowAppWork2View.swift
│   │   └── HowAppWork3View.swift
│   ├── Setup/
│   │   ├── PermissionView.swift
│   │   ├── PermissionSetupViewModel.swift
│   │   ├── AppToBlock.swift
│   │   ├── AppToBlockStep1View.swift
│   │   ├── AppToBlockStep2View.swift
│   │   ├── AppToBlockStep3View.swift
│   │   ├── StarterPageView.swift
│   │   ├── SetupViewModel.swift
│   │   └── SetupSummary.swift
│   ├── MainTabs/
│   │   ├── MainTabView.swift
│   │   ├── HomeTab/
│   │   │   ├── HomeTabView.swift
│   │   │   └── HomeTabViewModel.swift
│   │   ├── QuranTab/
│   │   │   ├── QuranTabView.swift
│   │   │   ├── QuranTabViewModel.swift
│   │   │   ├── SelectSurahView.swift
│   │   │   ├── SelectSurahViewModel.swift
│   │   │   ├── AyahRangeSelectionView.swift
│   │   │   ├── AyahRangeSelectionViewModel.swift
│   │   │   ├── FocusSectionView.swift
│   │   │   ├── FocusSectionViewModel.swift
│   │   │   ├── ActiveSessionView.swift
│   │   │   ├── ActiveSessionViewModel.swift
│   │   │   └── SessionFinishView.swift
│   │   ├── BlockingTab/
│   │   │   ├── BlockingTabView.swift
│   │   │   ├── BlockingTabViewModel.swift
│   │   │   ├── AppLimitView.swift
│   │   │   ├── AppLimitViewModel.swift
│   │   │   ├── TimeLimitView.swift
│   │   │   └── TimeLimitViewModel.swift
│   │   └── SettingsTab/
│   │       ├── SettingsTabView.swift
│   │       ├── SettingsTabViewModel.swift
│   │       ├── PreferencesView.swift
│   │       ├── PreferencesViewModel.swift
│   │       ├── SubscriptionView.swift
│   │       ├── SubscriptionViewModel.swift
│   │       ├── SubscriptionPlansView.swift
│   │       ├── SupportView.swift
│   │       ├── SupportViewModel.swift
│   │       ├── ReciterSelectionSheet.swift
│   │       ├── TranslationSelectionSheet.swift
│   │       └── EmergencyUnblock/
│   │           ├── EmergencyUnblockView.swift
│   │           └── EmergencyUnblockViewModel.swift
│   ├── ReciteToUnblock/
│   │   ├── ReciteToUnblockView.swift
│   │   ├── ReciteToUnblockViewModel.swift
│   │   ├── ReciteAlertView.swift
│   │   └── UnblockDurationSheet.swift
│   ├── QuranReading/
│   │   ├── QuranReadingView.swift
│   │   └── QuranReadingViewModel.swift
│   ├── FocusSession/
│   │   ├── StartView.swift
│   │   ├── SelectSurahFocusView.swift
│   │   ├── SetupView.swift
│   │   └── EndView.swift
│   └── Components/
│       ├── (shared reusable components)
│       ├── BlockingTabComps/
│       ├── HomeTabComps/
│       ├── FocusSessionComps/
│       └── SettingsTabComps/
├── Shared/
│   ├── AppGroupConstants.swift
│   ├── DayHelper.swift
│   └── ScreenTimeEvents.swift
├── Utils/
│   ├── AppConstants.swift
│   ├── Color+Extension.swift
│   ├── Date+Extension.swift
│   ├── DeviceActivityScheduleHelper.swift
│   ├── KeychainHelper.swift
│   ├── TimeLimitHelper.swift
│   └── UserPersistenceHelper.swift
├── RootView.swift
└── DeenFirstApp.swift
```

---

## ARCHITECTURE: CLEAN ARCH + MVVM

```
Presentation (View + ViewModel)
    ↓
Domain (Service + Entity)
    ↓
Data (Repository + DataSource)
```

---

## NAMING CONVENTIONS

### Files
- Views: `PascalCase` → `HomeTabView.swift`
- ViewModels: `PascalCase` → `HomeTabViewModel.swift`
- Entities: `snake_case` → `user.swift`, `session.swift`
- Services: `PascalCase` → `QuranService.swift`
- Repositories: `PascalCase` → `QuranRepository.swift`
- Components: `PascalCase` → `PrimaryButton.swift`
- Utils: `PascalCase` → `Date+Extension.swift`

### Classes/Structs
- Views: `{Name}View` → `struct HomeTabView: View`
- ViewModels: `{Name}Viewmodel` → `final class HomeTabViewModel: ObservableObject`
- Services Protocol: `{Name}Service` → `protocol QuranService`
- Services Impl: `{Name}ServiceImpl` → `class QuranServiceImpl: QuranService`
- Repositories: same pattern as services
- Entities: `PascalCase` class/struct, `snake_case` file name

### Variables/Properties
- camelCase: `var searchText: String = ""`
- Booleans: `is/has` prefix → `isLoading`, `hasCompletedOnboarding`
- Private: `private let service: QuranService`
- Published: `@Published var surahs: [Surah] = []`

---

## VIEW PATTERN

```swift
struct HomeTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var vm: HomeTabViewModel

    var body: some View {
        VStack {
            // UI only, no business logic
        }
        .onAppear {
            vm.load()
        }
    }
}
```

**Rules:**
- `struct` + `View` protocol
- `@EnvironmentObject var router: Router` for navigation
- `@EnvironmentObject var vm: {Name}Viewmodel` for state
- `@State` for local UI state only
- Call `vm.load()` in `.onAppear`
- No business logic in views

---

## VIEWMODEL PATTERN

```swift
@MainActor
final class HomeTabViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = true
    @Published var activeBlocks: [ScreenTimeRule] = []

    private let userRepo: UserRepository
    private let screenTimeService: ScreenTimeRulesService

    init() {
        self.userRepo = DIContainer.shared.userRepository
        self.screenTimeService = DIContainer.shared.screenTimeRulesService
    }

    func load() {
        Task {
            do {
                isLoading = true
                user = try userRepo.getCurrentUser()
                activeBlocks = try screenTimeService.getActiveRules()
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
}
```

**Rules:**
- `@MainActor` decorator ALWAYS
- `final class {Name}Viewmodel: ObservableObject`
- Inject deps via `DIContainer.shared` in `init()`
- `@Published var` for reactive state
- Wrap async in `Task { }`
- Set `isLoading = true` before, `false` after
- Use `do/catch` for errors
- No UI code in ViewModel

---

## SERVICE PATTERN

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
}
```

**Rules:**
- Protocol first: `protocol {Name}Service`
- Implementation: `class {Name}ServiceImpl: {Name}Service`
- Inject repositories in `init()`
- Business logic layer only
- Use `async throws` for async methods

---

## REPOSITORY PATTERN

```swift
protocol QuranRepository {
    func getAllSurahs() async throws -> [Surah]
    func getSurahById(id: Int, translation: String) async throws -> Surah
}

class QuranRepositoryImpl: QuranRepository {
    private let apiDataSource: QuranAPIDataSource
    private let localDataSource: LocalDataSource

    init(apiDataSource: QuranAPIDataSource, localDataSource: LocalDataSource) {
        self.apiDataSource = apiDataSource
        self.localDataSource = localDataSource
    }
}
```

**Rules:**
- Protocol first: `protocol {Name}Repository`
- Implementation: `class {Name}RepositoryImpl: {Name}Repository`
- Data access layer only (no business logic)
- Inject DataSources in `init()`
- `async throws` for async operations

---

## DEPENDENCY INJECTION

```swift
final class DIContainer {
    static let shared: DIContainer = { ... }()

    // Registration order: DataSource → Repository → Service
    lazy var localDataSource: LocalDataSource = ...
    lazy var quranRepository: QuranRepository = QuranRepositoryImpl(...)
    lazy var quranService: QuranService = QuranServiceImpl(repo: quranRepository)
    // ... etc
}
```

**Rules:**
- Singleton: `static let shared`
- `lazy var` for all dependencies
- Register: DataSources → Repositories → Services
- Inject protocol types, not implementations
- ViewModels get deps via `DIContainer.shared.{service}`

---

## NAVIGATION PATTERN

```swift
class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Route: Hashable {
        case auth
        case mainTabs
        case quranReading(surahId: Int)
        case reciteToUnlock
        case emergencyUnblock
        // ... all routes
    }

    func navigate(to route: Route) { navigationPath.append(route) }
    func navigateBack() { if !navigationPath.isEmpty { navigationPath.removeLast() } }
    func replaceWith(_ routes: [Route]) { navigationPath = NavigationPath(); routes.forEach { navigationPath.append($0) } }
    func reset() { navigationPath = NavigationPath() }
}
```

**Rules:**
- Single `Router` class with `NavigationPath`
- `enum Route: Hashable` for type-safe routes
- Associated values for parameters
- Inject as `@EnvironmentObject var router: Router`
- Navigate: `router.navigate(to: .quranReading(surahId: 1))`
- Back: `router.navigateBack()`

---

## ROOT VIEW PATTERN

All ViewModels created as `@StateObject` in RootView and injected as environment objects. This makes ViewModels persistent across navigation and avoids recreation.

```swift
struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var homeTabVM = HomeTabViewModel()
    @StateObject private var quranTabVM = QuranTabViewModel()
    // ... all 23 ViewModels

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            // Initial view based on state check
        }
        .environmentObject(router)
        .environmentObject(homeTabVM)
        .environmentObject(quranTabVM)
        // ... inject all VMs
    }
}
```

---

## COMPONENTS PATTERN

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            // UI
        }
        .disabled(isDisabled || isLoading)
    }
}
```

**Rules:**
- Stateless or minimal `@State` only
- Accept closures: `let action: () -> Void`
- Default values for optional params
- Located in `Presentation/Components/`
- Tab-specific components in `Components/{Tab}Comps/`
- Reusable across features

---

## ASYNC/AWAIT PATTERN

```swift
func load() {
    Task {
        do {
            isLoading = true
            data = try await service.getData()
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
}
```

**Rules:**
- Wrap async work in `Task { }`
- `do/catch` for error handling
- Set loading state before/after
- Use `async throws` for service/repo methods
- `@MainActor` on ViewModels ensures main thread

---

## ENTITY PATTERN

```swift
// SwiftData Model (local persistence)
@Model
class User {
    @Attribute(.unique) var id: String
    var name: String
    var isPremium: Bool
    init(id: String, name: String) { ... }
}

// Codable struct (API response / App Groups)
struct ScreenTimeRule: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: RuleType
}

// Enum
enum RuleType: String, Codable {
    case timeLimit
    case timeLimit
    case allDay
}
```

**Rules:**
- `@Model` for SwiftData entities
- `Codable` structs for App Groups / API data
- `snake_case` file names: `user.swift`, `session.swift`
- `PascalCase` class/struct names: `User`, `Session`
- Enums with `RawValue` for serialization

---

## DATA SOURCE PATTERN

```swift
final class LocalDataSource {
    let container: ModelContainer
    let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func getCurrentUser() throws -> User? {
        let descriptor = FetchDescriptor<User>()
        return try context.fetch(descriptor).first
    }

    func save(_ user: User) throws {
        context.insert(user)
        try context.save()
    }
}
```

**Rules:**
- Single `LocalDataSource` class
- Wraps all SwiftData operations
- Use `FetchDescriptor` for queries
- Manual `context.save()` after mutations
- Throw errors, don't catch internally

---

## SHARED / APP GROUPS

Files in `Shared/` are accessible to both the main app and extensions:
- `AppGroupConstants.swift` — shared UserDefaults suite name, key constants
- `DayHelper.swift` — day name utilities for scheduling
- `ScreenTimeEvents.swift` — event creation utilities for DeviceActivity

**App Group**: `group.com.aydev.deenfirst`

```swift
let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
```

---

## SCREEN TIME EXTENSION PATTERN

Two separate extension targets required:

**DeviceActivityMonitor** (`com.aydev.deenfirst.ScreenTimeMonitor`):
- Subclass of `DeviceActivityMonitor`
- Implements `intervalDidStart`, `intervalDidEnd`, `eventDidReachThreshold`
- Reads token mappings from shared UserDefaults
- Applies shields via `ManagedSettingsStore`

**ShieldConfiguration** (`com.aydev.deenfirst.Shield`):
- Subclass of `ShieldConfigurationDataSource`
- Implements `configuration(shielding:)` variants
- Returns branded `ShieldConfiguration` (Deen First title, branding color)

Both targets must:
- Share app group `group.com.aydev.deenfirst`
- Have `com.apple.developer.family-controls` entitlement (monitor extension only)

---

## STATE MANAGEMENT

```
View reads @Published
    ↓
ViewModel (ObservableObject, @MainActor)
    ↓
Service (business logic, stateless functions)
    ↓
Repository (data access, stateless functions)
    ↓
DataSource (persistence)
```

---

## THREADING

- `@MainActor` on all ViewModels — UI updates automatic on main thread
- Background network/DB work runs in `Task { }` (actor-isolated to main since ViewModel is @MainActor)
- Services and Repositories: no actor annotation — called from ViewModel's Task context

---

## CODE STYLE

- No force unwraps (`!`) — use optional binding or `guard`
- `guard` for early returns, `if let` for simple checks
- Explicit types: `var name: String = ""`
- 4-space indent (Xcode default)
- Opening brace same line: `func foo() {`
- Blank line between methods
- Minimal comments — code should be self-documenting
- Only comment complex algorithms (e.g., recitation similarity scoring)

---

## CHECKLIST FOR NEW FEATURES

1. Create Entity in `Domain/Entities/` if needed
2. Create Repository protocol + impl in `Data/Repositories/`
3. Add repo to `DIContainer`
4. Create Service protocol + impl in `Domain/Services/`
5. Add service to `DIContainer`
6. Create ViewModel in `Presentation/{Feature}/`
7. Inject service via `DIContainer.shared`
8. Create View in `Presentation/{Feature}/`
9. Add route to `Router.Route` enum
10. Add destination in `RootView` navigation destinations
11. Create `@StateObject` for ViewModel in `RootView`
12. Inject ViewModel via `.environmentObject()`
13. Add reusable components to `Presentation/Components/` if needed

---

## QUICK REFERENCE

| Layer | Protocol | Implementation | DI Access |
|-------|----------|----------------|-----------|
| Service | `protocol XService` | `class XServiceImpl: XService` | `DIContainer.shared.xService` |
| Repository | `protocol XRepository` | `class XRepositoryImpl: XRepository` | `DIContainer.shared.xRepository` |
| ViewModel | — | `@MainActor final class XViewmodel: ObservableObject` | Created as `@StateObject` in RootView |
| View | — | `struct XView: View` | Injected via `@EnvironmentObject` |
| Entity | — | `@Model class X` or `struct X: Codable` | — |

---

## BUILD SYSTEM

See `PROJECT_SETUP.md` for Tuist configuration, Makefile, and environment setup.

```bash
# Verify build
xcodebuild -workspace deenfirst.xcworkspace \
  -scheme deenfirst \
  -destination 'generic/platform=iOS Simulator' \
  build 2>&1 | grep -E "(BUILD|error:)" | tail -10
```

Build once at end of work session to verify. Fix all errors at once.

---

## PLANNING DOCUMENTS REFERENCE

- `DEEN_FIRST_PRD.md` — feature requirements & user stories (no code)
- `DEEN_FIRST_SYSTEM_DESIGN.md` — architecture, flows, data models
- `PROJECT_RULES.md` — code patterns & conventions (this file)
- `PROJECT_SETUP.md` — build system & Tuist config
- `SCREEN_TIME_API_GUIDE.md` — Screen Time API reference implementation
- `REVENUECAT_SETUP.md` — RevenueCat setup & configuration

---

**Summary:** Clean Architecture + MVVM + Protocol-Oriented + Dependency Injection + SwiftUI reactive patterns.
