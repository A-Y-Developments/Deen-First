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
        try context.save()
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

}
