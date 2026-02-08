import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class UserRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var localDataSource: LocalDataSource!
    var repository: UserRepository!

    override func setUp() async throws {
        let schema = Schema([User.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        localDataSource = LocalDataSource(container: container)
        repository = UserRepositoryImpl(localDataSource: localDataSource)
    }

    override func tearDown() {
        container = nil
        localDataSource = nil
        repository = nil
    }

    func testCreateUser() async throws {
        let user = User(appleUserId: "test123", email: "test@example.com")

        try await repository.createUser(user)

        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.appleUserId, "test123")
    }

    func testGetUserByAppleUserId() async throws {
        let user = User(appleUserId: "test456", email: "test456@example.com")
        try await repository.createUser(user)

        let fetchedUser = try await repository.getUser(byAppleUserId: "test456")

        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.email, "test456@example.com")
    }

    func testGetUserByAppleUserIdReturnsNilWhenNotFound() async throws {
        let fetchedUser = try await repository.getUser(byAppleUserId: "nonexistent")

        XCTAssertNil(fetchedUser)
    }

    func testGetCurrentUser() async throws {
        let user = User(appleUserId: "current123")
        try await repository.createUser(user)

        let currentUser = try await repository.getCurrentUser()

        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.appleUserId, "current123")
    }

    func testGetCurrentUserReturnsNilWhenNoUsers() async throws {
        let currentUser = try await repository.getCurrentUser()

        XCTAssertNil(currentUser)
    }

    func testUpdateUser() async throws {
        let user = User(appleUserId: "update123")
        try await repository.createUser(user)

        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        fetchedUser.isPremium = true
        fetchedUser.currentStreak = 5
        try await repository.updateUser(fetchedUser)

        let updatedUser = try await repository.getCurrentUser()
        XCTAssertTrue(updatedUser?.isPremium ?? false)
        XCTAssertEqual(updatedUser?.currentStreak, 5)
    }

    func testDeleteCurrentUser() async throws {
        let user = User(appleUserId: "delete123")
        try await repository.createUser(user)

        try await repository.deleteCurrentUser()

        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNil(fetchedUser)
    }
}
