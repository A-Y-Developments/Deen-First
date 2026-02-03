# PHASE 5: MAIN TABS + QURAN READING
**Timeline:** Days 8-9 (Feb 10-11)  
**Duration:** 2 full days  
**Goal:** 3-tab navigation working, Quran browsing functional, reading experience polished

---

## PREREQUISITES

- [ ] Phase 4 completed (Quran API working)
- [ ] Can fetch all 114 surahs
- [ ] Caching functional
- [ ] 93+ tests passing

---

## PHASE OVERVIEW

This phase builds the main app experience:
1. MainTabView with 3 tabs (Quran, Blocking, Settings)
2. QuranTabView with surah list and search
3. SurahDetailView with ayah display
4. Streak badge component
5. Reusable UI components
6. Empty states for tabs

**By end of Phase 5, you will have:**
- ✅ 3-tab navigation functional
- ✅ Can browse all 114 surahs
- ✅ Search filters correctly
- ✅ Can read any surah with translation
- ✅ Streak displays on Quran tab
- ✅ 110+ unit tests passing

---

## TASK 5.1: MAIN TAB VIEW (Day 8 Morning - 2 hours)

### Step 1: Create MainTabView

**Create `Sources/Presentation/MainTabs/MainTabView.swift`:**

```swift
import SwiftUI

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
        .accentColor(Color(hex: "4facfe"))
    }
}

#Preview {
    MainTabView()
}
```

### Step 2: Create Placeholder Tab Views

**Create `Sources/Presentation/MainTabs/BlockingTab/BlockingTabView.swift`:**

```swift
import SwiftUI

struct BlockingTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "4facfe"))
                
                Text("Blocking")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Phase 7: Manage blocked apps and time limits")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Blocking")
        }
    }
}
```

**Create `Sources/Presentation/MainTabs/SettingsTab/SettingsTabView.swift`:**

```swift
import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "4facfe"))
                
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Phase 7: Profile, subscription, and app settings")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}
```

### Step 3: Update RootView

**Update `Sources/RootView.swift`:**

```swift
case .mainTabs:
    MainTabView()
```

### Verification Checkpoint 1:

```bash
make build
```

**Test in simulator:**
1. Navigate to main tabs
2. Verify 3 tabs display
3. Can switch between tabs
4. Tab bar icons correct

---

## TASK 5.2: QURAN TAB VIEWMODEL (Day 8 Morning - 2 hours)

### Step 1: Create QuranTabViewModel

**Create `Sources/Presentation/MainTabs/QuranTab/QuranTabViewModel.swift`:**

```swift
import SwiftUI

@MainActor
final class QuranTabViewModel: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var filteredSurahs: [Surah] = []
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var currentStreak = 0
    
    private let quranService: QuranService
    private let authService: AuthService
    
    init(
        quranService: QuranService? = nil,
        authService: AuthService? = nil
    ) {
        self.quranService = quranService ?? DIContainer.shared.quranService
        self.authService = authService ?? DIContainer.shared.authService
    }
    
    func loadSurahs() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            surahs = try await quranService.loadAllSurahs()
            filteredSurahs = surahs
            
            // Load user streak
            if let user = try await authService.getCurrentUser() {
                currentStreak = user.currentStreak
            }
        } catch {
            errorMessage = "Failed to load surahs: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func searchSurahs() {
        if searchQuery.isEmpty {
            filteredSurahs = surahs
        } else {
            filteredSurahs = quranService.searchSurahs(query: searchQuery, in: surahs)
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        filteredSurahs = surahs
    }
}
```

### Step 2: Create QuranTabViewModel Tests

**Create `Tests/Presentation/MainTabs/QuranTabViewModelTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

@MainActor
final class QuranTabViewModelTests: XCTestCase {
    var viewModel: QuranTabViewModel!
    var mockQuranService: MockQuranService!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        mockQuranService = MockQuranService()
        mockAuthService = MockAuthService()
        viewModel = QuranTabViewModel(
            quranService: mockQuranService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockQuranService = nil
        mockAuthService = nil
    }
    
    func testInitialState() {
        XCTAssertTrue(viewModel.surahs.isEmpty)
        XCTAssertTrue(viewModel.filteredSurahs.isEmpty)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.currentStreak, 0)
    }
    
    func testLoadSurahsSuccess() async {
        let mockSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        mockQuranService.surahsToReturn = mockSurahs
        
        await viewModel.loadSurahs()
        
        XCTAssertEqual(viewModel.surahs.count, 1)
        XCTAssertEqual(viewModel.filteredSurahs.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadSurahsLoadsUserStreak() async {
        let mockUser = User(appleUserId: "test123")
        mockUser.currentStreak = 5
        mockAuthService.userToReturn = mockUser
        
        await viewModel.loadSurahs()
        
        XCTAssertEqual(viewModel.currentStreak, 5)
    }
    
    func testSearchSurahsFiltersResults() {
        viewModel.surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "Al-Fatihah", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan"),
            Surah(number: 2, name: "Al-Baqarah", englishName: "Al-Baqarah", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationType: "Medinan")
        ]
        viewModel.filteredSurahs = viewModel.surahs
        mockQuranService.searchResults = [viewModel.surahs[0]]
        
        viewModel.searchQuery = "opening"
        viewModel.searchSurahs()
        
        XCTAssertEqual(viewModel.filteredSurahs.count, 1)
        XCTAssertEqual(viewModel.filteredSurahs.first?.englishName, "Al-Fatihah")
    }
    
    func testClearSearchRestoresAllSurahs() {
        viewModel.surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "Al-Fatihah", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        viewModel.searchQuery = "test"
        viewModel.filteredSurahs = []
        
        viewModel.clearSearch()
        
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.filteredSurahs.count, 1)
    }
}

// MARK: - Mock Services

class MockQuranService: QuranService {
    var surahsToReturn: [Surah] = []
    var searchResults: [Surah] = []
    
    func loadAllSurahs() async throws -> [Surah] {
        return surahsToReturn
    }
    
    func loadSurahDetail(number: Int, withTranslation: Bool) async throws -> (surah: Surah, ayahs: [Ayah]) {
        let surah = Surah(number: number, name: "", englishName: "", englishNameTranslation: "", numberOfAyahs: 0, revelationType: "")
        return (surah, [])
    }
    
    func getAudioURL(for surah: Surah, reciterId: Int) -> String {
        return ""
    }
    
    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah] {
        return searchResults
    }
}
```

### Verification Checkpoint 2:

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranTabViewModelTests' passed (5 tests)
```

---

## TASK 5.3: QURAN TAB VIEW (Day 8 Afternoon - 3 hours)

### Step 1: Create Surah Card Component

**Create `Sources/Presentation/Components/SurahCard.swift`:**

```swift
import SwiftUI

struct SurahCard: View {
    let surah: Surah
    
    var body: some View {
        HStack(spacing: 16) {
            // Surah number badge
            ZStack {
                Circle()
                    .strokeBorder(Color(hex: "4facfe"), lineWidth: 2)
                    .frame(width: 50, height: 50)
                
                Text("\(surah.number)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "4facfe"))
            }
            
            // Surah info
            VStack(alignment: .leading, spacing: 4) {
                Text(surah.englishName)
                    .font(.system(size: 18, weight: .semibold))
                
                HStack(spacing: 8) {
                    Text(surah.englishNameTranslation)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(surah.numberOfAyahs) ayahs")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Arabic name
            Text(surah.name)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    SurahCard(
        surah: Surah(
            number: 1,
            name: "سُورَةُ ٱلْفَاتِحَةِ",
            englishName: "Al-Fatihah",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationType: "Meccan"
        )
    )
    .padding()
}
```

### Step 2: Create Streak Badge Component

**Create `Sources/Presentation/Components/StreakBadge.swift`:**

```swift
import SwiftUI

struct StreakBadge: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Text("🔥")
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Keep it going!")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "FFE5B4").opacity(0.3),
                    Color(hex: "FFD700").opacity(0.2)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

#Preview {
    StreakBadge(streak: 7)
        .padding()
}
```

### Step 3: Create QuranTabView

**Create `Sources/Presentation/MainTabs/QuranTab/QuranTabView.swift`:**

```swift
import SwiftUI

struct QuranTabView: View {
    @StateObject private var viewModel = QuranTabViewModel()
    @EnvironmentObject var router: Router
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.surahs.isEmpty {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Streak Badge
                            if viewModel.currentStreak > 0 {
                                StreakBadge(streak: viewModel.currentStreak)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                            }
                            
                            // Search Bar
                            SearchBar(
                                text: $viewModel.searchQuery,
                                placeholder: "Search surahs..."
                            )
                            .onChange(of: viewModel.searchQuery) { _, _ in
                                viewModel.searchSurahs()
                            }
                            .padding(.horizontal, 16)
                            
                            // Surah List
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredSurahs) { surah in
                                    Button {
                                        router.navigate(to: .surahDetail(surahId: surah.number))
                                    } label: {
                                        SurahCard(surah: surah)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await viewModel.loadSurahs()
                    }
                }
            }
            .navigationTitle("Quran")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        router.navigate(to: .listenSession)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(Color(hex: "4facfe"))
                    }
                }
            }
        }
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    QuranTabView()
        .environmentObject(Router())
}
```

### Step 4: Create SearchBar Component

**Create `Sources/Presentation/Components/SearchBar.swift`:**

```swift
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
```

### Verification Checkpoint 3:

```bash
make build
```

**Test in simulator:**
1. Navigate to Quran tab
2. Should see loading indicator
3. 114 surahs load
4. Streak badge displays (if user has streak)
5. Search bar functional
6. Can scroll through surahs

---

## TASK 5.4: SURAH DETAIL VIEWMODEL (Day 9 Morning - 2 hours)

### Step 1: Create SurahDetailViewModel

**Create `Sources/Presentation/MainTabs/QuranTab/SurahDetailViewModel.swift`:**

```swift
import SwiftUI

@MainActor
final class SurahDetailViewModel: ObservableObject {
    @Published var surah: Surah?
    @Published var ayahs: [Ayah] = []
    @Published var showTranslation = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let quranService: QuranService
    private let surahNumber: Int
    
    init(surahNumber: Int, quranService: QuranService? = nil) {
        self.surahNumber = surahNumber
        self.quranService = quranService ?? DIContainer.shared.quranService
    }
    
    func loadSurahDetail() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let (loadedSurah, loadedAyahs) = try await quranService.loadSurahDetail(
                number: surahNumber,
                withTranslation: showTranslation
            )
            surah = loadedSurah
            ayahs = loadedAyahs
        } catch {
            errorMessage = "Failed to load surah: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func toggleTranslation() async {
        showTranslation.toggle()
        await loadSurahDetail()
    }
}
```

### Step 2: Create SurahDetailViewModel Tests

**Create `Tests/Presentation/MainTabs/SurahDetailViewModelTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

@MainActor
final class SurahDetailViewModelTests: XCTestCase {
    var viewModel: SurahDetailViewModel!
    var mockQuranService: MockQuranService!
    
    override func setUp() {
        mockQuranService = MockQuranService()
        viewModel = SurahDetailViewModel(surahNumber: 1, quranService: mockQuranService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockQuranService = nil
    }
    
    func testInitialState() {
        XCTAssertNil(viewModel.surah)
        XCTAssertTrue(viewModel.ayahs.isEmpty)
        XCTAssertTrue(viewModel.showTranslation)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadSurahDetailSuccess() async {
        let mockSurah = Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        let mockAyahs = [
            Ayah(number: 1, text: "بِسْمِ اللَّهِ", numberInSurah: 1)
        ]
        mockQuranService.surahToReturn = mockSurah
        mockQuranService.ayahsToReturn = mockAyahs
        
        await viewModel.loadSurahDetail()
        
        XCTAssertNotNil(viewModel.surah)
        XCTAssertEqual(viewModel.ayahs.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testToggleTranslationChangesState() async {
        await viewModel.toggleTranslation()
        
        XCTAssertFalse(viewModel.showTranslation)
    }
}
```

### Verification Checkpoint 4:

```bash
make test
```

**Expected Output:**
```
Test Suite 'SurahDetailViewModelTests' passed (3 tests)
```

---

## TASK 5.5: SURAH DETAIL VIEW (Day 9 Afternoon - 4 hours)

### Step 1: Create Ayah Card Component

**Create `Sources/Presentation/Components/AyahCard.swift`:**

```swift
import SwiftUI

struct AyahCard: View {
    let ayah: Ayah
    let showTranslation: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Ayah number
            HStack {
                Circle()
                    .fill(Color(hex: "4facfe").opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("\(ayah.numberInSurah)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "4facfe"))
                    )
                
                Spacer()
            }
            
            // Arabic text
            Text(ayah.text)
                .font(.system(size: 24, weight: .medium))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Translation
            if showTranslation, let translation = ayah.translation {
                Divider()
                    .padding(.vertical, 4)
                
                Text(translation)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AyahCard(
        ayah: Ayah(
            number: 1,
            text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            numberInSurah: 1,
            translation: "In the name of Allah, the Entirely Merciful, the Especially Merciful."
        ),
        showTranslation: true
    )
    .padding()
}
```

### Step 2: Create SurahDetailView

**Create `Sources/Presentation/MainTabs/QuranTab/SurahDetailView.swift`:**

```swift
import SwiftUI

struct SurahDetailView: View {
    let surahNumber: Int
    @StateObject private var viewModel: SurahDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(surahNumber: Int) {
        self.surahNumber = surahNumber
        _viewModel = StateObject(wrappedValue: SurahDetailViewModel(surahNumber: surahNumber))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.ayahs.isEmpty {
                ProgressView()
            } else if let surah = viewModel.surah {
                ScrollView {
                    VStack(spacing: 20) {
                        // Surah Header
                        SurahHeader(surah: surah)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // Bismillah (except for Surah 9)
                        if surah.number != 1 && surah.number != 9 {
                            BismillahView()
                                .padding(.horizontal, 16)
                        }
                        
                        // Ayahs
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.ayahs) { ayah in
                                AyahCard(
                                    ayah: ayah,
                                    showTranslation: viewModel.showTranslation
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80) // Space for floating button
                    }
                }
            }
        }
        .navigationTitle(viewModel.surah?.englishName ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.toggleTranslation()
                    }
                } label: {
                    Image(systemName: viewModel.showTranslation ? "text.bubble.fill" : "text.bubble")
                        .foregroundColor(Color(hex: "4facfe"))
                }
            }
        }
        .task {
            if viewModel.ayahs.isEmpty {
                await viewModel.loadSurahDetail()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

// MARK: - Supporting Views

struct SurahHeader: View {
    let surah: Surah
    
    var body: some View {
        VStack(spacing: 12) {
            Text(surah.name)
                .font(.system(size: 32, weight: .bold))
            
            Text(surah.englishNameTranslation)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Label("\(surah.numberOfAyahs) Ayahs", systemImage: "text.alignleft")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(surah.revelationType)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "4facfe").opacity(0.1),
                    Color(hex: "00f2fe").opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct BismillahView: View {
    var body: some View {
        Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
            .font(.system(size: 24, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "4facfe").opacity(0.05))
            .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        SurahDetailView(surahNumber: 1)
    }
}
```

### Step 3: Update Router

**Update `Sources/Core/SceneNavigation/Router.swift`:**

Add navigation destination in RootView:

```swift
case .surahDetail(let surahId):
    SurahDetailView(surahNumber: surahId)
```

### Verification Checkpoint 5:

```bash
make build
```

**Test in simulator:**
1. Navigate to Quran tab
2. Tap any surah
3. Surah detail loads
4. See surah header
5. See bismillah (if not surah 1 or 9)
6. Scroll through ayahs
7. Toggle translation button works
8. Translation shows/hides

---

## FINAL BUILD & TEST

### Step 1: Run All Tests

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranTabViewModelTests' passed (5 tests)
Test Suite 'SurahDetailViewModelTests' passed (3 tests)
[... previous tests ...]

Test Suite 'SurahFocusTests' passed (101+ tests)
```

### Step 2: Integration Test

**Full flow test:**
1. Launch app
2. Navigate to main tabs
3. See Quran tab with 114 surahs
4. Search for "opening" → Al-Fatihah appears
5. Clear search → all surahs return
6. Tap Al-Fatihah
7. See 7 ayahs with translations
8. Toggle translation off → translations hide
9. Toggle translation on → translations show
10. Navigate back → returns to list

### Step 3: Performance Test

**Scroll performance:**
1. Open Quran tab
2. Scroll rapidly through 114 surahs
3. Should be smooth (60 FPS)
4. Open any long surah (Al-Baqarah, 286 ayahs)
5. Scroll through ayahs
6. Should remain smooth

---

## PHASE 5 COMPLETION CHECKLIST

### Main Tab Structure
- [ ] MainTabView created with 3 tabs
- [ ] Tab bar icons and labels correct
- [ ] Tab switching works smoothly
- [ ] Placeholder views for Blocking and Settings

### Quran Tab
- [ ] QuranTabViewModel implemented
- [ ] QuranTabView created
- [ ] Can load all 114 surahs
- [ ] Streak badge displays
- [ ] Search bar functional
- [ ] Search filters correctly
- [ ] 5 Quran tab tests passing

### Surah Detail
- [ ] SurahDetailViewModel implemented
- [ ] SurahDetailView created
- [ ] Surah header displays correctly
- [ ] Bismillah shows (except surah 1, 9)
- [ ] All ayahs render
- [ ] Translation toggle works
- [ ] 3 surah detail tests passing

### Components
- [ ] SurahCard component
- [ ] AyahCard component
- [ ] StreakBadge component
- [ ] SearchBar component
- [ ] BismillahView component
- [ ] SurahHeader component

### Integration
- [ ] Router updated with surah detail route
- [ ] Navigation works end-to-end
- [ ] 101+ total tests passing
- [ ] Smooth scroll performance
- [ ] No memory leaks

### Verification Commands
```bash
# All tests pass
make test

# Build succeeds
make build

# Check performance
# Use Instruments > Time Profiler
# Scroll through surahs - should be 60 FPS
```

---

## TROUBLESHOOTING

### Issue: Surahs not loading
**Solution:**
1. Check internet connection
2. Verify API working (Phase 4)
3. Check cache for corrupted data
4. Clear cache and retry

### Issue: Search not working
**Solution:**
1. Verify searchSurahs() called on text change
2. Check search query not empty
3. Verify filteredSurahs updates
4. Check search implementation in service

### Issue: Scroll performance poor
**Solution:**
1. Use LazyVStack instead of VStack
2. Verify cards are efficient
3. Check for unnecessary re-renders
4. Profile with Instruments

### Issue: Translation not showing
**Solution:**
1. Check showTranslation flag
2. Verify API returns translations
3. Check ayah.translation not nil
4. Verify conditional rendering logic

---

## NEXT PHASE PREVIEW

**Phase 6 will cover:**
- AudioPlayerService with AVFoundation
- Background audio playback
- Lock screen controls
- SessionRepository implementation
- ListenSessionView with audio controls
- Session tracking and streak updates

**Prerequisites for Phase 6:**
- Phase 5 fully complete
- Can browse and read surahs
- 101+ tests passing
- Quran UI polished

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 5.1 (Main Tab View): 2 hours
- Task 5.2 (Quran Tab ViewModel): 2 hours
- Task 5.3 (Quran Tab View): 3 hours
- Task 5.4 (Surah Detail ViewModel): 2 hours
- Task 5.5 (Surah Detail View): 4 hours
- **Total: 13 hours over 2 days**

**If behind schedule:**
- Skip streak badge (add in Phase 8)
- Remove search functionality temporarily
- Simplify surah header design
- Use basic list instead of cards

---

**🎯 PHASE 5 COMPLETE! Ready for Phase 6: Listening Sessions + Audio Player**

Commit your work:
```bash
git add .
git commit -m "✅ Phase 5 complete: Main Tabs + Quran Reading + 101 tests passing"
git push
```
