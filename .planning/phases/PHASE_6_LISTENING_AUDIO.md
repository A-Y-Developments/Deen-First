# PHASE 6: LISTENING SESSIONS + AUDIO PLAYER
**Timeline:** Days 10-11 (Feb 12-13)  
**Duration:** 2 full days  
**Goal:** Complete audio playback system with background support, session tracking, and shield application during listening

---

## PREREQUISITES

- [ ] Phase 5 complete (Main tabs functional, Quran API working)
- [ ] Physical iOS 17+ device ready (Screen Time features require real device)
- [ ] Mindcore project accessible at `/Users/adithyafp_/Projects/mindcore`
- [ ] Audio test files or streaming URLs ready
- [ ] Background audio capability enabled in Xcode

---

## PHASE OVERVIEW

This phase builds the core listening experience:
1. **AudioPlayerService**: Background playback with lock screen controls
2. **SessionRepository**: CRUD operations for session tracking
3. **SessionService**: Business logic for streaks and preferences
4. **ListenSessionView**: Full listening UI with shield application

**By end of Phase 6, you will have:**
- ✅ Audio plays in background
- ✅ Lock screen controls working
- ✅ Sessions tracked with duration
- ✅ Streak increments after valid sessions (2+ min)
- ✅ Shields apply during listening
- ✅ Shields removed after session ends
- ✅ 20+ critical tests passing

---

## TASK 6.1: AUDIO PLAYER SERVICE (Day 10 Morning - 3 hours)

### Step 1: Add Background Audio Capability

**Update `Project.swift` (Tuist):**

Add to SurahFocus target's infoPlist:

```swift
"UIBackgroundModes": ["audio"]
```

### Step 2: Create AudioPlayerService Protocol

**File: `Sources/Domain/Services/AudioPlayerService.swift`**

```swift
import Foundation
import AVFoundation
import Combine

protocol AudioPlayerService {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    
    func play(url: URL) async throws
    func pause()
    func resume()
    func stop()
    func seek(to time: TimeInterval)
}

final class AudioPlayerServiceImpl: NSObject, AudioPlayerService {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    
    var isPlaying: Bool {
        player?.rate != 0
    }
    
    var currentTime: TimeInterval {
        player?.currentTime().seconds ?? 0
    }
    
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteControls()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Set category to .playback for background audio
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Lock Screen Controls
    
    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Disable next/previous (not needed for Quran player)
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
    }
    
    // MARK: - Playback Control
    
    func play(url: URL) async throws {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Add time observer for progress tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTimeSubject.send(time.seconds)
        }
        
        player?.play()
        updateNowPlaying(title: "Quran Recitation")
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
    
    func stop() {
        player?.pause()
        player = nil
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        currentTimeSubject.send(0)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    // MARK: - Lock Screen Metadata
    
    private func updateNowPlaying(title: String) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Surah Focus"
        
        if let duration = player?.currentItem?.duration.seconds,
           !duration.isNaN && !duration.isInfinite {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
```

**Key Points:**
- Uses `AVAudioSession.Category.playback` for background audio
- `MPRemoteCommandCenter` for lock screen controls
- `MPNowPlayingInfoCenter` for metadata display
- Time observer publishes current playback time via Combine

---

## TASK 6.2: SESSION REPOSITORY (Day 10 Afternoon - 2 hours)

### Step 1: Create Session Repository

**File: `Sources/Data/Repositories/SessionRepository.swift`**

```swift
import Foundation
import SwiftData

protocol SessionRepository {
    func createSession(userId: UUID, type: Session.SessionType, surahNumbers: [Int], reciterId: Int) async throws -> Session
    func updateSession(_ session: Session, duration: TimeInterval) async throws
    func getRecentSessions(userId: UUID, limit: Int) async throws -> [Session]
    func getTodaySessions(userId: UUID) async throws -> [Session]
}

final class SessionRepositoryImpl: SessionRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createSession(userId: UUID, type: Session.SessionType, surahNumbers: [Int], reciterId: Int) async throws -> Session {
        let session = Session(
            userId: userId,
            type: type,
            surahNumbers: surahNumbers,
            reciterId: reciterId,
            duration: 0,
            createdAt: Date()
        )
        
        modelContext.insert(session)
        try modelContext.save()
        
        return session
    }
    
    func updateSession(_ session: Session, duration: TimeInterval) async throws {
        session.duration = duration
        session.updatedAt = Date()
        try modelContext.save()
    }
    
    func getRecentSessions(userId: UUID, limit: Int) async throws -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let allSessions = try modelContext.fetch(descriptor)
        return Array(allSessions.prefix(limit))
    }
    
    func getTodaySessions(userId: UUID) async throws -> [Session] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { 
                $0.userId == userId && $0.createdAt >= startOfDay 
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
}
```

**Reference:** Similar to Mindcore's session tracking in `mindcore/Sources/Data/Repositories/SessionRepository.swift`

---

## TASK 6.3: SESSION SERVICE (Day 10 Afternoon - 2 hours)

### Step 1: Create Session Service

**File: `Sources/Domain/Services/SessionService.swift`**

```swift
import Foundation

protocol SessionService {
    func startSession(userId: UUID, type: Session.SessionType, surahNumbers: [Int], reciterId: Int) async throws -> Session
    func endSession(_ session: Session, duration: TimeInterval) async throws
    func updateStreak(userId: UUID) async throws
    func saveListeningPreference(userId: UUID, reciterId: Int, surahNumbers: [Int]) async throws
}

final class SessionServiceImpl: SessionService {
    private let sessionRepository: SessionRepository
    private let userRepository: UserRepository
    
    init(sessionRepository: SessionRepository, userRepository: UserRepository) {
        self.sessionRepository = sessionRepository
        self.userRepository = userRepository
    }
    
    func startSession(userId: UUID, type: Session.SessionType, surahNumbers: [Int], reciterId: Int) async throws -> Session {
        // Create session record
        return try await sessionRepository.createSession(
            userId: userId,
            type: type,
            surahNumbers: surahNumbers,
            reciterId: reciterId
        )
    }
    
    func endSession(_ session: Session, duration: TimeInterval) async throws {
        // Update session duration
        try await sessionRepository.updateSession(session, duration: duration)
        
        // Only update streak if session is valid (2+ minutes)
        if session.isValid {
            try await updateStreak(userId: session.userId)
        }
    }
    
    func updateStreak(userId: UUID) async throws {
        guard let user = try await userRepository.getUser(id: userId) else {
            throw SessionError.userNotFound
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if user already completed a session today
        let todaySessions = try await sessionRepository.getTodaySessions(userId: userId)
        let validSessionsToday = todaySessions.filter { $0.isValid }
        
        guard !validSessionsToday.isEmpty else {
            return // No valid session today, don't update streak
        }
        
        // Get last streak date
        if let lastStreakDate = user.lastStreakDate {
            let lastStreakDay = calendar.startOfDay(for: lastStreakDate)
            let daysDiff = calendar.dateComponents([.day], from: lastStreakDay, to: today).day ?? 0
            
            if daysDiff == 0 {
                // Already counted today, do nothing
                return
            } else if daysDiff == 1 {
                // Consecutive day, increment streak
                user.currentStreak += 1
                user.lastStreakDate = Date()
                
                if user.currentStreak > user.longestStreak {
                    user.longestStreak = user.currentStreak
                }
            } else {
                // Missed days, reset streak
                user.currentStreak = 1
                user.lastStreakDate = Date()
            }
        } else {
            // First ever session
            user.currentStreak = 1
            user.longestStreak = 1
            user.lastStreakDate = Date()
        }
        
        try await userRepository.updateUser(user)
    }
    
    func saveListeningPreference(userId: UUID, reciterId: Int, surahNumbers: [Int]) async throws {
        // Save last used reciter and surahs to UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.aydev.surahfocus")
        defaults?.set(reciterId, forKey: "lastReciterId")
        defaults?.set(surahNumbers, forKey: "lastSurahNumbers")
    }
}

enum SessionError: LocalizedError {
    case userNotFound
    case invalidDuration
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidDuration:
            return "Session duration must be at least 2 minutes"
        }
    }
}
```

**Key Logic:**
- Only valid sessions (2+ min) count toward streak
- Consecutive day check: if last streak date was yesterday, increment
- Missed days: reset streak to 1
- Same day: don't increment again

**Reference:** Mindcore's streak logic in `mindcore/Sources/Domain/Services/StreakService.swift`

---

## TASK 6.4: LISTEN SESSION VIEW (Day 11 - 5 hours)

### Step 1: Create ListenSessionViewModel

**File: `Sources/Presentation/ListenSession/ListenSessionViewModel.swift`**

```swift
import SwiftUI
import Combine

@MainActor
final class ListenSessionViewModel: ObservableObject {
    // MARK: - Published State
    @Published var selectedSurahs: Set<Int> = []
    @Published var selectedReciter: Int = 7 // Default: Mishary Alafasy
    @Published var isPlaying = false
    @Published var sessionDuration: TimeInterval = 0
    @Published var currentAudioTime: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // MARK: - Dependencies
    private let audioService: AudioPlayerService
    private let sessionService: SessionService
    private let screenTimeService: ScreenTimeService
    private let quranService: QuranService
    private var session: Session?
    private var sessionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        audioService: AudioPlayerService,
        sessionService: SessionService,
        screenTimeService: ScreenTimeService,
        quranService: QuranService
    ) {
        self.audioService = audioService
        self.sessionService = sessionService
        self.screenTimeService = screenTimeService
        self.quranService = quranService
        
        setupAudioTimeObserver()
    }
    
    // MARK: - Audio Time Observer
    
    private func setupAudioTimeObserver() {
        audioService.currentTimePublisher
            .sink { [weak self] time in
                self?.currentAudioTime = time
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Session Control
    
    func startSession(userId: UUID) async {
        guard !selectedSurahs.isEmpty else {
            errorMessage = "Please select at least one surah"
            return
        }
        
        isLoading = true
        
        do {
            // 1. Create session record
            session = try await sessionService.startSession(
                userId: userId,
                type: .listening,
                surahNumbers: Array(selectedSurahs).sorted(),
                reciterId: selectedReciter
            )
            
            // 2. Apply Screen Time shields
            try await screenTimeService.applyShields()
            
            // 3. Get audio URL for first surah
            let audioURL = try await getAudioURL(for: Array(selectedSurahs).sorted().first!)
            
            // 4. Start audio playback
            try await audioService.play(url: audioURL)
            
            // 5. Start session timer
            sessionStartTime = Date()
            isPlaying = true
            
            // 6. Save preferences
            try await sessionService.saveListeningPreference(
                userId: userId,
                reciterId: selectedReciter,
                surahNumbers: Array(selectedSurahs)
            )
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func endSession(userId: UUID) async {
        guard let session = session, let startTime = sessionStartTime else {
            return
        }
        
        isLoading = true
        
        do {
            // 1. Calculate duration
            let duration = Date().timeIntervalSince(startTime)
            
            // 2. Stop audio
            audioService.stop()
            
            // 3. Save session duration
            try await sessionService.endSession(session, duration: duration)
            
            // 4. Remove shields
            try await screenTimeService.removeShields()
            
            // 5. Reset state
            isPlaying = false
            sessionDuration = duration
            self.session = nil
            sessionStartTime = nil
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func togglePlayPause() {
        if audioService.isPlaying {
            audioService.pause()
        } else {
            audioService.resume()
        }
    }
    
    // MARK: - Helpers
    
    private func getAudioURL(for surahNumber: Int) async throws -> URL {
        let surah = try await quranService.getSurah(number: surahNumber)
        
        // Get audio URL from Quran API based on reciter
        // Example: https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3
        let baseURL = "https://cdn.islamic.network/quran/audio/128"
        let reciterSlug = getReciterSlug(for: selectedReciter)
        let urlString = "\(baseURL)/\(reciterSlug)/\(surahNumber).mp3"
        
        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }
        
        return url
    }
    
    private func getReciterSlug(for reciterId: Int) -> String {
        // Map reciter IDs to API slugs
        // Reference: https://alquran.cloud/api
        switch reciterId {
        case 7: return "ar.alafasy"
        case 2: return "ar.abdurrahmaansudais"
        case 3: return "ar.abdulbasitmurattal"
        case 4: return "ar.shaatree"
        default: return "ar.alafasy"
        }
    }
    
    var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum AudioError: LocalizedError {
    case invalidURL
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .playbackFailed:
            return "Failed to play audio"
        }
    }
}
```

### Step 2: Create ListenSessionView

**File: `Sources/Presentation/ListenSession/ListenSessionView.swift`**

```swift
import SwiftUI

struct ListenSessionView: View {
    @StateObject private var viewModel: ListenSessionViewModel
    @EnvironmentObject private var router: Router
    @State private var userId: UUID
    
    init(userId: UUID, container: DIContainer) {
        self._userId = State(initialValue: userId)
        self._viewModel = StateObject(wrappedValue: ListenSessionViewModel(
            audioService: container.audioService,
            sessionService: container.sessionService,
            screenTimeService: container.screenTimeService,
            quranService: container.quranService
        ))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isPlaying {
                // Active session view
                activeSessionView
            } else {
                // Setup view
                setupView
            }
        }
        .padding()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .navigationTitle("Listen to Quran")
    }
    
    // MARK: - Setup View
    
    private var setupView: some View {
        VStack(spacing: 32) {
            // Surah selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Surahs")
                    .font(.headline)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(1...114, id: \.self) { number in
                            surahRow(number: number)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            // Reciter picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Reciter")
                    .font(.headline)
                
                Picker("Reciter", selection: $viewModel.selectedReciter) {
                    Text("Mishary Alafasy").tag(7)
                    Text("Abdul Rahman Al-Sudais").tag(2)
                    Text("Abdul Basit").tag(3)
                    Text("Sa'ad Al-Ghamidi").tag(4)
                }
                .pickerStyle(.menu)
            }
            
            Spacer()
            
            // Start button
            Button(action: {
                Task {
                    await viewModel.startSession(userId: userId)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Listening")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(viewModel.selectedSurahs.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(viewModel.selectedSurahs.isEmpty || viewModel.isLoading)
        }
    }
    
    // MARK: - Active Session View
    
    private var activeSessionView: some View {
        VStack(spacing: 32) {
            // Selected surahs
            VStack(alignment: .leading, spacing: 8) {
                Text("Now Playing")
                    .font(.headline)
                
                Text(selectedSurahNames)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress indicator
            VStack(spacing: 8) {
                ProgressView(value: viewModel.currentAudioTime, total: 100)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text(formatTime(viewModel.currentAudioTime))
                    Spacer()
                    Text(viewModel.formattedDuration)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Play/Pause button
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // End session button
            Button(action: {
                Task {
                    await viewModel.endSession(userId: userId)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("End Session")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Helper Views
    
    private func surahRow(number: Int) -> some View {
        Button(action: {
            if viewModel.selectedSurahs.contains(number) {
                viewModel.selectedSurahs.remove(number)
            } else {
                viewModel.selectedSurahs.insert(number)
            }
        }) {
            HStack {
                Text("Surah \(number)")
                    .font(.body)
                
                Spacer()
                
                if viewModel.selectedSurahs.contains(number) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(viewModel.selectedSurahs.contains(number) ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
    
    private var selectedSurahNames: String {
        let sorted = Array(viewModel.selectedSurahs).sorted()
        return sorted.map { "Surah \($0)" }.joined(separator: ", ")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

**Reference:** Mindcore's session UI in `mindcore/Sources/Presentation/Sessions/SessionView.swift`

---

## TASK 6.5: REGISTER DEPENDENCIES (Day 11 - 30 min)

**Update `Sources/Core/DIContainer.swift`:**

```swift
final class DIContainer {
    static let shared = DIContainer()
    
    // ... existing services
    
    // MARK: - Phase 6 Services
    
    lazy var audioService: AudioPlayerService = {
        AudioPlayerServiceImpl()
    }()
    
    lazy var sessionRepository: SessionRepository = {
        SessionRepositoryImpl(modelContext: modelContext)
    }()
    
    lazy var sessionService: SessionService = {
        SessionServiceImpl(
            sessionRepository: sessionRepository,
            userRepository: userRepository
        )
    }()
}
```

---

## TESTING PHASE 6

### Test 6.1: AudioPlayerServiceTests

**File: `Tests/Domain/Services/AudioPlayerServiceTests.swift`**

```swift
import XCTest
@testable import SurahFocus

final class AudioPlayerServiceTests: XCTestCase {
    var sut: AudioPlayerServiceImpl!
    
    override func setUp() {
        super.setUp()
        sut = AudioPlayerServiceImpl()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialization() {
        // Given: Fresh service
        // When: Initialized
        // Then: Should not be playing
        XCTAssertFalse(sut.isPlaying)
        XCTAssertEqual(sut.currentTime, 0)
    }
    
    func testPlayStartsAudio() async throws {
        // Given: Valid audio URL
        let url = URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3")!
        
        // When: Play audio
        try await sut.play(url: url)
        
        // Then: Should be playing
        try await Task.sleep(for: .seconds(1))
        XCTAssertTrue(sut.isPlaying)
        
        // Cleanup
        sut.stop()
    }
    
    func testPauseStopsAudio() async throws {
        // Given: Playing audio
        let url = URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3")!
        try await sut.play(url: url)
        try await Task.sleep(for: .seconds(1))
        
        // When: Pause
        sut.pause()
        
        // Then: Should not be playing
        XCTAssertFalse(sut.isPlaying)
        
        // Cleanup
        sut.stop()
    }
    
    func testResumeRestartsAudio() async throws {
        // Given: Paused audio
        let url = URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3")!
        try await sut.play(url: url)
        try await Task.sleep(for: .seconds(1))
        sut.pause()
        
        // When: Resume
        sut.resume()
        
        // Then: Should be playing
        try await Task.sleep(for: .seconds(0.5))
        XCTAssertTrue(sut.isPlaying)
        
        // Cleanup
        sut.stop()
    }
    
    func testStopClearsPlayer() async throws {
        // Given: Playing audio
        let url = URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3")!
        try await sut.play(url: url)
        try await Task.sleep(for: .seconds(1))
        
        // When: Stop
        sut.stop()
        
        // Then: Should reset state
        XCTAssertFalse(sut.isPlaying)
        XCTAssertEqual(sut.currentTime, 0)
    }
}
```

### Test 6.2: SessionServiceTests

**File: `Tests/Domain/Services/SessionServiceTests.swift`**

```swift
import XCTest
@testable import SurahFocus

final class SessionServiceTests: XCTestCase {
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
    
    func testStartSessionCreatesRecord() async throws {
        // Given: User ID and session details
        let userId = UUID()
        
        // When: Start session
        let session = try await sut.startSession(
            userId: userId,
            type: .listening,
            surahNumbers: [1, 2, 3],
            reciterId: 7
        )
        
        // Then: Session created
        XCTAssertEqual(session.userId, userId)
        XCTAssertEqual(session.type, .listening)
        XCTAssertEqual(session.surahNumbers, [1, 2, 3])
    }
    
    func testEndSessionUpdatesStreak() async throws {
        // Given: Valid session (2+ min)
        let userId = UUID()
        let user = User(appleUserId: "test", email: "test@test.com")
        mockUserRepo.users = [user.id: user]
        
        let session = Session(
            userId: user.id,
            type: .listening,
            surahNumbers: [1],
            reciterId: 7,
            duration: 0,
            createdAt: Date()
        )
        
        // When: End session with valid duration
        try await sut.endSession(session, duration: 150) // 2.5 min
        
        // Then: Streak incremented
        let updatedUser = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updatedUser?.currentStreak, 1)
    }
    
    func testInvalidDurationDoesntUpdateStreak() async throws {
        // Given: Invalid session (<2 min)
        let userId = UUID()
        let user = User(appleUserId: "test", email: "test@test.com")
        mockUserRepo.users = [user.id: user]
        
        let session = Session(
            userId: user.id,
            type: .listening,
            surahNumbers: [1],
            reciterId: 7,
            duration: 0,
            createdAt: Date()
        )
        
        // When: End session with invalid duration
        try await sut.endSession(session, duration: 90) // 1.5 min
        
        // Then: Streak not incremented
        let updatedUser = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updatedUser?.currentStreak, 0)
    }
    
    func testConsecutiveDayIncrementsStreak() async throws {
        // Given: User with streak from yesterday
        let user = User(appleUserId: "test", email: "test@test.com")
        user.currentStreak = 5
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        user.lastStreakDate = yesterday
        mockUserRepo.users = [user.id: user]
        
        // Create valid session today
        let session = Session(
            userId: user.id,
            type: .listening,
            surahNumbers: [1],
            reciterId: 7,
            duration: 150,
            createdAt: Date()
        )
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak incremented
        let updatedUser = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updatedUser?.currentStreak, 6)
    }
    
    func testMissedDayResetsStreak() async throws {
        // Given: User with streak from 3 days ago
        let user = User(appleUserId: "test", email: "test@test.com")
        user.currentStreak = 10
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        user.lastStreakDate = threeDaysAgo
        mockUserRepo.users = [user.id: user]
        
        // Create valid session today
        let session = Session(
            userId: user.id,
            type: .listening,
            surahNumbers: [1],
            reciterId: 7,
            duration: 150,
            createdAt: Date()
        )
        mockSessionRepo.sessions = [session]
        
        // When: Update streak
        try await sut.updateStreak(userId: user.id)
        
        // Then: Streak reset to 1
        let updatedUser = try await mockUserRepo.getUser(id: user.id)
        XCTAssertEqual(updatedUser?.currentStreak, 1)
    }
}

// MARK: - Mock Repositories

final class MockSessionRepository: SessionRepository {
    var sessions: [Session] = []
    
    func createSession(userId: UUID, type: Session.SessionType, surahNumbers: [Int], reciterId: Int) async throws -> Session {
        let session = Session(
            userId: userId,
            type: type,
            surahNumbers: surahNumbers,
            reciterId: reciterId,
            duration: 0,
            createdAt: Date()
        )
        sessions.append(session)
        return session
    }
    
    func updateSession(_ session: Session, duration: TimeInterval) async throws {
        session.duration = duration
    }
    
    func getRecentSessions(userId: UUID, limit: Int) async throws -> [Session] {
        return Array(sessions.filter { $0.userId == userId }.prefix(limit))
    }
    
    func getTodaySessions(userId: UUID) async throws -> [Session] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.userId == userId && $0.createdAt >= startOfDay }
    }
}

final class MockUserRepository: UserRepository {
    var users: [UUID: User] = [:]
    
    func getUser(id: UUID) async throws -> User? {
        return users[id]
    }
    
    func updateUser(_ user: User) async throws {
        users[user.id] = user
    }
    
    // ... other required methods
}
```

---

## BUILD & VERIFY

### Step 1: Run All Tests

```bash
# Navigate to project
cd ~/Projects/SurahFocus

# Run tests
make test

# Expected output:
# ✓ AudioPlayerServiceTests (5 tests)
# ✓ SessionServiceTests (6 tests)
# ✓ Total: 125+ tests passing
```

### Step 2: Manual Testing on Device

**CRITICAL:** Audio and Screen Time require physical device.

1. **Build and run on device:**
   ```bash
   # In Xcode:
   # 1. Select your physical device
   # 2. Cmd+R to build and run
   ```

2. **Test listening session:**
   - Navigate to "Listen" tab
   - Select a surah (e.g., Al-Fatihah)
   - Select reciter
   - Tap "Start Listening"
   - Verify audio plays
   - Lock device
   - Check lock screen shows audio controls
   - Play/pause from lock screen
   - Return to app
   - Tap "End Session"
   - Verify duration saved

3. **Test streak update:**
   - Complete a valid session (2+ min)
   - Check Quran tab shows streak badge incremented
   - Complete another session same day
   - Verify streak doesn't increment twice

---

## PHASE 6 COMPLETION CHECKLIST

### Audio Player
- [ ] AudioPlayerService implemented
- [ ] Background audio works (test with device locked)
- [ ] Lock screen controls appear
- [ ] Play/pause from lock screen works
- [ ] Audio continues when switching apps
- [ ] Stop clears player state

### Session Tracking
- [ ] SessionRepository CRUD operations work
- [ ] Sessions save with correct duration
- [ ] Can fetch recent sessions
- [ ] Can fetch today's sessions

### Session Service
- [ ] Start session creates record
- [ ] End session updates duration
- [ ] Valid sessions (2+ min) update streak
- [ ] Invalid sessions (<2 min) don't update streak
- [ ] Consecutive day increments streak
- [ ] Missed days reset streak
- [ ] Same day doesn't increment twice

### Listen Session UI
- [ ] Can select multiple surahs
- [ ] Can select reciter
- [ ] Start button disabled when no surahs selected
- [ ] Audio plays when session starts
- [ ] Shields apply during session
- [ ] Timer shows session duration
- [ ] Play/pause button works
- [ ] End session stops audio
- [ ] Shields removed after session ends

### Testing
- [ ] 5+ audio player tests passing
- [ ] 6+ session service tests passing
- [ ] 125+ total tests passing
- [ ] Manual testing completed on device

### Verification Commands
```bash
# All tests pass
make test

# Build succeeds
make build

# No warnings
xcodebuild build -scheme SurahFocus | grep warning
# Should return: 0 results
```

---

## TROUBLESHOOTING

### Issue: Audio doesn't play in background
**Solution:**
1. Check Info.plist has `UIBackgroundModes: ["audio"]`
2. Verify AVAudioSession category is `.playback`
3. Test on physical device (simulator doesn't support background audio fully)

### Issue: Lock screen controls don't appear
**Solution:**
1. Check MPRemoteCommandCenter is setup in init
2. Verify MPNowPlayingInfoCenter is updated with metadata
3. Ensure audio is actually playing (not just prepared)

### Issue: Shields don't apply during session
**Solution:**
1. Check ScreenTimeService.applyShields() is called
2. Verify Phase 3 extensions are working correctly
3. Test on physical device (required for Screen Time)
4. Check App Group identifier is correct

### Issue: Streak not updating
**Solution:**
1. Verify session.isValid returns true (duration >= 120 seconds)
2. Check User.lastStreakDate is being updated
3. Verify getTodaySessions() returns valid sessions
4. Debug streak logic with print statements

### Issue: Tests fail with "No such module AVFoundation"
**Solution:**
1. Ensure test target has dependency on main target
2. Check `@testable import SurahFocus` is present
3. Run `make clean && make generate`

---

## NEXT PHASE PREVIEW

**Phase 7 will cover:**
- Complete BlockingTab implementation
- ScreenTime repository full functionality
- Settings tab with profile and subscription
- App management (edit limits, remove apps)

**Prerequisites for Phase 7:**
- Phase 6 fully complete
- Shield application working from Phase 6
- User can see blocked apps list
- Subscription status available from Phase 2

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 6.1 (Audio Player): 3 hours
- Task 6.2 (Session Repository): 2 hours
- Task 6.3 (Session Service): 2 hours
- Task 6.4 (Listen Session View): 5 hours
- Task 6.5 (Dependencies): 0.5 hours
- Testing: 2 hours
- **Total: 14.5 hours over 2 days**

**Track your actual time:**
- Day 10 actual: _____ hours
- Day 11 actual: _____ hours

---

**🎯 PHASE 6 COMPLETE! Ready for Phase 7: Blocking + Settings Tabs**

Commit your work:
```bash
git add .
git commit -m "✅ Phase 6: Listening sessions + Audio player + 125 tests"
git push
```
