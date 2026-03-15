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

    // MARK: - Streak Update Tests

    func testUpdateStreak_FirstActivity() async throws {
        // Given
        let user = User(appleUserId: "streak1")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When - first activity (no prior lastActiveDate)
        fetchedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(fetchedUser)

        // Then
        let updatedUser = try await repository.getCurrentUser()
        XCTAssertEqual(updatedUser?.currentStreak, 1)
        XCTAssertEqual(updatedUser?.longestStreak, 1)
        XCTAssertNotNil(updatedUser?.lastActiveDate)
    }

    func testUpdateStreak_SameDayActivity() async throws {
        // Given
        let user = User(appleUserId: "streak2")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When - first activity
        fetchedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(fetchedUser)

        // Then - same day activity (no change)
        guard let updatedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }
        let streakBefore = updatedUser.currentStreak

        updatedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(updatedUser)

        let finalUser = try await repository.getCurrentUser()
        XCTAssertEqual(
            finalUser?.currentStreak, streakBefore, "Streak should not increment on same day")
    }

    func testUpdateStreak_ConsecutiveDay() async throws {
        // Given
        let user = User(appleUserId: "streak3")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When - first activity
        fetchedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(fetchedUser)

        // Then - consecutive day (simulate by modifying lastActiveDate)
        guard let updatedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }
        // Set lastActiveDate to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        updatedUser.lastActiveDate = yesterday
        try await repository.updateUser(updatedUser)

        // Now update streak for today
        updatedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(updatedUser)

        let finalUser = try await repository.getCurrentUser()
        XCTAssertEqual(finalUser?.currentStreak, 2, "Streak should increment for consecutive day")
        XCTAssertEqual(finalUser?.longestStreak, 2)
    }

    func testUpdateStreak_BrokenStreak() async throws {
        // Given
        let user = User(appleUserId: "streak4")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When - first activity
        fetchedUser.updateStreak(isActiveToday: true)
        fetchedUser.currentStreak = 5
        fetchedUser.longestStreak = 5
        try await repository.updateUser(fetchedUser)

        // Then - streak broken (simulate gap > 1 day)
        guard let updatedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }
        // Set lastActiveDate to 3 days ago
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        updatedUser.lastActiveDate = threeDaysAgo
        try await repository.updateUser(updatedUser)

        // Now update streak for today
        updatedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(updatedUser)

        let finalUser = try await repository.getCurrentUser()
        XCTAssertEqual(finalUser?.currentStreak, 1, "Streak should reset to 1 after gap")
        XCTAssertEqual(finalUser?.longestStreak, 5, "Longest streak should be preserved")
    }

    func testUpdateStreak_LongestStreakUpdated() async throws {
        // Given
        let user = User(appleUserId: "streak5")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When - build up streak
        fetchedUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(fetchedUser)

        // Simulate consecutive days to exceed current longest
        guard var updatingUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }
        updatingUser.currentStreak = 3
        updatingUser.longestStreak = 3
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        updatingUser.lastActiveDate = yesterday
        try await repository.updateUser(updatingUser)

        // Now update - should become 4, which exceeds longestStreak of 3
        updatingUser.updateStreak(isActiveToday: true)
        try await repository.updateUser(updatingUser)

        let finalUser = try await repository.getCurrentUser()
        XCTAssertEqual(finalUser?.currentStreak, 4)
        XCTAssertEqual(
            finalUser?.longestStreak, 4, "Longest streak should be updated when exceeded")
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

    func testUpdateUser_SubscriptionExpiryDate() async throws {
        // Given
        let user = User(appleUserId: "update_sub")
        try await repository.createUser(user)
        guard let fetchedUser = try await repository.getCurrentUser() else {
            XCTFail("User not found")
            return
        }

        // When
        let expiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        fetchedUser.subscriptionExpiryDate = expiryDate
        try await repository.updateUser(fetchedUser)

        // Then
        let updatedUser = try await repository.getCurrentUser()
        XCTAssertNotNil(updatedUser?.subscriptionExpiryDate)
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
