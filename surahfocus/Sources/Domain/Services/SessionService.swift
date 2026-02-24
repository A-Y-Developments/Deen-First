import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

// MARK: - Session Repository (unchanged)

protocol SessionRepository {
    func save(_ session: Session) async throws
    func getActiveSessions() async throws -> [Session]
    func updateSession(_ session: Session) async throws
    func getSessions(for userId: UUID, startDate: Date, endDate: Date) async throws -> [Session]
    func getTodaySession(for userId: UUID) async throws -> Session?
}

final class SessionRepositoryImpl: SessionRepository {
    let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func save(_ session: Session) async throws {
        try await localDataSource.insertSession(session)
    }

    func getActiveSessions() async throws -> [Session] {
        return try await localDataSource.fetchSessions(predicate: { $0.isCompleted == false })
    }

    func updateSession(_ session: Session) async throws {
        try await localDataSource.updateSession(session)
    }

    func getSessions(for userId: UUID, startDate: Date, endDate: Date) async throws -> [Session] {
        return try await localDataSource.fetchSessions(predicate: {
            $0.userId == userId && $0.startTime >= startDate && $0.startTime <= endDate
        })
    }

    func getTodaySession(for userId: UUID) async throws -> Session? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let sessions = try await getSessions(for: userId, startDate: today, endDate: tomorrow)
        return sessions.first
    }
}

// MARK: - Session Service Protocol

protocol SessionService {
    func startSession(type: Session.SessionType, surahNumbers: [Int], reciterId: Int?) async throws -> Session
    func endSession(_ session: Session, durationSeconds: Int) async throws
    func getTodaySession(for userId: UUID) async throws -> Session?
    func updateStreak(for userId: UUID) async throws
    func checkAndResetStreakIfNeeded() async throws
    func cleanupOrphanedSessions() async  // ← ADD
}

// MARK: - Session Service Errors

enum SessionServiceError: LocalizedError {
    case noUser
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noUser:    return "User not found"
        case .saveFailed: return "Failed to save session"
        }
    }
}

// MARK: - Session Service Implementation

final class SessionServiceImpl: SessionService {
    let sessionRepository: SessionRepository
    let userRepository: UserRepository
    let screenTimeRulesService: ScreenTimeRulesService

    init(
        sessionRepository: SessionRepository,
        userRepository: UserRepository,
        screenTimeRulesService: ScreenTimeRulesService
    ) {
        self.sessionRepository = sessionRepository
        self.userRepository = userRepository
        self.screenTimeRulesService = screenTimeRulesService
    }

    // MARK: - Start Session

    func startSession(
        type: Session.SessionType,
        surahNumbers: [Int],
        reciterId: Int? = nil
    ) async throws -> Session {
        guard let user = try await userRepository.getCurrentUser() else {
            throw SessionServiceError.noUser
        }

        if type == .listening {
            await applySessionShields()
        }

        let session = Session(
            userId: user.id,
            type: type,
            surahNumbers: surahNumbers,
            reciterId: reciterId
        )

        try await sessionRepository.save(session)

        UserDefaults.standard.set(surahNumbers, forKey: "lastSelectedSurahs")
        if let reciterId = reciterId {
            UserDefaults.standard.set(reciterId, forKey: "lastReciterId")
        }

        try await updateStreak(for: user.id)

        return session
    }

    // MARK: - End Session

    func endSession(_ session: Session, durationSeconds: Int) async throws {
        session.endTime = Date()
        session.durationSeconds = durationSeconds
        session.isCompleted = true

        if session.type == .listening {
            await removeSessionShields()
        }

        try await sessionRepository.updateSession(session)
    }

    // MARK: - Queries

    func getTodaySession(for userId: UUID) async throws -> Session? {
        return try await sessionRepository.getTodaySession(for: userId)
    }

    // MARK: - Streak

    func updateStreak(for userId: UUID) async throws {
        print("🔥 updateStreak: Starting for userId \(userId)")
        guard let user = try await userRepository.getCurrentUser() else {
            print("⚠️ updateStreak: No user found for id \(userId)")
            throw SessionServiceError.noUser
        }

        let today = Calendar.current.startOfDay(for: Date())
        let lastActiveDay = user.lastActiveDate.map { Calendar.current.startOfDay(for: $0) }
        print("📅 updateStreak: today=\(today), lastActiveDay=\(String(describing: lastActiveDay)), currentStreak=\(user.currentStreak)")

        if let lastActive = lastActiveDay {
            let daysDiff = Calendar.current.dateComponents([.day], from: lastActive, to: today).day ?? 0

            if daysDiff == 0 {
                return
            } else if daysDiff == 1 {
                user.currentStreak += 1
                if user.currentStreak > user.longestStreak {
                    user.longestStreak = user.currentStreak
                }
            } else {
                user.currentStreak = 1
            }
        } else {
            user.currentStreak = 1
            user.longestStreak = 1
        }

        user.lastActiveDate = Date()
        print("💾 updateStreak: Saving user with currentStreak=\(user.currentStreak), longestStreak=\(user.longestStreak)")
        try await userRepository.updateUser(user)

        UserPersistenceHelper.saveStreaks(
            current: user.currentStreak,
            longest: user.longestStreak,
            userId: user.appleUserId
        )
        UserPersistenceHelper.saveLastActiveDate(user.lastActiveDate!, userId: user.appleUserId)
        print("✅ updateStreak: Completed. Streak updated to \(user.currentStreak)")
    }

    // MARK: - Session Shield Management

    private func applySessionShields() async {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            print("⚠️ Could not access AppGroup defaults")
            return
        }

        var selection = FamilyActivitySelection()

        if let tokenMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data] {
            for (_, data) in tokenMapping {
                if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                    selection.applicationTokens.insert(token)
                }
            }
        }

        if let categoryMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] {
            for (_, data) in categoryMapping {
                if let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                    selection.categoryTokens.insert(token)
                }
            }
        }

        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            print("⚠️ No saved app selection found for session shield")
            return
        }

        // FIX: Set session active flag BEFORE applying shields.
        // This ensures that if reapplyActiveShields is called by another code path
        // while the session is active, it will correctly include the session tokens.
        AppGroupConstants.sharedDefaults?.set(true, forKey: AppGroupConstants.isSessionActiveKey)

        await screenTimeRulesService.applySessionShield(for: selection)
        print("✅ Session shields applied")
    }

    private func removeSessionShields() async {
        await screenTimeRulesService.removeSessionShield()
        print("✅ Session ended — shields restored to rule-based state")
    }

    // MARK: - Streak Check

    func checkAndResetStreakIfNeeded() async throws {
        guard let user = try await userRepository.getCurrentUser() else { return }

        guard let lastActive = user.lastActiveDate else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastActiveDay = Calendar.current.startOfDay(for: lastActive)
        let daysDiff = Calendar.current.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

        if daysDiff > 1 {
            user.currentStreak = 1
            try await userRepository.updateUser(user)
            UserPersistenceHelper.saveStreaks(current: 1, longest: user.longestStreak, userId: user.appleUserId)
            print("🔄 Streak reset to 1 (missed \(daysDiff) days)")
        }
    }

    // MARK: - Orphaned Session Cleanup

    /// Called on app launch and foreground to recover from force-kill during an active session.
    ///
    /// When the app is force-killed mid-session:
    ///   - `endSession()` was never called
    ///   - `isSessionActiveKey` is stuck `true` in UserDefaults
    ///   - The Session record in SwiftData has `isCompleted = false`
    ///   - `reapplyActiveShields` keeps re-applying session tokens on every relaunch
    ///
    /// Since the audio queue is gone from memory, the session cannot be resumed.
    /// This method silently marks all incomplete sessions as ended and restores
    /// the shield state to rules-only (no session tokens).
    func cleanupOrphanedSessions() async {
        do {
            let orphans = try await sessionRepository.getActiveSessions()
            guard !orphans.isEmpty else { return }

            for session in orphans {
                let elapsed = Int(Date().timeIntervalSince(session.startTime))
                session.endTime = Date()
                session.durationSeconds = max(elapsed, 0)
                session.isCompleted = true
                try await sessionRepository.updateSession(session)
                print("🧹 Cleaned up orphaned session: \(session.id), elapsed: \(elapsed)s")
            }

            // Clear session active flag so reapplyActiveShields stops including session tokens
            AppGroupConstants.sharedDefaults?.set(false, forKey: AppGroupConstants.isSessionActiveKey)

            // Restore shields to rules-only state
            await screenTimeRulesService.reapplyActiveShields()

            print("✅ Orphaned session cleanup complete — shields restored to rule-based state")
        } catch {
            print("⚠️ Failed to cleanup orphaned sessions: \(error)")
        }
    }
}