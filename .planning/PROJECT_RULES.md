# PROJECT RULES - iOS Swift MVVM Clean Architecture

## FOLDER STRUCTURE

```
SurahFocus/Sources/
├── Core/
│   ├── DataDepency/DIContainer.swift
│   ├── ImageCaching/
│   ├── Networking/
│   └── SceneNavigation/Router.swift
├── Data/
│   ├── DataSource/LocalDataSource.swift
│   └── Repositories/
│       └── {Name}Repository.swift
├── Domain/
│   ├── Entities/
│   │   └── {entity}.swift (snake_case)
│   └── Services/
│       └── {Name}Service.swift
├── Presentation/
│   ├── Components/
│   │   └── {ComponentName}.swift
│   └── {FeatureName}View/
│       ├── {FeatureName}View.swift
│       └── {FeatureName}Viewmodel.swift
├── Utils/
│   ├── Extensions.swift
│   └── ScreenTime/
│       └── {ScreenTimeHelper}.swift
├── RootView.swift
└── SurahFocusApp.swift
```

## ARCHITECTURE: CLEAN ARCH + MVVM

```
Presentation (View + ViewModel)
    ↓
Domain (Service + Entity)
    ↓
Data (Repository + DataSource)
```

## NAMING CONVENTIONS

### Files
- Views: `PascalCase` → `CameraView.swift`
- ViewModels: `PascalCase` → `CameraViewmodel.swift`
- Entities: `snake_case` → `shade.swift`, `skin_tone.swift`
- Services: `PascalCase` → `ProductService.swift`
- Repositories: `PascalCase` → `ProductRepository.swift`
- Components: `PascalCase` → `CustomButton.swift`
- Utils: `PascalCase` → `Extensions.swift`, `ScreenTimeHelper.swift`

### Classes/Structs
- Views: `{Name}View` → `struct CameraView: View`
- ViewModels: `{Name}Viewmodel` → `class CameraViewmodel: ObservableObject`
- Services Protocol: `{Name}Service` → `protocol ProductService`
- Services Impl: `{Name}ServiceImpl` → `class ProductServiceImpl: ProductService`
- Repositories: Same pattern as services
- Entities: `PascalCase` → `struct Shade`, `class SkinTone`
- Components: Descriptive → `CustomButton`, `BackButton`

### Variables/Properties
- camelCase: `var searchText: String = ""`
- Booleans: `is/has` prefix → `isLoading`, `hasError`
- Private: `private let` → `private let repo: ProductRepository`
- Published: `@Published var brands: [Brand] = []`

### Functions
- camelCase: `func load()`, `func getBrands()`
- Async: `async` suffix in context → `async func calculateMatches() throws`
- Private helpers: `private func startAnalysis()`

## VIEW PATTERN

```swift
struct ChooseBrandView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var vm: ChooseBrandViewModel
    @State private var isSearchFocused: Bool = false

    var body: some View {
        VStack {
            // UI
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
- `@EnvironmentObject var vm: {Name}ViewModel` for state
- `@State` for local UI state only
- Call `vm.load()` in `.onAppear`
- No business logic in views

## VIEWMODEL PATTERN

```swift
@MainActor
final class ChooseBrandViewModel: ObservableObject {
    @Published var productService: ProductService
    @Published var searchText: String = ""
    @Published var isLoading: Bool = true
    @Published var brands: [Brand] = []
    @Published var selectedBrands: Set<Brand> = []

    init() {
        productService = DIContainer.shared.productService
    }

    func load() {
        Task {
            do {
                isLoading = true
                brands = try await productService.getBrands()
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
- Use `do/catch` with print for errors
- No UI code in viewmodel

## SERVICE PATTERN

```swift
protocol ProductService {
    func getBrands() async throws -> [Brand]
    func calculateMatches() async throws
}

class ProductServiceImpl: ProductService {
    private let repo: ProductRepository
    private let skinAnalysisRepo: SkinAnalysisRepository

    init(repo: ProductRepository, skinAnalysisRepo: SkinAnalysisRepository) {
        self.repo = repo
        self.skinAnalysisRepo = skinAnalysisRepo
    }

    func getBrands() async throws -> [Brand] {
        return try await repo.getBrands()
    }

    func calculateMatches() async throws {
        // business logic
        let recommendations = try await repo.getRecommendations()
        // process...
    }
}
```

**Rules:**
- Protocol first: `protocol {Name}Service`
- Implementation: `class {Name}ServiceImpl: {Name}Service`
- Inject repos in `init()`
- Business logic layer (wraps repos)
- Use `async throws` for async methods
- Return types explicit

## REPOSITORY PATTERN

```swift
protocol ProductRepository {
    func insertAllBrand(_ brands: [Brand]) async throws
    func getBrands() async throws -> [Brand]
}

class ProductRepositoryImpl: ProductRepository {
    private let ds: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.ds = localDataSource
    }

    func getBrands() async throws -> [Brand] {
        return try ds.getBrandsCatalog()
    }
}
```

**Rules:**
- Protocol first: `protocol {Name}Repository`
- Implementation: `class {Name}RepositoryImpl: {Name}Repository`
- Inject `LocalDataSource` in init
- Data access layer only
- Delegate to DataSource methods
- `async throws` for async operations

## DEPENDENCY INJECTION

```swift
final class DIContainer {
    private let modelContainer: ModelContainer

    lazy var localDataSource: LocalDataSource =
        LocalDataSource(container: modelContainer)

    lazy var productRepository: ProductRepository =
        ProductRepositoryImpl(localDataSource: localDataSource)

    lazy var productService: ProductService =
        ProductServiceImpl(repo: productRepository, skinAnalysisRepo: skinAnalysisRepository)

    static let shared: DIContainer = {
        let container = try? ModelContainer(for: AppData.self)
        return DIContainer(modelContainer: container ?? inMemoryContainer)
    }()

    private init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
}
```

**Rules:**
- Singleton: `static let shared`
- `lazy var` for all dependencies
- Register: DataSource → Repositories → Services
- Inject protocol types, not implementations
- ViewModels get deps via `DIContainer.shared.{service}`

## NAVIGATION PATTERN

```swift
class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Route: Hashable {
        case onboarding
        case brandPreference(isEdit: Bool)
        case detailShade(shadeRecommendation: ShadeRecommendation)
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

**RootView:**
```swift
NavigationStack(path: $router.navigationPath) {
    SplashView()
        .navigationDestination(for: Router.Route.self) { route in
            destinationView(for: route)
        }
}
.environmentObject(router)

@ViewBuilder
private func destinationView(for route: Router.Route) -> some View {
    switch route {
    case .onboarding:
        OnboardingView()
    case .brandPreference(let isEdit):
        ChooseBrandView(isEdit: isEdit)
    }
}
```

**Rules:**
- Single `Router` class with `NavigationPath`
- `enum Route: Hashable` for type-safe routes
- Associated values for params
- Inject as `@EnvironmentObject var router: Router`
- Navigate: `router.navigate(to: .detailShade(shade))`
- Back: `router.navigateBack()`

## COMPONENTS PATTERN

```swift
struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isDense: Bool = false
    var isFilled: Bool = true
    var variant: ButtonVariant = .active

    enum ButtonVariant {
        case active, disabled
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isDense ? 14 : 16, design: .monospaced))
        }
        .disabled(variant == .disabled)
    }
}
```

**Rules:**
- Stateless or minimal state
- Accept closures: `let action: () -> Void`
- Default values for optional params
- Located in `Presentation/Components/`
- Reusable across features

## STATE MANAGEMENT

**Data Flow:**
```
View reads @Published
    ↓
ViewModel (ObservableObject)
    ↓
Service (business logic)
    ↓
Repository (data access)
    ↓
DataSource (persistence)
```

**Rules:**
- View: `@State` for local UI, `@EnvironmentObject` for ViewModel
- ViewModel: `@Published var` for reactive properties
- ViewModel: `@MainActor` for thread safety
- Service/Repo: No state, stateless functions
- Async: wrap in `Task { }`

## ASYNC/AWAIT PATTERN

```swift
func load() {
    Task {
        do {
            isLoading = true
            brands = try await productService.getBrands()
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

## ERROR HANDLING

```swift
// In ViewModels:
do {
    try await service.doSomething()
} catch {
    print("Error: \(error)")
}

// In Services/Repos:
func getBrands() async throws -> [Brand] {
    return try await repo.getBrands()
}
```

**Rules:**
- Use `throws` for service/repo methods
- `try/catch` in ViewModels
- Print errors: `print("Error: \(error)")`
- Silent failures: `catch {}` where appropriate
- No alert/toast error handling (just logging)

## ENTITY PATTERN

```swift
// SwiftData Model
@Model
class SkinTone {
    var hex: String
    var skinToneTimestamp: Date

    init(hex: String) {
        self.hex = hex
        self.skinToneTimestamp = Date()
    }
}

// Enum
enum Undertone: String, Codable {
    case warm = "warm"
    case cool = "cool"
    case neutral = "neutral"
}

// Typealias
typealias Brand = String
```

**Rules:**
- Use `@Model` for SwiftData persistence
- snake_case file names: `skin_tone.swift`
- PascalCase class/struct names: `SkinTone`
- Enums with raw values for serialization
- Simple types can be typealias

## DATA SOURCE PATTERN

```swift
final class LocalDataSource {
    let container: ModelContainer
    let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func getBrandsCatalog() throws -> [Brand] {
        let appData = try getOrCreateAppData()
        return appData.selectedBrands
    }

    func updateAppData(_ apply: (AppData) -> Void) throws {
        let appData = try getOrCreateAppData()
        apply(appData)
        try context.save()
    }
}
```

**Rules:**
- Single `LocalDataSource` class
- Wrap SwiftData operations
- Use FetchDescriptor for queries
- Manual `context.save()` after mutations
- Throw errors, don't catch

## UTILS PATTERN

**Utils** (`/Utils/`): Extensions and utilities
- `Extensions.swift` - Generic extensions (Color(hex:), Array safe subscript, Date helpers)
- `/ScreenTime/` - Screen Time specific utilities (when needed for FamilyControls)
  - `ScreenTimeHelper.swift` - Shield configuration helpers
  - `TimeLimit.swift` - Time limit enums
  - `ScreenTimeEvents.swift` - Event creation utilities

**Rules:**
- Utils: generic extensions and specific utilities
- Screen Time helpers go in Utils/ScreenTime/ subfolder
- No business logic in utils (use Services instead)
- Pure functions preferred

## EXTENSION PATTERN

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

**Rules:**
- Put all extensions in `Utils/Extensions.swift`
- Generic helpers only (no feature-specific)
- Use `extension {Type} { }`
- Add convenience inits/computed props

## PROPERTY DEFINITION STYLE

```swift
// Published state
@Published var searchText: String = ""
@Published var brands: [Brand] = []

// Private constants
private let service: ProductService

// Computed properties
var filteredBrands: [Brand] {
    brands.filter { $0.contains(searchText) }
}

// State with default
@State private var isLoading: Bool = false
```

**Rules:**
- Explicit types: `var name: Type = value`
- `@Published` for reactive ViewModel state
- `@State private` for local View state
- No implicit types unless obvious

## FUNCTION DEFINITION STYLE

```swift
// Simple sync
func load() {
    // Task wrapper
}

// Async throws
async func getBrands() throws -> [Brand] {
    return try await repo.getBrands()
}

// Private helper
private func startAnalysis() {
    // logic
}

// With closure param
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // async work
}
```

**Rules:**
- camelCase names
- Explicit return types for public methods
- `private` for internal helpers
- `async throws` for async that can fail
- `@MainActor` when needed for UI updates

## SWIFTUI STYLE

```swift
var body: some View {
    VStack(spacing: 16) {
        Text("Title")
            .font(.system(size: 20, weight: .bold, design: .monospaced))

        Button(action: { vm.load() }) {
            Text("Load")
        }
    }
    .padding(.horizontal, 16)
    .onAppear {
        vm.load()
    }
}
```

**Rules:**
- Use `.font(.system(..., design: .monospaced))` for consistency
- Spacing: 8pt, 16pt standard
- Padding: `.padding(.horizontal, 16)`
- Call VM methods in `.onAppear`
- Closure actions: `action: { vm.methodName() }`

## ROOT VIEW PATTERN

```swift
struct RootView: View {
    @StateObject private var router = Router()
    @StateObject private var cameraVM = CameraViewmodel()
    @StateObject private var chooseBrandVM = ChooseBrandViewModel()

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            SplashView()
                .navigationDestination(for: Router.Route.self) { route in
                    destinationView(for: route)
                }
        }
        .environmentObject(router)
        .environmentObject(cameraVM)
        .environmentObject(chooseBrandVM)
    }
}
```

**Rules:**
- Create all ViewModels as `@StateObject`
- Single Router instance
- Inject via `.environmentObject()`
- Use `NavigationStack` with path binding

## LIFECYCLE PATTERN

**App Entry:**
```swift
@main
struct SurahFocusApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

**View Lifecycle:**
```swift
.onAppear {
    vm.load()  // fetch data
}

.task {
    await vm.initialize()  // async init
}
```

## THREADING

**Rules:**
- `@MainActor` on all ViewModels
- UI updates automatic on main thread
- Manual dispatch if needed: `await MainActor.run { }`
- Background work in `Task { }` (actor-isolated)

## CODE STYLE PREFERENCES

**General:**
- No force unwraps (!), use optional binding
- Prefer `if let` over guard for simple checks
- Use `guard` for early returns
- Monospaced fonts in UI
- Dark/light mode support

**Comments:**
- Minimal comments
- Code should be self-documenting
- Only comment complex algorithms

**Formatting:**
- 4-space indent (or Xcode default)
- Opening brace same line: `func foo() {`
- Line length: flexible, prefer readable
- Blank line between methods

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
10. Add destination in `RootView.destinationView()`
11. Create ViewModels in `RootView` as `@StateObject`
12. Inject ViewModel via `.environmentObject()`
13. Add Components to `Presentation/Components/` if reusable

## QUICK REFERENCE

| Layer | Protocol | Implementation | DI |
|-------|----------|----------------|-----|
| Service | `protocol XService` | `class XServiceImpl: XService` | `DIContainer.shared.xService` |
| Repository | `protocol XRepository` | `class XRepositoryImpl: XRepository` | `DIContainer.shared.xRepository` |
| ViewModel | - | `@MainActor final class XViewmodel: ObservableObject` | Created in RootView |
| View | - | `struct XView: View` | Injected via @EnvironmentObject |
| Entity | - | `@Model class X` or `struct X` or `enum X` | - |

---

## BUILD SYSTEM & PROJECT SETUP

For project initialization, Tuist configuration, Makefile, and environment setup, see [PROJECT_SETUP.md](./PROJECT_SETUP.md).

### Build Verification

**Use this command to verify builds:**
```bash
xcodebuild -workspace SurahFocus.xcworkspace -scheme SurahFocus -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(BUILD|error:)" | tail -10
```

**Build Rules:**
- Build ONCE at end of work to verify, fix all issues at once
- Don't build too frequently - only at end for verification

---

## DEVELOPMENT WORKFLOW

**ALWAYS REFERENCE PLANNING DOCS:**
- SURAH_FOCUS_PRD.md - feature requirements & user stories
- SURAH_FOCUS_SYSTEM_DESIGN.md - architecture & service specs
- SURAH_FOCUS_MILESTONES.md - timeline & phase tasks
- PROJECT_SETUP.md - build system & environment
- MINDCORE_MIGRATION_GUIDE.md - Screen Time code reference

**CONFIRMATION OVER HYPOTHESIS:**
- Never assume - confirm anything uncertain with user
- Ask questions before making architectural decisions
- Request human input for UI/UX, complex logic, edge cases

**UNIT TESTING:**
- Create unit tests for all new code
- Test services, repositories, ViewModels
- Use XCTest framework
- Place tests in `Tests/` directory

**PLAN VALIDATION:**
- Always validate plan phases before execution
- Cross-reference with milestones
- Check dependencies between tasks

**DECISION MAKING:**
- Ultra think before decisions
- Consider trade-offs explicitly
- Document rationale in plan

---

**Summary:** Clean Architecture + MVVM + Protocol-Oriented + Dependency Injection + SwiftUI reactive patterns.
