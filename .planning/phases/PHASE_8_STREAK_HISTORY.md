# PHASE 8: STREAK SYSTEM + HISTORY
**Timeline:** Day 13 (Feb 15)  
**Duration:** 1 full day  
**Goal:** Polish streak display, add session history, handle all edge cases

---

## PREREQUISITES

- [ ] Phase 7 complete (Blocking and Settings functional)
- [ ] Streak logic working from Phase 6
- [ ] Sessions saving correctly
- [ ] User model has streak fields

---

## PHASE OVERVIEW

This phase enhances the user experience around streaks:
1. **Animated Streak Badge**: Visual feedback for streak changes
2. **Session History View**: Browse past sessions with grouping
3. **Comprehensive Streak Tests**: Cover all edge cases
4. **Milestone Celebrations**: Special animations for 7, 30, 100 days

**By end of Phase 8, you will have:**
- ✅ Animated streak badge on Quran tab
- ✅ Session history accessible from profile
- ✅ All streak edge cases tested
- ✅ Milestone celebrations
- ✅ 10+ edge case tests passing

---

## TASK 8.1: ANIMATED STREAK BADGE (Day 13 Morning - 2 hours)

### Step 1: Create Animated Streak Badge Component

**File: `Sources/Presentation/Components/StreakBadge.swift`**

```swift
import SwiftUI

struct StreakBadge: View {
    let currentStreak: Int
    let longestStreak: Int
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Flame icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .red.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? -5 : 5))
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // Streak count
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(currentStreak == 1 ? "day streak" : "days streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Longest streak
            if longestStreak > 0 {
                Text("Best: \(longestStreak) days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Milestone Celebration Overlay

struct MilestoneCelebration: View {
    let milestone: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Confetti animation
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(20))
                
                Text("🎉")
                    .font(.system(size: 60))
                
                VStack(spacing: 8) {
                    Text("\(milestone) Day Streak!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(milestoneMessage)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.top)
            }
            .padding()
        }
    }
    
    private var milestoneMessage: String {
        switch milestone {
        case 7:
            return "One week of consistent Quran connection! May Allah accept your efforts."
        case 30:
            return "SubhanAllah! One month of dedication. Keep going!"
        case 100:
            return "MashaAllah! 100 days of devotion. You're an inspiration!"
        default:
            return "Keep up the amazing work!"
        }
    }
}
```

### Step 2: Update QuranTabView to Show Streak Badge

**Update `Sources/Presentation/QuranTab/QuranTabView.swift`:**

```swift
struct QuranTabView: View {
    @StateObject private var viewModel: QuranTabViewModel
    @State private var showMilestoneCelebration = false
    @State private var currentMilestone = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Streak badge at top
                if let streak = viewModel.currentStreak, streak > 0 {
                    StreakBadge(
                        currentStreak: streak,
                        longestStreak: viewModel.longestStreak ?? 0
                    )
                    .padding(.vertical)
                }
                
                // Existing surah list
                // ...
            }
            .overlay {
                if showMilestoneCelebration {
                    MilestoneCelebration(
                        milestone: currentMilestone,
                        isPresented: $showMilestoneCelebration
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onChange(of: viewModel.currentStreak) { oldValue, newValue in
            checkForMilestone(oldValue: oldValue ?? 0, newValue: newValue ?? 0)
        }
    }
    
    private func checkForMilestone(oldValue: Int, newValue: Int) {
        let milestones = [7, 30, 100]
        
        for milestone in milestones {
            if oldValue < milestone && newValue >= milestone {
                currentMilestone = milestone
                withAnimation(.spring()) {
                    showMilestoneCelebration = true
                }
                break
            }
        }
    }
}
```

---

## TASK 8.2: SESSION HISTORY VIEW (Day 13 Afternoon - 3 hours)

### Step 1: Create SessionHistoryViewModel

**File: `Sources/Presentation/SessionHistory/SessionHistoryViewModel.swift`**

```swift
import SwiftUI

@MainActor
final class SessionHistoryViewModel: ObservableObject {
    @Published var groupedSessions: [DateGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let sessionRepository: SessionRepository
    private let quranService: QuranService
    
    struct DateGroup: Identifiable {
        let id = UUID()
        let date: Date
        let sessions: [SessionInfo]
        
        var dateString: String {
            let formatter = DateFormatter()
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
        }
    }
    
    struct SessionInfo: Identifiable {
        let id: UUID
        let type: Session.SessionType
        let surahNumbers: [Int]
        let duration: TimeInterval
        let createdAt: Date
        
        var durationString: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
        
        var typeIcon: String {
            switch type {
            case .reading:
                return "book.fill"
            case .listening:
                return "speaker.wave.2.fill"
            }
        }
    }
    
    init(sessionRepository: SessionRepository, quranService: QuranService) {
        self.sessionRepository = sessionRepository
        self.quranService = quranService
    }
    
    func loadSessions(userId: UUID) async {
        isLoading = true
        
        do {
            // Fetch recent sessions (last 30 days)
            let sessions = try await sessionRepository.getRecentSessions(userId: userId, limit: 100)
            
            // Group by date
            let grouped = Dictionary(grouping: sessions) { session in
                Calendar.current.startOfDay(for: session.createdAt)
            }
            
            // Convert to DateGroup array, sorted by date
            groupedSessions = grouped.map { date, sessions in
                DateGroup(
                    date: date,
                    sessions: sessions.map { session in
                        SessionInfo(
                            id: session.id,
                            type: session.type,
                            surahNumbers: session.surahNumbers,
                            duration: session.duration,
                            createdAt: session.createdAt
                        )
                    }.sorted { $0.createdAt > $1.createdAt }
                )
            }.sorted { $0.date > $1.date }
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
```

### Step 2: Create SessionHistoryView

**File: `Sources/Presentation/SessionHistory/SessionHistoryView.swift`**

```swift
import SwiftUI

struct SessionHistoryView: View {
    @StateObject private var viewModel: SessionHistoryViewModel
    @State private var userId: UUID
    
    init(userId: UUID, container: DIContainer) {
        self._userId = State(initialValue: userId)
        self._viewModel = StateObject(wrappedValue: SessionHistoryViewModel(
            sessionRepository: container.sessionRepository,
            quranService: container.quranService
        ))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.groupedSessions.isEmpty {
                emptyStateView
            } else {
                sessionsList
            }
        }
        .navigationTitle("Session History")
        .task {
            await viewModel.loadSessions(userId: userId)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first Quran session to see it here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        List {
            ForEach(viewModel.groupedSessions) { group in
                Section(header: Text(group.dateString)) {
                    ForEach(group.sessions) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: SessionHistoryViewModel.SessionInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: session.typeIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type == .reading ? "Reading" : "Listening")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(surahNamesText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.durationString)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var surahNamesText: String {
        if session.surahNumbers.count == 1 {
            return "Surah \(session.surahNumbers[0])"
        } else {
            return "\(session.surahNumbers.count) Surahs"
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.createdAt)
    }
}
```

### Step 3: Add History Link to Settings

**Update `Sources/Presentation/SettingsTab/SettingsTabView.swift`:**

Add to the list:

```swift
Section("Activity") {
    NavigationLink {
        SessionHistoryView(userId: userId, container: DIContainer.shared)
    } label: {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
            Text("Session History")
        }
    }
}
```

---

## TASK 8.3: COMPREHENSIVE STREAK TESTS (Day 13 Afternoon - 2 hours)

### Create Streak Edge Case Tests

**File: `Tests/Domain/Services/StreakEdgeCaseTests.swift`**

```swift
import XCTest
@testable import DeenFirst

final class StreakEdgeCaseTests: XCTestCase {
    var sut: SessionServiceImpl!
    var mockSessionRepo: MockSessionRepository!
    var mockUserRepo: MockUserRepository!
    
    override func setUp() {
        super.setUp()
        mockSessionRepo = MockSessionRepository()
        mockUserRepo = MockUserRepository()
        sut = SessionServiceImpl(
            sessionRepository: mockSessionRepo,
            userRepository: mockUserRepo
        )
    }
    
    // MARK: - Consecutive Days
    
    func testConsecutiveDaysIncrementsStreak() async throws {
        // Given: User with streak yesterday
        let user = createUser(streak: 5, lastDate: yesterday())
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak incremented
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 6)
    }
    
    // MARK: - Missed Days
    
    func testMissedOneDayResetsStreak() async throws {
        // Given: User with streak 2 days ago
        let user = createUser(streak: 10, lastDate: twoDaysAgo())
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak reset to 1
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 1)
    }
    
    func testMissedMultipleDaysResetsStreak() async throws {
        // Given: User with streak 7 days ago
        let user = createUser(streak: 20, lastDate: sevenDaysAgo())
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak reset to 1
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 1)
    }
    
    // MARK: - Same Day
    
    func testMultipleSessionsSameDayOnlyCountsOnce() async throws {
        // Given: User already completed session today
        let user = createUser(streak: 5, lastDate: today())
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak again
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak unchanged
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 5)
    }
    
    // MARK: - Timezone Handling
    
    func testMidnightCrossingHandledCorrectly() async throws {
        // Given: User with session at 11:59 PM yesterday
        let user = createUser(streak: 3, lastDate: yesterdayEndOfDay())
        let session = createValidSession(userId: user.id, date: todayStartOfDay())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak incremented (consecutive days)
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 4)
    }
    
    // MARK: - First Session Ever
    
    func testFirstSessionEverSetsStreakToOne() async throws {
        // Given: User with no previous streak
        let user = createUser(streak: 0, lastDate: nil)
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak is 1
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 1)
        XCTAssertEqual(updated?.longestStreak, 1)
    }
    
    // MARK: - Longest Streak
    
    func testLongestStreakUpdatesWhenCurrentExceeds() async throws {
        // Given: User with current streak = longest streak
        let user = createUser(streak: 10, lastDate: yesterday())
        user.longestStreak = 10
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Both current and longest increment
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 11)
        XCTAssertEqual(updated?.longestStreak, 11)
    }
    
    func testLongestStreakRemainsAfterReset() async throws {
        // Given: User with longest streak 50, current 20, missed days
        let user = createUser(streak: 20, lastDate: threeDaysAgo())
        user.longestStreak = 50
        let session = createValidSession(userId: user.id, date: today())
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Current resets but longest remains
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 1)
        XCTAssertEqual(updated?.longestStreak, 50)
    }
    
    // MARK: - Invalid Sessions
    
    func testInvalidSessionDoesNotUpdateStreak() async throws {
        // Given: User with streak yesterday
        let user = createUser(streak: 5, lastDate: yesterday())
        let invalidSession = Session(
            userId: user.id,
            type: .listening,
            surahNumbers: [1],
            reciterId: 7,
            duration: 90, // Only 1.5 min (invalid)
            createdAt: today()
        )
        mockUserRepo.users = [user.id: user]
        mockSessionRepo.sessions = [invalidSession]
        
        // When: Try to update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak unchanged (no valid session today)
        let updated = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updated?.currentStreak, 5)
    }
    
    // MARK: - Helper Functions
    
    private func createUser(streak: Int, lastDate: Date?) -> User {
        let user = User(appleUserId: "test", email: "test@test.com")
        user.currentStreak = streak
        user.lastStreakDate = lastDate
        return user
    }
    
    private func createValidSession(userId: UUID, date: Date) -> Session {
        Session(
            userId: userId,
            type: .listening,
            surahNumbers: [1],
            reciterId: 7,
            duration: 150, // 2.5 min (valid)
            createdAt: date
        )
    }
    
    private func today() -> Date {
        Date()
    }
    
    private func yesterday() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
    
    private func twoDaysAgo() -> Date {
        Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    }
    
    private func threeDaysAgo() -> Date {
        Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    }
    
    private func sevenDaysAgo() -> Date {
        Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    }
    
    private func yesterdayEndOfDay() -> Date {
        let yesterday = yesterday()
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!
    }
    
    private func todayStartOfDay() -> Date {
        Calendar.current.startOfDay(for: Date())
    }
}
```

---

## BUILD & VERIFY

```bash
cd ~/Projects/DeenFirst
make test

# Expected: 155+ tests passing
```

### Manual Testing

1. **Test streak badge animation:**
   - Open Quran tab
   - Verify flame animates
   - Complete a session
   - Watch for milestone celebration at 7, 30, 100 days

2. **Test session history:**
   - Navigate to Settings > Session History
   - Verify sessions grouped by date
   - Check "Today" and "Yesterday" labels
   - Verify duration and time display correctly

---

## PHASE 8 COMPLETION CHECKLIST

### Streak Badge
- [ ] Animated flame icon on Quran tab
- [ ] Shows current streak count
- [ ] Shows longest streak
- [ ] Milestone celebrations at 7, 30, 100 days
- [ ] Animation smooth and not distracting

### Session History
- [ ] Sessions grouped by date
- [ ] "Today" and "Yesterday" labels work
- [ ] Shows session type icon
- [ ] Shows duration and time
- [ ] Empty state when no sessions
- [ ] Accessible from Settings tab

### Testing
- [ ] 10+ streak edge case tests passing
- [ ] Consecutive day test passes
- [ ] Missed day test passes
- [ ] Same day test passes
- [ ] Timezone test passes
- [ ] First session test passes
- [ ] Longest streak test passes
- [ ] Invalid session test passes
- [ ] 155+ total tests passing

---

## TROUBLESHOOTING

### Issue: Milestone doesn't trigger
**Solution:**
Check onChange logic in QuranTabView, ensure comparison is correct

### Issue: History view empty but sessions exist
**Solution:**
Verify date grouping logic, check calendar timezone

---

## NEXT PHASE PREVIEW

**Phase 9: Polish + Integration Tests**
- UI consistency pass
- End-to-end integration tests
- Performance optimization
- Final bug fixes

---

**🎯 PHASE 8 COMPLETE!**

```bash
git add .
git commit -m "✅ Phase 8: Streak system + History + 155 tests"
git push
```
