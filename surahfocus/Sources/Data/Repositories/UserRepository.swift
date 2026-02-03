import Foundation

protocol UserRepository {
    func createUser(_ user: User) async throws
    func getUser(byAppleUserId appleUserId: String) async throws -> User?
    func getCurrentUser() async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteCurrentUser() async throws
}

final class UserRepositoryImpl: UserRepository {
    let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func createUser(_ user: User) async throws {
        try await MainActor.run {
            try localDataSource.insertUser(user)
        }
    }

    func getUser(byAppleUserId appleUserId: String) async throws -> User? {
        try await MainActor.run {
            try localDataSource.getUser(byAppleUserId: appleUserId)
        }
    }

    func getCurrentUser() async throws -> User? {
        try await MainActor.run {
            try localDataSource.getFirstUser()
        }
    }

    func updateUser(_ user: User) async throws {
        try await MainActor.run {
            try localDataSource.updateUser(user)
        }
    }

    func deleteCurrentUser() async throws {
        try await MainActor.run {
            guard let user = try localDataSource.getFirstUser() else { return }
            try localDataSource.deleteUser(user)
        }
    }
}
