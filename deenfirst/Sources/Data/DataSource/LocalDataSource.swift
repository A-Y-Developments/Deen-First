import SwiftData
import Foundation

final class LocalDataSource {
    let container: ModelContainer

    @MainActor
    var context: ModelContext {
        container.mainContext
    }

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - User Operations

    @MainActor
    func insertUser(_ user: User) throws {
        context.insert(user)
        try context.save()
    }

    @MainActor
    func getUser(byAppleUserId appleUserId: String) throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserId == appleUserId }
        )
        let users = try context.fetch(descriptor)
        return users.first
    }

    @MainActor
    func getFirstUser() throws -> User? {
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        return users.first
    }

    @MainActor
    func updateUser(_ user: User) throws {
        print("💾 LocalDataSource.updateUser: Saving user id=\(user.id), currentStreak=\(user.currentStreak)")
        try context.save()
        print("✅ LocalDataSource.updateUser: Save successful")
    }

    @MainActor
    func deleteUser(_ user: User) throws {
        context.delete(user)
        try context.save()
    }

    @MainActor
    func deleteAllUsers() throws {
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        for user in users {
            context.delete(user)
        }
        try context.save()
    }

    // MARK: - Session Operations

    @MainActor
    func insertSession(_ session: Session) throws {
        context.insert(session)
        try context.save()
    }

    @MainActor
    func getActiveSession() throws -> Session? {
        let descriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(descriptor)
        return sessions.first { $0.endTime == nil && !$0.isCompleted }
    }

    @MainActor
    func fetchSessions(predicate: (Session) -> Bool) throws -> [Session] {
        let descriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(descriptor)
        return sessions.filter(predicate)
    }

    @MainActor
    func updateSession(_ session: Session) throws {
        try context.save()
    }

    @MainActor
    func deleteSession(_ session: Session) throws {
        context.delete(session)
        try context.save()
    }

    // MARK: - AyahPool Operations

    @MainActor
    func fetchAyahPool() throws -> [AyahPoolItem] {
        let descriptor = FetchDescriptor<AyahPoolItem>(
            sortBy: [SortDescriptor(\.addedAt)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - PendingRuleChange Operations

    @MainActor
    func fetchPendingChanges() throws -> [PendingRuleChange] {
        let descriptor = FetchDescriptor<PendingRuleChange>(
            sortBy: [SortDescriptor(\.requestedAt)]
        )
        return try context.fetch(descriptor)
    }

    @MainActor
    func insertPendingChange(_ change: PendingRuleChange) throws {
        context.insert(change)
        try context.save()
    }

    @MainActor
    func savePendingChanges() throws {
        try context.save()
    }

    @MainActor
    func deletePendingChange(_ change: PendingRuleChange) throws {
        context.delete(change)
        try context.save()
    }

}
