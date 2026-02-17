import Foundation
import SwiftData
import ManagedSettings
import FamilyControls

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
            $0.userId == userId &&
            $0.startTime >= startDate &&
            $0.startTime <= endDate
        })
    }

    func getTodaySession(for userId: UUID) async throws -> Session? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let sessions = try await getSessions(for: userId, startDate: today, endDate: tomorrow)
        return sessions.first
    }
}

protocol SessionService {
    func startSession(type: Session.SessionType, surahNumbers: [Int], reciterId: Int?) async throws -> Session
    func endSession(_ session: Session, durationSeconds: Int) async throws
    func getTodaySession(for userId: UUID) async throws -> Session?
    func updateStreak(for userId: UUID) async throws
}

enum SessionServiceError: LocalizedError {
    case noUser
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noUser: return "User not found"
        case .saveFailed: return "Failed to save session"
        }
    }
}

final class SessionServiceImpl: SessionService {
    let sessionRepository: SessionRepository
    let userRepository: UserRepository
    let screenTimeRulesUseCase: ScreenTimeRulesUseCase

    init(sessionRepository: SessionRepository, userRepository: UserRepository, screenTimeRulesUseCase: ScreenTimeRulesUseCase) {
        self.sessionRepository = sessionRepository
        self.userRepository = userRepository
        self.screenTimeRulesUseCase = screenTimeRulesUseCase
    }


    func startSession(type: Session.SessionType, surahNumbers: [Int], reciterId: Int? = nil) async throws -> Session {
        guard let user = try await userRepository.getCurrentUser() else {
            throw SessionServiceError.noUser
        }

        // Apply shields for listening sessions
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

        // Save preferences to UserDefaults
        UserDefaults.standard.set(surahNumbers, forKey: "lastSelectedSurahs")
        if let reciterId = reciterId {
            UserDefaults.standard.set(reciterId, forKey: "lastReciterId")
        }

        // Engagement counts immediately - no minimum time
        try await updateStreak(for: user.id)

        return session
    }

    func endSession(_ session: Session, durationSeconds: Int) async throws {
        session.endTime = Date()
        session.durationSeconds = durationSeconds
        session.isCompleted = true

        // Remove shields when session ends
        if session.type == .listening {
            await removeSessionShields()
        }

        try await sessionRepository.updateSession(session)
    }

    func getTodaySession(for userId: UUID) async throws -> Session? {
        return try await sessionRepository.getTodaySession(for: userId)
    }

    func updateStreak(for userId: UUID) async throws {
        guard let user = try await userRepository.getCurrentUser() else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastActiveDay = user.lastActiveDate.map { Calendar.current.startOfDay(for: $0) }

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
        try await userRepository.updateUser(user)
    }

    // MARK: - Session Shield Management
    private func applySessionShields() async {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else {
            print("⚠️ Could not access AppGroup defaults")
            return
        }

        var selection = FamilyActivitySelection()
        
        // Load application tokens
        if let tokenMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data] {
            for (_, data) in tokenMapping {
                if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                    selection.applicationTokens.insert(token)
                }
            }
        }
        
        // Load category tokens
        if let categoryMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] {
            for (_, data) in categoryMapping {
                if let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                    selection.categoryTokens.insert(token)
                }
            }
        }
        
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            print("⚠️ No saved app selection found")
            return
        }
        
        do {
            try await screenTimeRulesUseCase.applySessionShield(for: selection)
            print("✅ Session shields applied")
        } catch {
            print("❌ Failed to apply session shields: \(error)")
        }
    }

    private func removeSessionShields() async {
        await screenTimeRulesUseCase.removeSessionShield()
        print("✅ Session shields removed, rule-based shields reapplied")
    }
}
