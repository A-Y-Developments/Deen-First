# PHASE 3: ONBOARDING + SCREEN TIME PERMISSION
**Timeline:** Days 5-6 (Feb 7-8)  
**Duration:** 2 full days  
**Goal:** Complete 4-screen survey, Screen Time permission granted, app selection working

---

## PREREQUISITES

- [ ] Phase 2 completed (Auth + RevenueCat working)
- [ ] Can sign in with Apple successfully
- [ ] Paywall functional
- [ ] Physical iOS 17+ device ready
- [ ] Mindcore Screen Time code accessible

---

## PHASE OVERVIEW

This phase implements user onboarding and Screen Time setup:
1. Four-screen onboarding survey
2. Screen Time permission request
3. App selection using FamilyActivityPicker
4. Time limit configuration
5. First shield test on physical device

**By end of Phase 3, you will have:**
- ✅ 4-screen onboarding survey complete
- ✅ Screen Time permission granted
- ✅ Apps selectable via FamilyActivityPicker
- ✅ Time limits configurable
- ✅ First shield test successful
- ✅ 65+ unit tests passing

---

## TASK 3.1: ONBOARDING SURVEY DATA MODEL (Day 5 Morning - 1 hour)

### Step 1: Create Survey Response Model

**Create `Sources/Domain/Entities/onboarding_survey.swift`:**

```swift
import Foundation

struct OnboardingSurvey: Codable {
    var motivations: Set<Motivation>
    var distractionTimes: Set<DistractionTime>
    var goals: Set<Goal>
    var isCompleted: Bool
    var completedAt: Date?
    
    enum Motivation: String, Codable, CaseIterable {
        case consistency = "I want more consistency with the Quran"
        case distracted = "I get distracted too easily"
        case routine = "I want a simple daily routine"
        case focus = "I need help focusing"
        case reconnect = "I want to reconnect with my faith"
    }
    
    enum DistractionTime: String, Codable, CaseIterable {
        case lateNight = "Late at night"
        case overwhelmed = "When I feel overwhelmed"
        case throughout = "Throughout the day"
        case stressed = "When I feel stressed"
        case quickCheck = "For a minute (turns into hours)"
    }
    
    enum Goal: String, Codable, CaseIterable {
        case quranConsistency = "More consistency with the Quran"
        case presence = "More presence and focus"
        case betterHabits = "Better phone habits"
    }
    
    init() {
        self.motivations = []
        self.distractionTimes = []
        self.goals = []
        self.isCompleted = false
        self.completedAt = nil
    }
}
```

### Step 2: Survey Persistence Helper

**Create `Sources/Utils/SurveyStorage.swift`:**

```swift
import Foundation

final class SurveyStorage {
    private static let key = "onboarding_survey"
    
    static func save(_ survey: OnboardingSurvey) {
        if let encoded = try? JSONEncoder().encode(survey) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func load() -> OnboardingSurvey? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let survey = try? JSONDecoder().decode(OnboardingSurvey.self, from: data) else {
            return nil
        }
        return survey
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

---

## TASK 3.2: ONBOARDING VIEWMODEL (Day 5 Morning - 2 hours)

### Step 1: Create OnboardingViewModel

**Create `Sources/Presentation/Onboarding/OnboardingViewModel.swift`:**

```swift
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var survey = OnboardingSurvey()
    @Published var canContinue = false
    
    private let totalSteps = 4
    
    var progressText: String {
        "\(currentStep + 1)/\(totalSteps)"
    }
    
    var canGoBack: Bool {
        currentStep > 0
    }
    
    // MARK: - Step 1: Motivations
    
    func toggleMotivation(_ motivation: OnboardingSurvey.Motivation) {
        if survey.motivations.contains(motivation) {
            survey.motivations.remove(motivation)
        } else {
            survey.motivations.insert(motivation)
        }
        updateContinueState()
        saveSurvey()
    }
    
    func isMotivationSelected(_ motivation: OnboardingSurvey.Motivation) -> Bool {
        survey.motivations.contains(motivation)
    }
    
    // MARK: - Step 2: Distraction Times
    
    func toggleDistractionTime(_ time: OnboardingSurvey.DistractionTime) {
        if survey.distractionTimes.contains(time) {
            survey.distractionTimes.remove(time)
        } else {
            survey.distractionTimes.insert(time)
        }
        updateContinueState()
        saveSurvey()
    }
    
    func isDistractionTimeSelected(_ time: OnboardingSurvey.DistractionTime) -> Bool {
        survey.distractionTimes.contains(time)
    }
    
    // MARK: - Step 3: Goals
    
    func toggleGoal(_ goal: OnboardingSurvey.Goal) {
        if survey.goals.contains(goal) {
            survey.goals.remove(goal)
        } else {
            survey.goals.insert(goal)
        }
        updateContinueState()
        saveSurvey()
    }
    
    func isGoalSelected(_ goal: OnboardingSurvey.Goal) -> Bool {
        survey.goals.contains(goal)
    }
    
    // MARK: - Navigation
    
    func goNext() {
        guard canContinue else { return }
        
        if currentStep < totalSteps - 1 {
            currentStep += 1
            updateContinueState()
        }
    }
    
    func goBack() {
        if currentStep > 0 {
            currentStep -= 1
            updateContinueState()
        }
    }
    
    func skip() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
            updateContinueState()
        }
    }
    
    func complete() {
        survey.isCompleted = true
        survey.completedAt = Date()
        saveSurvey()
    }
    
    // MARK: - Private Helpers
    
    private func updateContinueState() {
        switch currentStep {
        case 0: // Motivations
            canContinue = !survey.motivations.isEmpty
        case 1: // Distraction times
            canContinue = !survey.distractionTimes.isEmpty
        case 2: // Goals
            canContinue = !survey.goals.isEmpty
        case 3: // Time comparison (always enabled)
            canContinue = true
        default:
            canContinue = false
        }
    }
    
    private func saveSurvey() {
        SurveyStorage.save(survey)
    }
    
    func loadSavedSurvey() {
        if let saved = SurveyStorage.load() {
            survey = saved
            updateContinueState()
        }
    }
}
```

### Step 2: Create OnboardingViewModel Tests

**Create `Tests/Presentation/Onboarding/OnboardingViewModelTests.swift`:**

```swift
import XCTest
@testable import DeenFirst

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    var viewModel: OnboardingViewModel!
    
    override func setUp() {
        viewModel = OnboardingViewModel()
        SurveyStorage.clear()
    }
    
    override func tearDown() {
        viewModel = nil
        SurveyStorage.clear()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertTrue(viewModel.survey.motivations.isEmpty)
        XCTAssertFalse(viewModel.canContinue)
    }
    
    func testProgressText() {
        XCTAssertEqual(viewModel.progressText, "1/4")
        viewModel.currentStep = 1
        XCTAssertEqual(viewModel.progressText, "2/4")
    }
    
    func testToggleMotivation() {
        let motivation = OnboardingSurvey.Motivation.consistency
        
        viewModel.toggleMotivation(motivation)
        XCTAssertTrue(viewModel.isMotivationSelected(motivation))
        XCTAssertTrue(viewModel.canContinue)
        
        viewModel.toggleMotivation(motivation)
        XCTAssertFalse(viewModel.isMotivationSelected(motivation))
        XCTAssertFalse(viewModel.canContinue)
    }
    
    func testToggleDistractionTime() {
        viewModel.currentStep = 1
        let time = OnboardingSurvey.DistractionTime.lateNight
        
        viewModel.toggleDistractionTime(time)
        XCTAssertTrue(viewModel.isDistractionTimeSelected(time))
        XCTAssertTrue(viewModel.canContinue)
    }
    
    func testToggleGoal() {
        viewModel.currentStep = 2
        let goal = OnboardingSurvey.Goal.quranConsistency
        
        viewModel.toggleGoal(goal)
        XCTAssertTrue(viewModel.isGoalSelected(goal))
        XCTAssertTrue(viewModel.canContinue)
    }
    
    func testGoNextIncreasesStep() {
        viewModel.toggleMotivation(.consistency)
        viewModel.goNext()
        
        XCTAssertEqual(viewModel.currentStep, 1)
    }
    
    func testGoBackDecreasesStep() {
        viewModel.currentStep = 2
        viewModel.goBack()
        
        XCTAssertEqual(viewModel.currentStep, 1)
    }
    
    func testCannotGoBackFromFirstStep() {
        XCTAssertFalse(viewModel.canGoBack)
        
        viewModel.currentStep = 1
        XCTAssertTrue(viewModel.canGoBack)
    }
    
    func testSkipAdvancesStep() {
        viewModel.skip()
        XCTAssertEqual(viewModel.currentStep, 1)
    }
    
    func testCompleteSetsCompletionFlag() {
        viewModel.complete()
        
        XCTAssertTrue(viewModel.survey.isCompleted)
        XCTAssertNotNil(viewModel.survey.completedAt)
    }
    
    func testSurveyPersistence() {
        viewModel.toggleMotivation(.consistency)
        viewModel.toggleMotivation(.focus)
        
        // Create new viewModel and load
        let newViewModel = OnboardingViewModel()
        newViewModel.loadSavedSurvey()
        
        XCTAssertTrue(newViewModel.isMotivationSelected(.consistency))
        XCTAssertTrue(newViewModel.isMotivationSelected(.focus))
    }
}
```

### Verification Checkpoint 1:

```bash
make test
```

**Expected Output:**
```
Test Suite 'OnboardingViewModelTests' passed (12 tests)
```

---

## TASK 3.3: ONBOARDING VIEWS (Day 5 Afternoon - 4 hours)

### Step 1: Create Reusable Components

**Create `Sources/Presentation/Components/SelectableCard.swift`:**

```swift
import SwiftUI

struct SelectableCard: View {
    let text: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(text: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 24))
                }
                
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "4facfe") : .white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}
```

### Step 2: Create OnboardingView Container

**Create `Sources/Presentation/Onboarding/OnboardingView.swift`:**

```swift
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = OnboardingViewModel()
    
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
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    if viewModel.canGoBack {
                        Button(action: viewModel.goBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Text(viewModel.progressText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if viewModel.currentStep < 3 {
                        Button("Skip") {
                            viewModel.skip()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    } else {
                        // Invisible spacer for alignment
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.clear)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    OnboardingStep1View(viewModel: viewModel)
                        .tag(0)
                    OnboardingStep2View(viewModel: viewModel)
                        .tag(1)
                    OnboardingStep3View(viewModel: viewModel)
                        .tag(2)
                    OnboardingStep4View(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Continue Button
                Button {
                    if viewModel.currentStep == 3 {
                        viewModel.complete()
                        router.navigate(to: .paywall)
                    } else {
                        viewModel.goNext()
                    }
                } label: {
                    Text(viewModel.currentStep == 3 ? "Continue" : "Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.canContinue ?
                            LinearGradient(
                                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .disabled(!viewModel.canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            viewModel.loadSavedSurvey()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(Router())
}
```

### Step 3: Create Survey Step Views

**Create `Sources/Presentation/Onboarding/OnboardingStep1View.swift`:**

```swift
import SwiftUI

struct OnboardingStep1View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What brings you here today?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select all that apply")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)
                
                VStack(spacing: 12) {
                    ForEach(OnboardingSurvey.Motivation.allCases, id: \.self) { motivation in
                        SelectableCard(
                            text: motivation.rawValue,
                            isSelected: viewModel.isMotivationSelected(motivation)
                        ) {
                            viewModel.toggleMotivation(motivation)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
```

**Create `Sources/Presentation/Onboarding/OnboardingStep2View.swift`:**

```swift
import SwiftUI

struct OnboardingStep2View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When does your phone distract you most?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select all that apply")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)
                
                VStack(spacing: 12) {
                    SelectableCard(
                        text: "Late at night",
                        icon: "🌙",
                        isSelected: viewModel.isDistractionTimeSelected(.lateNight)
                    ) {
                        viewModel.toggleDistractionTime(.lateNight)
                    }
                    
                    SelectableCard(
                        text: "When I feel overwhelmed",
                        icon: "😰",
                        isSelected: viewModel.isDistractionTimeSelected(.overwhelmed)
                    ) {
                        viewModel.toggleDistractionTime(.overwhelmed)
                    }
                    
                    SelectableCard(
                        text: "Throughout the day",
                        icon: "☀️",
                        isSelected: viewModel.isDistractionTimeSelected(.throughout)
                    ) {
                        viewModel.toggleDistractionTime(.throughout)
                    }
                    
                    SelectableCard(
                        text: "When I feel stressed",
                        icon: "😓",
                        isSelected: viewModel.isDistractionTimeSelected(.stressed)
                    ) {
                        viewModel.toggleDistractionTime(.stressed)
                    }
                    
                    SelectableCard(
                        text: "For a minute (turns into hours)",
                        icon: "⏱️",
                        isSelected: viewModel.isDistractionTimeSelected(.quickCheck)
                    ) {
                        viewModel.toggleDistractionTime(.quickCheck)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
```

**Create `Sources/Presentation/Onboarding/OnboardingStep3View.swift`:**

```swift
import SwiftUI

struct OnboardingStep3View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you want more of?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select what matters most")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)
                
                VStack(spacing: 12) {
                    ForEach(OnboardingSurvey.Goal.allCases, id: \.self) { goal in
                        SelectableCard(
                            text: goal.rawValue,
                            isSelected: viewModel.isGoalSelected(goal)
                        ) {
                            viewModel.toggleGoal(goal)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
```

**Create `Sources/Presentation/Onboarding/OnboardingStep4View.swift`:**

```swift
import SwiftUI

struct OnboardingStep4View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Based on average usage:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("You spend ~2.5 hours\ndaily on social media")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("That's enough time to:")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    TimeComparisonRow(icon: "📖", text: "Read 5 surahs of the Quran")
                    TimeComparisonRow(icon: "⏰", text: "Complete 30 minutes of focused work")
                    TimeComparisonRow(icon: "💬", text: "Have meaningful conversations")
                }
                .padding(.horizontal, 24)
                
                Text("Let's create space for what matters 🌙")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}

struct TimeComparisonRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 32))
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
```

### Verification Checkpoint 2:

```bash
make build
```

**Then test in Xcode:**
1. Run on simulator
2. Navigate through all 4 survey screens
3. Verify selections persist
4. Verify can go back/skip
5. Verify continue button state changes

---

## TASK 3.4: SCREEN TIME UTILS (Day 6 Morning - 2 hours)

### Step 1: Copy and Adapt Screen Time Helpers

**From mindcore, copy these to `Sources/Utils/ScreenTime/`:**

**Create `Sources/Utils/ScreenTime/TimeLimit.swift`:**

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
    
    var seconds: Int {
        return self.rawValue * 60
    }
}
```

**Create `Sources/Utils/ScreenTime/AppGroupConstants.swift`:**

```swift
import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.aydev.deenfirst"
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    // Storage keys
    static let tokenMappingKey = "tokenMapping"
    static let categoryTokensKey = "categoryTokens"
    static let selectedAppsKey = "selectedApps"
}
```

### Step 2: Update Extension Files

**Update `ScreenTimeMonitor/DeviceActivityMonitorExtension.swift`:**

Search and replace all instances of:
```swift
// OLD:
UserDefaults(suiteName: "group.com.alexis.screentime")

// NEW:
UserDefaults(suiteName: "group.com.aydev.deenfirst")
```

Or better yet, use the constant:
```swift
import Foundation

let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
```

---

## TASK 3.5: SCREEN TIME PERMISSION VIEW (Day 6 Morning - 2 hours)

### Step 1: Create ScreenTimePermissionViewModel

**Create `Sources/Presentation/Onboarding/ScreenTimePermissionViewModel.swift`:**

```swift
import SwiftUI
import FamilyControls

@MainActor
final class ScreenTimePermissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let authCenter = AuthorizationCenter.shared
    
    func checkAuthorization() {
        isAuthorized = authCenter.authorizationStatus == .approved
    }
    
    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await authCenter.requestAuthorization(for: .individual)
            isAuthorized = authCenter.authorizationStatus == .approved
            
            if !isAuthorized {
                errorMessage = "Permission was denied. You can enable it later in Settings."
                showError = true
            }
        } catch {
            errorMessage = "Failed to request permission: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func skip() {
        // User can skip, but they'll need to grant permission later
    }
}
```

### Step 2: Create ScreenTimePermissionView

**Create `Sources/Presentation/Onboarding/ScreenTimePermissionView.swift`:**

```swift
import SwiftUI

struct ScreenTimePermissionView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = ScreenTimePermissionViewModel()
    
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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Title & Description
                VStack(spacing: 16) {
                    Text("Screen Time Permission")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("To block distracting apps, we need Screen Time permission. This allows Deen First to temporarily restrict apps during your Quran sessions.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Info Cards
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "checkmark.circle.fill", text: "Permission is required to use app blocking")
                    InfoRow(icon: "checkmark.circle.fill", text: "You control what gets blocked")
                    InfoRow(icon: "checkmark.circle.fill", text: "We never access your personal data")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await viewModel.requestAuthorization()
                            if viewModel.isAuthorized {
                                router.navigate(to: .appSelection)
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Grant Permission")
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
                    
                    Button("I'll do this later") {
                        viewModel.skip()
                        router.navigate(to: .mainTabs)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onAppear {
            viewModel.checkAuthorization()
            if viewModel.isAuthorized {
                // Already authorized, skip to app selection
                router.replaceWith(.appSelection)
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "4facfe"))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

#Preview {
    ScreenTimePermissionView()
        .environmentObject(Router())
}
```

### Step 3: Create Tests

**Create `Tests/Presentation/Onboarding/ScreenTimePermissionViewModelTests.swift`:**

```swift
import XCTest
@testable import DeenFirst

@MainActor
final class ScreenTimePermissionViewModelTests: XCTestCase {
    var viewModel: ScreenTimePermissionViewModel!
    
    override func setUp() {
        viewModel = ScreenTimePermissionViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isAuthorized)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    // Note: Full authorization tests require physical device
    // These are structural tests only
}
```

### Verification Checkpoint 3:

```bash
make test
make build
```

**Test on physical device:**
1. Run app on device
2. Complete onboarding survey
3. Complete paywall (sandbox purchase)
4. See permission screen
5. Tap "Grant Permission"
6. iOS permission dialog appears
7. Grant permission
8. Verify `isAuthorized` becomes true

---

## TASK 3.6: APP SELECTION VIEW (Day 6 Afternoon - 3 hours)

### Step 1: Create AppSelectionViewModel

**Create `Sources/Presentation/Onboarding/AppSelectionViewModel.swift`:**

```swift
import SwiftUI
import FamilyControls

@MainActor
final class AppSelectionViewModel: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var isPresented = false
    @Published var selectedAppsCount: Int = 0
    @Published var timeLimits: [String: TimeLimit] = [:]
    
    func openPicker() {
        isPresented = true
    }
    
    func updateSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        selectedAppsCount = selection.applicationTokens.count + selection.categoryTokens.count
        
        // Initialize time limits for new apps
        for token in selection.applicationTokens {
            let key = token.description
            if timeLimits[key] == nil {
                timeLimits[key] = .sixty // Default 1 hour
            }
        }
        
        // Remove time limits for deselected apps
        let currentKeys = Set(selection.applicationTokens.map { $0.description })
        timeLimits = timeLimits.filter { currentKeys.contains($0.key) }
        
        saveSelection()
    }
    
    func setTimeLimit(_ limit: TimeLimit, for token: ApplicationToken) {
        timeLimits[token.description] = limit
        saveSelection()
    }
    
    func getTimeLimit(for token: ApplicationToken) -> TimeLimit {
        timeLimits[token.description] ?? .sixty
    }
    
    private func saveSelection() {
        // Save to App Group UserDefaults for extension access
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else { return }
        
        // Save application tokens
        var tokenMapping: [String: Data] = [:]
        for token in selection.applicationTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                tokenMapping[token.description] = encoded
            }
        }
        sharedDefaults.set(tokenMapping, forKey: AppGroupConstants.tokenMappingKey)
        
        // Save category tokens
        var categoryMapping: [String: Data] = [:]
        for token in selection.categoryTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                categoryMapping[token.description] = encoded
            }
        }
        sharedDefaults.set(categoryMapping, forKey: AppGroupConstants.categoryTokensKey)
        
        // Save time limits
        let limitsDict = timeLimits.mapValues { $0.rawValue }
        UserDefaults.standard.set(limitsDict, forKey: "appTimeLimits")
    }
    
    func loadSavedSelection() {
        // Load from UserDefaults
        if let limitsDict = UserDefaults.standard.dictionary(forKey: "appTimeLimits") as? [String: Int] {
            timeLimits = limitsDict.compactMapValues { TimeLimit(rawValue: $0) }
        }
        
        selectedAppsCount = selection.applicationTokens.count + selection.categoryTokens.count
    }
}
```

### Step 2: Create AppSelectionView

**Create `Sources/Presentation/Onboarding/AppSelectionView.swift`:**

```swift
import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = AppSelectionViewModel()
    
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
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Let's start simple")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Which app distracts you most?")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("You can select more apps or edit this later")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                // App Picker Button
                Button {
                    viewModel.openPicker()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "4facfe"))
                        
                        Text(viewModel.selectedAppsCount == 0 ? "Select Apps" : "\(viewModel.selectedAppsCount) apps selected")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                // Selected Apps Preview (if any)
                if !viewModel.selection.applicationTokens.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Set daily limits:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(Array(viewModel.selection.applicationTokens), id: \.self) { token in
                                AppLimitCard(
                                    token: token,
                                    selectedLimit: viewModel.getTimeLimit(for: token)
                                ) { newLimit in
                                    viewModel.setTimeLimit(newLimit, for: token)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Continue Button
                Button {
                    router.navigate(to: .mainTabs)
                } label: {
                    Text("Complete Setup")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.selectedAppsCount > 0 ?
                            LinearGradient(
                                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .disabled(viewModel.selectedAppsCount == 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.isPresented,
            selection: $viewModel.selection
        )
        .onChange(of: viewModel.selection) { oldValue, newValue in
            viewModel.updateSelection(newValue)
        }
        .onAppear {
            viewModel.loadSavedSelection()
        }
    }
}

struct AppLimitCard: View {
    let token: ApplicationToken
    let selectedLimit: TimeLimit
    let onLimitChanged: (TimeLimit) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App name would come from token metadata if available
            Text("Selected App")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            // Time limit options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeLimit.allCases, id: \.self) { limit in
                        Button {
                            onLimitChanged(limit)
                        } label: {
                            Text(limit.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedLimit == limit ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedLimit == limit ?
                                    Color(hex: "4facfe") :
                                    Color.white.opacity(0.1)
                                )
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    AppSelectionView()
        .environmentObject(Router())
}
```

### Step 3: Create Tests

**Create `Tests/Presentation/Onboarding/AppSelectionViewModelTests.swift`:**

```swift
import XCTest
import FamilyControls
@testable import DeenFirst

@MainActor
final class AppSelectionViewModelTests: XCTestCase {
    var viewModel: AppSelectionViewModel!
    
    override func setUp() {
        viewModel = AppSelectionViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.selectedAppsCount, 0)
        XCTAssertFalse(viewModel.isPresented)
        XCTAssertTrue(viewModel.timeLimits.isEmpty)
    }
    
    func testOpenPicker() {
        viewModel.openPicker()
        XCTAssertTrue(viewModel.isPresented)
    }
    
    // Note: Full FamilyActivityPicker tests require physical device
}
```

### Verification Checkpoint 4:

**Test on physical device:**
1. After granting Screen Time permission
2. App selection screen appears
3. Tap "Select Apps"
4. FamilyActivityPicker opens
5. Select 2-3 apps (e.g., Instagram, TikTok)
6. Time limit cards appear
7. Change time limits
8. Tap "Complete Setup"
9. Navigate to main tabs

---

## FINAL BUILD & TEST

### Step 1: Run All Tests

```bash
make test
```

**Expected Output:**
```
Test Suite 'OnboardingViewModelTests' passed (12 tests)
Test Suite 'ScreenTimePermissionViewModelTests' passed (1 test)
Test Suite 'AppSelectionViewModelTests' passed (2 tests)

Test Suite 'DeenFirstTests' passed (65+ tests)
```

### Step 2: Update RootView

**Update `Sources/RootView.swift` to include new routes:**

```swift
case .onboarding:
    OnboardingView()
case .screenTimePermission:
    ScreenTimePermissionView()
case .appSelection:
    AppSelectionView()
```

### Step 3: Build All Targets

```bash
make build
```

### Step 4: End-to-End Test on Physical Device

**Complete user flow:**
1. [ ] Launch app
2. [ ] Sign in with Apple
3. [ ] Complete 4-screen survey
4. [ ] Purchase subscription (sandbox)
5. [ ] Grant Screen Time permission
6. [ ] Select apps via FamilyActivityPicker
7. [ ] Set time limits
8. [ ] Complete setup
9. [ ] Navigate to main tabs

---

## PHASE 3 COMPLETION CHECKLIST

### Onboarding Survey
- [ ] Survey data model created
- [ ] Survey persistence working
- [ ] OnboardingViewModel implemented
- [ ] 4 survey step views created
- [ ] Can navigate forward/back/skip
- [ ] Selections persist across steps
- [ ] 12 onboarding tests passing

### Screen Time Permission
- [ ] ScreenTimePermissionViewModel implemented
- [ ] Permission request view created
- [ ] FamilyControls authorization working
- [ ] Permission granted on device
- [ ] Skip functionality working
- [ ] 1 permission test passing

### App Selection
- [ ] AppSelectionViewModel implemented
- [ ] FamilyActivityPicker integrated
- [ ] Can select multiple apps
- [ ] Time limit configuration working
- [ ] Selection persisted to App Group
- [ ] 2 app selection tests passing

### Screen Time Utils
- [ ] TimeLimit enum created
- [ ] AppGroupConstants configured
- [ ] Extension files updated with correct app group
- [ ] No old bundle ID references remain

### Integration
- [ ] All views added to RootView
- [ ] Navigation flow complete
- [ ] All tests passing (65+ tests)
- [ ] App builds successfully
- [ ] Full flow works on physical device

### Verification Commands
```bash
# All tests pass
make test

# Build succeeds
make build

# Check for old identifiers
grep -r "group.com.alexis.screentime" .
# Should return ZERO results

# Check new identifiers present
grep -r "group.com.aydev.deenfirst" .
# Should find multiple files
```

---

## TROUBLESHOOTING

### Issue: FamilyActivityPicker not appearing
**Solution:**
1. Must use physical device (doesn't work in simulator)
2. Check Screen Time permission was granted
3. Verify entitlements include family-controls
4. Check device has Screen Time enabled in Settings

### Issue: Selected apps not persisting
**Solution:**
1. Verify App Group identifier matches in all entitlements
2. Check AppGroupConstants.suiteName is correct
3. Verify extensions have app group in entitlements
4. Check UserDefaults is using correct suite name

### Issue: Tests failing
**Solution:**
1. Some tests require physical device
2. Check mock data is properly set up
3. Verify test target has access to main target
4. Run `make clean && make generate`

---

## NEXT PHASE PREVIEW

**Phase 4 will cover:**
- QuranAPIDataSource implementation
- HTTP client integration with caching
- QuranRepository with in-memory cache
- QuranService business logic
- Real API integration tests
- Fetching all 114 surahs successfully

**Prerequisites for Phase 4:**
- Phase 3 fully complete
- Onboarding flow tested end-to-end
- Screen Time permission working
- App selection functional

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 3.1 (Survey Model): 1 hour
- Task 3.2 (Onboarding ViewModel): 2 hours
- Task 3.3 (Onboarding Views): 4 hours
- Task 3.4 (Screen Time Utils): 2 hours
- Task 3.5 (Permission View): 2 hours
- Task 3.6 (App Selection): 3 hours
- **Total: 14 hours over 2 days**

**Critical milestone:** First successful shield test on device marks major progress!

---

**🎯 PHASE 3 COMPLETE! Ready for Phase 4: Quran API Integration**

Commit your work:
```bash
git add .
git commit -m "✅ Phase 3 complete: Onboarding + Screen Time + 65 tests passing"
git push
```
