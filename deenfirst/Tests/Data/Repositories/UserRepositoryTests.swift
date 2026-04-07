import SwiftData
import XCTest

@testable import DeenFirst

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

        fetchedUser.currentStreak = 5
        try await repository.updateUser(fetchedUser)

        let updatedUser = try await repository.getCurrentUser()
        XCTAssertEqual(updatedUser?.currentStreak, 5)
    }

    func testDeleteCurrentUser() async throws {
        let user = User(appleUserId: "delete123")
        try await repository.createUser(user)

        try await repository.deleteCurrentUser()

        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNil(fetchedUser)
    }

    // MARK: - Edge Cases

    func testCreateUser_EmptyEmail() async throws {
        // Given
        let user = User(appleUserId: "empty_email", email: "")

        // When
        try await repository.createUser(user)

        // Then - should create successfully
        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.email, "")
    }

    func testCreateUser_NilEmail() async throws {
        // Given
        let user = User(appleUserId: "nil_email", email: nil)

        // When
        try await repository.createUser(user)

        // Then - should create successfully
        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertNil(fetchedUser?.email)
    }

    func testCreateUser_EmptyName() async throws {
        // Given
        let user = User(appleUserId: "empty_name", name: "")

        // When
        try await repository.createUser(user)

        // Then - should create successfully
        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.name, "")
    }

    func testCreateUser_NilName() async throws {
        // Given
        let user = User(appleUserId: "nil_name", name: nil)

        // When
        try await repository.createUser(user)

        // Then - should create successfully
        let fetchedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertNil(fetchedUser?.name)
    }

    func testUpdateUser_CompletionFlags() async throws {
        // Given
        let user = User(appleUserId: "update_flags")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When
        fetchedUser.hasCompletedOnboarding = true
        fetchedUser.hasCompletedAppSelection = true
        fetchedUser.hasCompletedAppLimitSetup = true
        fetchedUser.hasCompletedDowntimeSetup = true
        try await repository.updateUser(fetchedUser)

        // Then
        let updatedUser = try await repository.getCurrentUser()
        XCTAssertTrue(updatedUser?.hasCompletedOnboarding ?? false)
        XCTAssertTrue(updatedUser?.hasCompletedAppSelection ?? false)
        XCTAssertTrue(updatedUser?.hasCompletedAppLimitSetup ?? false)
        XCTAssertTrue(updatedUser?.hasCompletedDowntimeSetup ?? false)
    }
}
